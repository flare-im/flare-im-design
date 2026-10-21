<script setup lang="ts">
import { computed, useId } from "vue";
import { NFormItem, NInput, NInputNumber, NSelect, NSwitch } from "naive-ui";
const props = defineProps<{ schema: Record<string, unknown>; modelValue: Record<string, unknown>; disabled?: boolean }>();
const emit = defineEmits<{ "update:modelValue": [value: Record<string, unknown>] }>();
const fieldPrefix = useId();
type Field = { id: string; title: string; description?: string; type: string; enum?: string[]; minimum?: number; maximum?: number };
const fields = computed<Field[]>(() => {
  const properties = props.schema.properties;
  if (!properties || typeof properties !== "object" || Array.isArray(properties)) return [];
  const definitions = props.schema.$defs as Record<string, unknown> | undefined;
  return Object.entries(properties).slice(0, 32).flatMap(([id, value]) => {
    if (!value || typeof value !== "object" || Array.isArray(value)) return [];
    let field = value as Record<string, unknown>;
    const ref = field.$ref;
    if (typeof ref === "string" && /^#\/\$defs\/[A-Za-z0-9_]+$/.test(ref)) {
      const resolved = definitions?.[ref.slice(8)];
      if (resolved && typeof resolved === "object" && !Array.isArray(resolved)) field = { ...(resolved as Record<string, unknown>), ...field };
    }
    if (!["string", "integer", "boolean"].includes(String(field.type))) return [];
    return [{ id, type: String(field.type), title: typeof field.title === "string" ? field.title : id,
      description: typeof field.description === "string" ? field.description : undefined,
      enum: Array.isArray(field.enum) && field.enum.length <= 100 && field.enum.every((v) => typeof v === "string") ? field.enum : undefined,
      minimum: Number.isSafeInteger(field.minimum) ? field.minimum as number : undefined,
      maximum: Number.isSafeInteger(field.maximum) ? field.maximum as number : undefined }];
  });
});
function set(id: string, value: unknown) { emit("update:modelValue", { ...props.modelValue, [id]: value }); }
</script>
<template>
  <div class="flare-schema-form">
    <NFormItem v-for="field in fields" :key="field.id" :label="field.title" :label-for="`${fieldPrefix}-${field.id}`" :feedback="field.description">
      <NSelect v-if="field.enum" :aria-label="field.title" :value="typeof modelValue[field.id] === 'string' ? modelValue[field.id] as string : null" :options="field.enum.map((value) => ({ label: value, value }))" :disabled="disabled" @update:value="set(field.id, $event)" />
      <NInputNumber v-else-if="field.type === 'integer'" :input-props="{ id: `${fieldPrefix}-${field.id}`, 'aria-label': field.title }" :value="typeof modelValue[field.id] === 'number' ? modelValue[field.id] as number : null" :min="field.minimum" :max="field.maximum" :precision="0" :disabled="disabled" @update:value="set(field.id, $event)" />
      <NSwitch v-else-if="field.type === 'boolean'" :aria-label="field.title" :value="modelValue[field.id] === true" :disabled="disabled" @update:value="set(field.id, $event)" />
      <NInput v-else :input-props="{ id: `${fieldPrefix}-${field.id}`, 'aria-label': field.title }" :value="typeof modelValue[field.id] === 'string' ? modelValue[field.id] as string : ''" :disabled="disabled" :maxlength="4096" @update:value="set(field.id, $event)" />
    </NFormItem>
  </div>
</template>
<style scoped>
.flare-schema-form { display: grid; gap: var(--flare-size-spacing-sm); }
</style>

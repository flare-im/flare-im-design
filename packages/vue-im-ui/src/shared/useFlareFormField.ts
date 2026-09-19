// Field ↔ control association. FlareFormField provides the id its label points
// at, the ids of the text that describes the control, and the invalid / required
// state; the kit's form controls inject them, so a labelled field names its
// control without any host wiring.
//
// The first control that registers owns the field: it renders the field id and
// the describing state. A second control inside the same field (a button beside
// an input, a search box above a picker) stays unbound, so an id never repeats.
// The label only carries `for` while a control owns the id — a label pointing at
// nothing names nothing.
import { computed, inject, onBeforeUnmount, provide, shallowRef, type ComputedRef, type InjectionKey, type Ref } from "vue";

interface FlareFormControlEntry {
  /** The control's own id prop, which wins over the field id. */
  explicitId: () => string | undefined;
}

interface FlareFormFieldContext {
  id: Readonly<Ref<string>>;
  /** Id of the visible label; undefined when the field renders none. */
  labelId: Readonly<Ref<string | undefined>>;
  describedBy: Readonly<Ref<string | undefined>>;
  invalid: Readonly<Ref<boolean>>;
  required: Readonly<Ref<boolean>>;
  owner: Readonly<Ref<FlareFormControlEntry | undefined>>;
  register: (entry: FlareFormControlEntry) => () => void;
}

const FLARE_FORM_FIELD_KEY: InjectionKey<FlareFormFieldContext> = Symbol("flare-form-field");

export interface FlareFormFieldState {
  id: Readonly<Ref<string>>;
  labelId: Readonly<Ref<string | undefined>>;
  describedBy: Readonly<Ref<string | undefined>>;
  invalid: Readonly<Ref<boolean>>;
  required: Readonly<Ref<boolean>>;
}

/** FlareFormField side. Returns the id the label should point at (undefined while no control owns the field). */
export function provideFlareFormField(state: FlareFormFieldState): { boundId: ComputedRef<string | undefined> } {
  const controls = shallowRef<FlareFormControlEntry[]>([]);
  const owner = computed(() => controls.value[0]);
  provide(FLARE_FORM_FIELD_KEY, {
    ...state,
    owner,
    register(entry) {
      controls.value = [...controls.value, entry];
      return () => {
        controls.value = controls.value.filter((item) => item !== entry);
      };
    },
  });
  return { boundId: computed(() => (owner.value ? owner.value.explicitId() ?? state.id.value : undefined)) };
}

export interface FlareFormControlBinding {
  id: string | undefined;
  describedBy: string | undefined;
  invalid: boolean;
  required: boolean;
  /** Id of the field label naming this control; the control then drops its fallback name. */
  labelId: string | undefined;
}

/**
 * Control side. Explicit props win; otherwise the control takes the enclosing
 * field's id, description, invalid and required state when it owns the field.
 * Outside a field everything comes from the explicit props.
 */
export function useFlareFormControl(explicit: {
  readonly id?: string;
  readonly ariaDescribedby?: string;
  readonly invalid?: boolean;
}): ComputedRef<FlareFormControlBinding> {
  const field = inject(FLARE_FORM_FIELD_KEY, null);
  const entry: FlareFormControlEntry = { explicitId: () => explicit.id };
  if (field) onBeforeUnmount(field.register(entry));
  return computed(() => {
    const bound = field !== null && field.owner.value === entry;
    return {
      id: explicit.id ?? (bound ? field.id.value : undefined),
      describedBy: explicit.ariaDescribedby ?? (bound ? field.describedBy.value : undefined),
      invalid: Boolean(explicit.invalid) || (bound && field.invalid.value),
      required: bound && field.required.value,
      labelId: bound ? field.labelId.value : undefined,
    };
  });
}

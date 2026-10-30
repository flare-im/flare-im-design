/** Bounded presentation of local JSON schemas. Validation remains with the schema owner. */
export type SchemaHint = {
  group?: string | null;
  order?: number | null;
  widget?: string;
};
export type SchemaPresentation = {
  label?: string;
  description?: string;
  options?: Record<string, string>;
};
type JsonObject = Record<string, unknown>;
export type SchemaField = {
  id: string;
  title: string;
  description?: string;
  type: string;
  required: boolean;
  nullable: boolean;
  defaultValue?: unknown;
  options?: string[];
  group?: string;
  minimum?: number;
  maximum?: number;
  maxLength?: number;
  secret: boolean;
  childSchema?: JsonObject;
  itemSchema?: JsonObject;
  maxItems?: number;
  minItems?: number;
};
function object(value: unknown): JsonObject | undefined {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? (value as JsonObject)
    : undefined;
}
function resolve(value: unknown, root: JsonObject, depth = 0): JsonObject {
  const field = object(value) ?? {};
  if (
    depth >= 8 ||
    typeof field.$ref !== "string" ||
    !/^#\/\$defs\/[A-Za-z0-9_]+$/.test(field.$ref)
  )
    return field;
  return {
    ...resolve(object(root.$defs)?.[field.$ref.slice(8)], root, depth + 1),
    ...field,
  };
}
function choices(field: JsonObject): string[] | undefined {
  const values = Array.isArray(field.enum)
    ? field.enum
    : Array.isArray(field.oneOf)
      ? field.oneOf.map((v) => object(v)?.const)
      : undefined;
  return values &&
    values.length > 0 &&
    values.length <= 100 &&
    values.every((v) => typeof v === "string")
    ? (values as string[])
    : undefined;
}
export function schemaFields(
  schema: JsonObject,
  hints: Record<string, SchemaHint> = {},
  presentation: Record<string, SchemaPresentation> = {},
): SchemaField[] {
  const required = Array.isArray(schema.required) ? schema.required : [];
  return Object.entries(object(schema.properties) ?? {})
    .slice(0, 32)
    .flatMap(([id, value]) => {
      let field = resolve(value, schema);
      const branches = field.anyOf ?? field.oneOf;
      let nullable = Array.isArray(field.type) && field.type.includes("null");
      if (Array.isArray(branches)) {
        const nonNull = branches.filter((v) => object(v)?.type !== "null");
        if (nonNull.length === 1 && nonNull.length < branches.length) {
          nullable = true;
          const { anyOf: _anyOf, oneOf: _oneOf, ...annotations } = field;
          field = { ...resolve(nonNull[0], schema), ...annotations };
        }
      }
      const options = choices(field);
      const type = Array.isArray(field.type)
        ? field.type.find((v) => v !== "null")
        : (field.type ?? (options ? "string" : undefined));
      const itemOptions =
        type === "array" ? choices(resolve(field.items, schema)) : undefined;
      const item = type === "array" ? resolve(field.items, schema) : undefined;
      const itemObject = item?.type === "object" && object(item.properties);
      if (
        !["string", "integer", "boolean"].includes(String(type)) &&
        !(type === "array" && (itemOptions || itemObject)) &&
        !(type === "object" && object(field.properties))
      )
        return [];
      const p = presentation[id];
      return [
        {
          id,
          type: String(type),
          title:
            p?.label ?? (typeof field.title === "string" ? field.title : id),
          description:
            p?.description ??
            (typeof field.description === "string"
              ? field.description
              : undefined),
          required: required.includes(id),
          nullable,
          defaultValue: field.default,
          options: itemOptions ?? options,
          group: hints[id]?.group ?? undefined,
          minimum: Number.isSafeInteger(field.minimum)
            ? (field.minimum as number)
            : undefined,
          maximum: Number.isSafeInteger(field.maximum)
            ? (field.maximum as number)
            : undefined,
          maxLength: Number.isSafeInteger(field.maxLength)
            ? (field.maxLength as number)
            : undefined,
          secret: hints[id]?.widget === "secret" || field.writeOnly === true,
          childSchema: type === "object" ? { ...field, $defs: schema.$defs } : undefined,
          itemSchema: itemObject ? { ...item, $defs: schema.$defs } : undefined,
          maxItems: type === "array" ? Math.max(0, Math.min(32, Number.isSafeInteger(field.maxItems) ? Number(field.maxItems) : 32)) : undefined,
          minItems: type === "array" ? Math.max(0, Math.min(32, Number.isSafeInteger(field.minItems) ? Number(field.minItems) : 0)) : undefined,
        },
      ];
    })
    .sort(
      (a, b) =>
        (a.group ?? "").localeCompare(b.group ?? "") ||
        (hints[a.id]?.order ?? 0) - (hints[b.id]?.order ?? 0),
    );
}
export function schemaFieldValue(
  model: JsonObject,
  field: SchemaField,
): unknown {
  return Object.hasOwn(model, field.id) ? model[field.id] : field.defaultValue;
}
/** Clear an optional override without turning absence into null or false. */
export function updateSchemaField(
  model: JsonObject,
  field: SchemaField,
  value: unknown,
): JsonObject {
  const next = { ...model };
  if (value === undefined || (value === null && !field.required))
    delete next[field.id];
  else next[field.id] = value;
  return next;
}

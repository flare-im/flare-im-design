import type { FlarePluginReference } from "../../shared/contracts/plugin-ui";

/** Text by locale, as a manifest declares it. */
export type SchemaLocalized = Record<string, string>;
/** Bounded presentation of local JSON schemas. Validation remains with the schema owner. */
export type SchemaHint = {
  group?: string | null;
  order?: number | null;
  widget?: string | null;
  /** The field's name, in place of the schema's one-language `title`. */
  label?: SchemaLocalized | null;
  /** The field's help, in place of the schema's one-language `description`. */
  description?: SchemaLocalized | null;
  /** Labels of enumerated values, by value. */
  options?: Record<string, SchemaLocalized> | null;
  /** The field's options come from the host, read with the viewer's own permission. */
  reference?: FlarePluginReference | null;
  /** Hints of the properties of an object field or of the items of an object array. */
  fields?: Record<string, SchemaHint>;
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
  /** `oneOf` titles by value: what the schema itself calls its options. */
  optionLabels?: Record<string, string>;
  reference?: FlarePluginReference;
  /** Hints of what this field nests. */
  childHints?: Record<string, SchemaHint>;
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
function choiceTitles(field: JsonObject): Record<string, string> | undefined {
  if (!Array.isArray(field.oneOf)) return undefined;
  const titles = field.oneOf.flatMap((branch) => {
    const entry = object(branch);
    return typeof entry?.const === "string" && typeof entry.title === "string"
      ? [[entry.const, entry.title] as const]
      : [];
  });
  return titles.length ? Object.fromEntries(titles) : undefined;
}
/** The text for `locale`: the exact tag, then its language; absent otherwise, so the schema's own text stands. */
export function schemaLocalized(
  text: SchemaLocalized | null | undefined,
  locale: string | undefined,
): string | undefined {
  if (!text || !locale) return undefined;
  const language = locale.split("-")[0];
  return (
    text[locale] ??
    Object.entries(text).find(([tag]) => tag.split("-")[0] === language)?.[1]
  );
}
function hintOptionLabels(
  hint: SchemaHint | undefined,
  locale: string | undefined,
): Record<string, string> {
  return Object.fromEntries(
    Object.entries(hint?.options ?? {}).flatMap(([value, text]) => {
      const label = schemaLocalized(text, locale);
      return label ? [[value, label]] : [];
    }),
  );
}
export function schemaFields(
  schema: JsonObject,
  hints: Record<string, SchemaHint> = {},
  presentation: Record<string, SchemaPresentation> = {},
  locale?: string,
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
      const hint = hints[id];
      const titles = choiceTitles(type === "array" ? (item ?? {}) : field);
      const hintLabels = hintOptionLabels(hint, locale);
      return [
        {
          id,
          type: String(type),
          title:
            p?.label ??
            schemaLocalized(hint?.label, locale) ??
            (typeof field.title === "string" ? field.title : id),
          description:
            p?.description ??
            schemaLocalized(hint?.description, locale) ??
            (typeof field.description === "string"
              ? field.description
              : undefined),
          required: required.includes(id),
          nullable,
          defaultValue: field.default,
          options: itemOptions ?? options,
          optionLabels:
            titles || Object.keys(hintLabels).length
              ? { ...titles, ...hintLabels }
              : undefined,
          reference: hints[id]?.reference ?? undefined,
          childHints: hints[id]?.fields,
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

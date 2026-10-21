// Kit glyphs no icon library draws. Each matches the Lucide shim's conventions (24-unit box, 1em,
// currentColor, the same stroke width) so it sits beside the library glyphs, and names itself in
// data-flare-glyph like they do. The native kits draw the same geometry (spec: icon `red-packet`).
import { h, type FunctionalComponent } from "vue";

const STROKE = 1.75;

/**
 * The red packet, reduced to a line: the card's small envelope — a rounded body 15 × 19.5 with corners
 * 2.7, a flap whose curved edge dips from the sides (7.98) to its lowest point (10.44) at the middle,
 * and a solid seal of radius 2.6 on that point. It follows the tint like any other glyph.
 */
export const RedPacketOutline: FunctionalComponent = (_props, { attrs }) =>
  h(
    "svg",
    {
      xmlns: "http://www.w3.org/2000/svg",
      width: "1em",
      height: "1em",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": STROKE,
      "stroke-linecap": "round",
      "stroke-linejoin": "round",
      "data-flare-glyph": "RedPacket",
      ...attrs,
    },
    [
      h("rect", { x: 4.5, y: 2.25, width: 15, height: 19.5, rx: 2.7 }),
      h("path", { d: "M4.5 7.98Q12 12.9 19.5 7.98" }),
      h("circle", { cx: 12, cy: 10.44, r: 2.6, fill: "currentColor", stroke: "none" }),
    ],
  );
RedPacketOutline.displayName = "RedPacket";

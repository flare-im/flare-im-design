# New Component Checklist

- [ ] Repository scope and target layer are explicit.
- [ ] `spec/components.json` contract is complete.
- [ ] Semantic/component tokens are added only when necessary.
- [ ] Default, focus, disabled, loading, empty, error, recovery, offline, and destructive states that apply are defined.
- [ ] Pointer, keyboard, touch, and gesture interaction is explicit.
- [ ] Accessible name, role, value/state, focus, large text, contrast, reduced motion, and touch targets are covered.
- [ ] Responsive pane/sheet/drawer/route behavior is defined.
- [ ] Vue implementation and public export exist.
- [ ] Flutter implementation and public facade export exist.
- [ ] Compose implementation and public symbol exist.
- [ ] SwiftUI implementation and public symbol exist.
- [ ] Focused tests cover public behavior and recovery.
- [ ] Shared scenario feeds gallery, test, visual baseline, and docs where applicable.
- [ ] Bilingual docs include overview, use/not-use, anatomy, examples, variants, sizes, states, interaction, keyboard, accessibility, responsive, platform differences, API, tokens, do/don't, related components, and migration.
- [ ] Basic and complex examples meet coverage rules.
- [ ] Component Catalog status, support, aliases, and `since` are correct.
- [ ] Public API baseline/version impact is reviewed.
- [ ] `npm run generate` and `npm run check` pass.

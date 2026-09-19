# Error Recovery Validation

Failure-state scenarios live in `spec/scenarios/rc.json` and are validated through the component contract, gallery, interaction tests, and visual fixtures.

Every recoverable failure must provide:

- a localized, human-readable explanation;
- one bounded recovery intent when recovery is possible;
- retained user content or an explicit retention policy;
- no focus theft for passive status updates;
- an accessible name and announced state;
- item-scoped failure when sibling work can continue.

Representative scenarios cover offline/reconnect, send failure, transfer failure, permission denial, unavailable media capability, missing conversation/history, and stale referenced content. The component emits intent; the host executes networking, authentication, permissions, and persistence.

Automated scenarios do not replace physical network, permission-dialog, screen-reader, and device testing recorded in `docs/device-accessibility-test-matrix.md`.

import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';
import test from 'node:test';
import { docImports, publicExports } from './vue-doc-imports.mjs';

test('documentation imports support aliases and both type-only syntaxes', () => {
  assert.deepEqual(docImports(`
    import { FlareComposer as Composer, type MessageLike } from '@flare-im/vue-ui';
    import type { ConversationLike as Conversation } from '@flare-im/vue-ui';
  `), ['FlareComposer', 'MessageLike', 'ConversationLike']);
});

test('public entry resolves composables/types and excludes internals or invented names', () => {
  const names = publicExports(fileURLToPath(new URL('../packages/vue-im-ui/src', import.meta.url)));
  for (const name of ['FlareMessageList', 'MessageLike', 'useViewportProvider']) assert.ok(names.has(name), name);
  for (const name of ['NonexistentMessage', 'FlarePrivateInternal', 'EnhancedComposer']) assert.ok(!names.has(name), name);
});

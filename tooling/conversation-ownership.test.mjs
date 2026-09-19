import assert from 'node:assert/strict';
import test from 'node:test';
import { inspectConversationSource } from './conversation-ownership.mjs';

test('business composition is allowed; component presentation is not', () => {
  assert.deepEqual(inspectConversationSource('<template><ConversationListPanel :items="items" /></template>', 'Host.vue'), []);
  for (const [source, file] of [
    ['<template><div /></template><style scoped>.host :deep(.im-conv-item) { color:red }</style>', 'Host.vue'],
    ['private struct ConversationCard: View {}', 'Host.swift'],
    ['class UnreadConversationItem {}', 'Host.dart'],
    ['SlidableAction(onPressed: action)', 'Host.dart'],
  ]) assert.ok(inspectConversationSource(source, file).length, file);
});

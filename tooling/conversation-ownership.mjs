import { readFileSync, readdirSync } from 'node:fs';
import { join, extname } from 'node:path';
import { parse } from '@vue/compiler-sfc';
import postcss from 'postcss';

export function inspectConversationSource(source, file) {
  const errors = [];
  if (file.endsWith('.vue')) {
    const { descriptor, errors: parseErrors } = parse(source, { filename: file });
    errors.push(...parseErrors.map(String));
    for (const style of descriptor.styles) {
      postcss.parse(style.content).walkRules(rule => {
        if (/im-conv|conversation-row|conversation-item|unread-pill/.test(rule.selector)) {
          errors.push('Host overrides canonical conversation selectors: ' + rule.selector);
        }
      });
    }
  }
  for (const expression of [
    /\b(?:struct|class|fun)\s+(?:ConversationCard|PinnedConversationItem|UnreadConversationItem|ConversationQuickAction|ConversationActionRow)\b/,
    /\bSlidableAction\s*\(/,
  ]) if (expression.test(source)) errors.push('Duplicate conversation presentation: ' + expression);
  return errors;
}

function* sources(root) {
  for (const entry of readdirSync(root, { withFileTypes: true })) {
    const path = join(root, entry.name);
    if (entry.isDirectory()) yield* sources(path);
    else if (['.vue', '.ts', '.dart', '.swift', '.kt'].includes(extname(path))) yield path;
  }
}

export function checkConversationOwnership(sdk) {
  const targets = [
    ['examples/flare-core-web-app/src/App.vue', ['../../shared/vue-reference/ReferenceApp.vue']],
    ['examples/flare-core-tauri-app/src/App.vue', ['../../shared/vue-reference/ReferenceApp.vue']],
    // D9 (P0-4) removed FlareConversationListPanel from the kit: the panel COMPOSITION
    // is product code now, so the barrel must point at the local file. What still has to
    // come from the kit is the row/list underneath it, which the panel itself imports.
    ['examples/shared/vue-reference/workbench/app/ui/components.ts', ['../components/ConversationListPanel.vue', '@flare-im/vue-ui/components']],
    ['examples/shared/vue-reference/workbench/app/components/ConversationListPanel.vue', ['FlareConversationList', '@flare-im/vue-ui/components']],
    ['examples/shared/vue-reference/workbench/app/components/FlareConversationsPanel.vue', ['<ConversationListPanel']],
    ['examples/flare-core-flutter-app/lib/interface/widgets/conversation_item/conversation_item.dart', ['FlareConversationRow(', 'FlareConversationActionSheet(', 'FlareConversationSwipeAction(']],
    ['examples/flare-core-ios-app/Sources/FlareImApp/Features/Messaging/ConversationList/ConversationListView.swift', ['FlareIMUI.ConversationRowView(', 'FlareIMUI.ConversationActionSheetView(']],
    ['examples/flare-core-android-app/app/src/main/kotlin/com/flare/im/app/features/messaging/conversationlist/ConversationListView.kt', ['com.flare.im.ui.ConversationRow(', 'com.flare.im.ui.ConversationActionSheet(']],
  ];
  const errors = [];
  for (const [file, required] of targets) {
    const source = readFileSync(join(sdk, file), 'utf8');
    for (const token of required) if (!source.includes(token)) errors.push(file + ': missing ' + token);
    for (const error of inspectConversationSource(source, file)) errors.push(file + ': ' + error);
  }
  // Scan all Vue host styles, not just the known adapter, so moving an override cannot bypass the gate.
  for (const dir of ['examples/shared/vue-reference', 'examples/flare-core-web-app/src', 'examples/flare-core-tauri-app/src']) {
    for (const file of sources(join(sdk, dir))) {
      for (const error of inspectConversationSource(readFileSync(file, 'utf8'), file)) errors.push(file + ': ' + error);
    }
  }
  return errors;
}

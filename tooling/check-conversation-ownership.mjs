import { fileURLToPath } from 'node:url';
import { checkConversationOwnership } from './conversation-ownership.mjs';
const sdk = fileURLToPath(new URL('../../flare-im-core-client-sdk/', import.meta.url));
const errors = checkConversationOwnership(sdk);
if (errors.length) { console.error(errors.join('\n')); process.exitCode = 1; }
else console.log('Conversation reference ownership PASS: five entry paths, canonical rows/menus, no Vue row overrides.');

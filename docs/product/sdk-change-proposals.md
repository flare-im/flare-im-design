# SDK change proposals: S25, S26, S27

Round 10, 2026-09-18. Three SDK gaps from `product-refinement-audit.md` §7 that this program cannot close, because the kit and the apps do not change `flare-im-core-sdk`. Each proposal says what is wrong with evidence, what to change, how to test it, and what the kits and apps do once it lands. S25 and S27 come with a patch that was built and tested against copies of the SDK files; S26 needs protocol and server work and is a design.

| ID | Gap | Severity | Deliverable |
|---|---|---|---|
| S27 | A tight Markdown list makes rich-text normalisation fail | P1: a rich send that contains a list fails on every client | Patch + 7 tests |
| S25 | Markdown normalisation loses tables, underline, images and three kinds of link; an unsafe link fails the whole document | P2: content silently lost | Same patch |
| S26 | Nothing can act on a poll or a task | P2: poll and task intents have nowhere to go | Design |

## 1. S27 and S25: `rich_doc_v2::from_markdown`

### Evidence

`pipeline::normalize_from_markdown` runs `from_markdown::markdown_to_doc_value`, then `validate::validate_doc_json`, then `extract::derive_from_value`. The table below ran byte-identical copies of those three files and `content/url_safety.rs` (pulldown-cmark 0.12.2, the version `Cargo.lock` resolves for the SDK) over each input, next to the patched copies. The SDK's own Markdown tests cover only `"hello"` and an oversized source.

| Input | SDK today | Patched |
|---|---|---|
| `- 苹果\n- 梨` | fails: `unclosed list item` | bullet list, plain `苹果\n梨` |
| `1. 第一步\n2. 第二步` | fails: `unclosed list item` | ordered list |
| `- 只有一项` | fails: `unclosed list item` | bullet list |
| `- [ ] 待办一\n- [x] 已完成` | fails: `unclosed list item` | bullet list; the brackets stay as text |
| `- 苹果\n\n- 梨` (loose) | bullet list | unchanged |
| a two-column table | empty `custom_block` (`markdown_table`), plain `""` | `custom_block` `table` with rows and cells, plain `名称 \| 数量\n苹果 \| 3\n梨 \| 5` |
| `这是 <u>下划线</u> 文字` | text without the mark | `underline` mark (already in the schema, and the HTML path already maps `<u>`) |
| `![海边日落](https://cdn.example/sunset.jpg "日落")` | alt text only, the address gone | a `link` to the image named by its alt text |
| `<https://flare.im/docs>` | the address disappears: plain `官网  见` | `link` |
| `<team@flare.im>` | the address disappears | `link` to `mailto:team@flare.im` |
| `[文档][d]` with `[d]: https://flare.im/docs` | the words disappear: plain `见 ` | `link` |
| an inline link whose address is `javascript:alert(1)` | fails: `link.href scheme not allowed` | the words, without a link |

### Root cause of S27

In a tight list item pulldown-cmark emits the item's inline events directly, with no paragraph around them. `next_block` treats a `Text` at block level as something to skip: it consumes the text and calls itself, and the recursive call consumes the item's `End(Item)` as a stray end. The item loop then never sees its own end, runs into the next item or the end of input, and returns `unclosed list item`. A loose list works because each item's text is inside a paragraph. The Vue composer's bullet and numbered shortcuts (`useMarkdownShortcuts`) and the SwiftUI composer's bullet format prefix a line with `- ` or `1. `, which is exactly a one-item tight list, so the kits' own list buttons produce a send that fails.

### The patch

`plans/round10/sdk-proposals/s25-s27-rich-doc-markdown.patch` (workspace root), against `src/content/rich_doc_v2/from_markdown.rs` and `extract.rs`. It applies with `patch -p1` from `flare-im-core-sdk` (checked with `--dry-run`). Everything it emits is already valid RichDoc v2, so the schema, the validator and the four kits need no change to show the recovered content.

- **Inline runs at block level** (tight list items, text next to a nested list) are collected into a paragraph by one inline parser that stops at the first block-level event without consuming it. `next_block` no longer swallows text or someone else's end tag.
- **Tables** become `custom_block` `table` (`attrs.align`: one of `none`, `left`, `center`, `right` per column), holding `table_row` blocks (`attrs.header: true` on the head row), each holding `table_cell` blocks with one paragraph. The kits draw a `custom_block`'s block children today, so every cell's text is visible on all four kits at once; a real table body is a kit follow-up. `extract` reads a row as one line with cells separated by ` | `.
- **Underline**: inline `<u>` and `</u>` open and close the `underline` mark. All other inline HTML is still ignored.
- **Links of every form** (inline, reference, collapsed, shortcut, autolink, email) keep their words; the address is kept when `is_safe_link_href` accepts it, and email autolinks get `mailto:`.
- **Images** become a `link` to the image named by the alt text (the file name when there is none), because every renderer draws links and there is no image node in the schema. An inline image node with a preview is a schema change for later.
- **An unsafe link** keeps its words and loses the link, instead of producing a document the validator rejects — which today fails the send.

`pop_mark` now closes the innermost mark of the same kind, so a stray `</u>` cannot close a bold run.

### Tests in the patch

Seven tests in `from_markdown.rs`, each validating its document with `validate_doc_json`: a tight list of paragraphs (with a bold run inside an item), a tight item keeping its nested list, a table with alignment, underline around a bold run, every link form with a safe and an unsafe address, images with alt text, without it and with an unsafe address, and a regression case holding everything that already normalised (heading, quote with marks and inline code, fenced code, divider, loose list) to its current output. Against the current file six of the seven fail and the regression case passes; with the patch all pass, alongside the copied validator and URL-safety tests (18 in total).

### After it lands

- `docs/RICHDOC_V2.md` §9: replace the table placeholder row and add rows for underline, images and links.
- The kits: add a case to `spec/rich-doc-vectors.json` for a `table` block, then a table body on four kits; until then cells draw as stacked paragraphs.
- The apps need no change. The two matrix rows named Rich text (Messaging and Composer) go back to SDK C once S27 is fixed.

## 2. S26: acting on a poll or a task

### What exists

- Builders only: `message_builder.create_vote(conversation_id, vote_id, title, options, participant_user_ids?)`, `create_task(…, status?, …)`, `create_schedule(…)` (`bindings/contract/dispatch.json`). A poll and a task are an `AppCardContent` with `card_type` `vote` or `task` and a JSON payload (`vote_id`, `options`, `participant_user_ids`; `task_id`, `status`, `participant_user_ids`).
- No operation casts or withdraws a vote, reads a tally, or changes a task's status. The payload is content, and content changes only through an edit by the sender.
- Since R9-B8 all four kits report `vote(optionIndex)` and `taskToggle(done)` on the list, the bubble and the content view, and draw the poll and the task as controls only while the host handles them. The apps pass no handler.

### Proposal

Model a vote and a task update the way reactions already work: an operation event with its own RPC, aggregated by the server into state on the message, applied locally by the SDK and published to the apps.

**Protocol (`flare-proto`, `flare-grpc-proto`)**

- `enum VoteAction { VOTE_ACTION_UNSPECIFIED = 0; VOTE_ACTION_CAST = 1; VOTE_ACTION_RETRACT = 2; }`
- `message VoteEvent { string server_msg_id = 1; string user_id = 2; repeated uint32 option_indices = 3; VoteAction action = 4; }` — a cast replaces the voter's previous choice, so a single-choice poll is one index and a change of mind is one event.
- `message TaskStatusEvent { string server_msg_id = 1; string operator_id = 2; string status = 3; }` with `status` in `todo | done` (the payload's free string today).
- New `Event.payload` cases for both, next to `ReactionEvent reaction = 20`.
- On `Message`, typed state beside `reactions`: `repeated VoteTally vote_tallies` (`option_index`, `count`, `user_ids` — capped like reactions for large groups) and `optional TaskState task_state` (`status`, `updated_by`, `updated_at`).
- `MessageService`: `CastVote(message_id, option_indices)`, `RetractVote(message_id)`, `UpdateTaskStatus(message_id, status)`; the user id comes from metadata, as for `AddReaction`.
- Close S15 at the same time: `create_vote` takes `max_choices` (1 for single choice) into the payload, and the server rejects a cast with more indices.

**Server (`flare-im-core`)**

- Accept a cast only from a conversation member, and only from `participant_user_ids` when that list is not empty; reject indices out of range or above `max_choices`.
- Accept a task status change from the sender or a participant.
- Aggregate into the message record and fan the event out with a `conversation_seq`, like reactions, so a late or reconnecting client converges.

**SDK (`flare-im-core-sdk`)**

- Use cases beside `add_reaction` in `usecases/message/mutation.rs`: `cast_vote`, `retract_vote`, `update_task_status` — plan the transport action, apply to the store, publish `MessageEvent::VoteChanged` / `TaskStatusChanged`.
- Dispatch ops `message.cast_vote`, `message.retract_vote`, `message.update_task_status`; bindings events `message.vote_changed`, `message.task_status_changed` in `bindings/shared/src/event.rs`; the four platform wrappers (TypeScript, Dart, Swift, Kotlin) get typed methods, which avoids another S24.
- `MessageActionAvailability` gains `can_vote` and `can_update_task`, computed from membership, participants and the poll's state, so apps pass the kit handler only when the core allows the act.
- Message projections carry the tallies and the task state, so a poll opened later shows its counts.
- Golden tables in `sdk-spec/golden/`: a sequence of vote and task events and the state each client must show, run by every SDK package.

**Kits and apps once it lands**

- Kits: the timeline intents already exist. The poll body needs counts, the reader's own choice and a closed state (contract props on `VoteMessage` and the timeline content types); the task body already takes `done`.
- Apps: pass `onVote` / `onTaskToggle` (Vue `vote` / `taskToggle`) gated on the availability flags, call the new ops, and refresh from the events.

### Acceptance

A poll cast on one device shows the new count on another member's device without a reload; a second cast replaces the first; a non-participant sees the poll read-only; a task ticked by a participant shows done for everyone; all of it survives a reconnect. These need two signed-in accounts and belong with the External Validation steps of the final report.

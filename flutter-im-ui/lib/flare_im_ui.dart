/// Flare IM UI Kit — Flutter component package (L1).
///
/// A framework-neutral contract (`flare-im-ui-spec`) realised natively in
/// Flutter. Components here are **pure / presentational**: they take data as
/// props and raise callbacks; product behaviour and IM state live in the Rust
/// core's observable views and are fed in by the host app.
library;

export 'src/tokens/flare_tokens.dart';

// primitives (shared building blocks)
export 'src/primitives/flare_surface.dart';
export 'src/primitives/flare_unread_badge.dart';
export 'src/primitives/flare_presence_dot.dart';

export 'src/models/conversation_row_data.dart';
export 'src/models/message_content.dart';
export 'src/emoji_sticker/emoji_sticker.dart';
export 'src/models/message_data.dart';
export 'src/models/pinned_message_data.dart';
export 'src/models/conversation_summary.dart';
export 'src/models/contact_option.dart';
export 'src/models/directory_data.dart';

export 'src/components/flare_avatar.dart';
export 'src/components/flare_time_stamp.dart';
export 'src/components/flare_message_status.dart';
export 'src/components/flare_conversation_row.dart';
export 'src/components/flare_conversation_list.dart';
export 'src/components/flare_message_content_view.dart';
export 'src/components/flare_message_bodies.dart';
export 'src/components/flare_message_bubble.dart';
export 'src/components/flare_message_list.dart';
export 'src/components/flare_chat_header.dart';
export 'src/components/flare_pinned_message_bar.dart';
export 'src/components/flare_markdown_preview.dart';
export 'src/components/flare_rich_markdown_input.dart';
export 'src/components/flare_composer.dart';
export 'src/components/flare_message_action_sheet.dart';
export 'src/components/flare_typing_indicator.dart';
export 'src/components/flare_reaction_summary.dart';
export 'src/components/flare_read_receipt_sheet.dart';
export 'src/components/flare_message_batch_toolbar.dart';
export 'src/components/flare_mention_picker.dart';
export 'src/components/flare_quick_phrases.dart';
export 'src/components/flare_search_results.dart';
export 'src/components/flare_skeleton.dart';
export 'src/components/flare_unread_divider.dart';
export 'src/components/flare_scroll_to_latest.dart';
export 'src/components/flare_profile_card.dart';
export 'src/components/flare_group_member_grid.dart';
export 'src/components/flare_group_call_view.dart';
export 'src/components/flare_forward_picker.dart';
export 'src/components/flare_toast.dart';
export 'src/components/flare_red_packet_card.dart';
export 'src/components/flare_slash_command_menu.dart';
export 'src/components/flare_translation_view.dart';
export 'src/components/flare_qr_card.dart';
export 'src/components/flare_call_dock.dart';
export 'src/components/flare_announcement_banner.dart';
export 'src/components/flare_date_pill.dart';
export 'src/components/flare_image_grid.dart';
export 'src/components/flare_voice_recording_bar.dart';
export 'src/components/flare_voice_player.dart';
export 'src/components/flare_emoji_picker.dart';
export 'src/components/flare_sticker_panel.dart';
export 'src/components/flare_poll_composer.dart';
export 'src/components/flare_chat_wallpaper_picker.dart';

export 'src/components/flare_image_preview.dart';
export 'src/components/flare_video_player.dart';
export 'src/components/flare_conversation_details.dart';
export 'src/components/flare_start_conversation_sheet.dart';

// Phase C — general / contacts
export 'src/components/flare_search_bar.dart';
export 'src/components/flare_input.dart';
export 'src/components/flare_empty_state.dart';
export 'src/components/flare_contact_item.dart';
export 'src/components/flare_contact_list.dart';
export 'src/components/flare_contact_detail.dart';
export 'src/components/flare_new_friend_requests.dart';
export 'src/components/flare_group_list.dart';
export 'src/components/flare_profile_panel.dart';
export 'src/components/flare_profile_editor.dart';
export 'src/components/flare_settings_list.dart';
export 'src/components/flare_call_controls.dart';
export 'src/components/flare_call_view.dart';
export 'src/components/flare_incoming_call.dart';
export 'src/components/flare_app_shell.dart';
export 'src/components/flare_responsive_layout.dart';

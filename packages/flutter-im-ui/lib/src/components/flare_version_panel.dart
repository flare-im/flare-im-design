import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/directory_data.dart';
import '../models/update_prompt.dart';
import '../tokens/flare_strings.dart';
import 'flare_settings_list.dart';

/// The version block of an About page, in the settings list's rows: the
/// version, the build, the channel and the row that checks for an update.
/// Spec: Profile/VersionPanel (`FlareVersionPanel`).
///
/// What that row says and does is [flareVersionPanel]'s call
/// (`spec/update-prompt-vectors.json`, the same in every kit). The widget holds
/// no SDK: it reports intent, and the row is disabled while work is under way
/// or while the host passes no handler for what it would do. It sizes to its
/// content, so it goes inside the host's scrolling page.
class FlareVersionPanel extends StatefulWidget {
  const FlareVersionPanel({
    super.key,
    required this.version,
    this.build,
    this.channel,
    this.updateState,
    this.onCheck,
    this.onUpdate,
  });

  /// `UpdateStatus.current.version`.
  final String version;

  /// `UpdateStatus.current.build`.
  final int? build;

  /// `UpdateStatus.current.channel`.
  final String? channel;

  /// `UpdateStatus.state`.
  final String? updateState;

  /// Check for an update (`update.check` with `manual`).
  final VoidCallback? onCheck;

  /// Start or finish the update.
  final VoidCallback? onUpdate;

  @override
  State<FlareVersionPanel> createState() => _FlareVersionPanelState();
}

class _FlareVersionPanelState extends State<FlareVersionPanel> {
  static const _rowKey = 'update';
  String? _announced;

  void _announce(String? message) {
    if (message == _announced) return;
    _announced = message;
    if (message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(MediaQuery.maybeSupportsAnnounceOf(context) ?? false)) {
        return;
      }
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final model = flareVersionPanel(widget.updateState);
    final handler = switch (model.action) {
      FlareVersionPanelAction.check => widget.onCheck,
      FlareVersionPanelAction.update => widget.onUpdate,
      null => null,
    };
    final detail = model.detail == null
        ? null
        : flareVersionPanelDetailLabel(model.detail!, strings);
    _announce(detail);
    final channel = widget.channel;
    final build = widget.build;
    return FlareSettingsList(
      shrinkWrap: true,
      onSelect: (item) {
        if (item.key == _rowKey) handler?.call();
      },
      sections: [
        FlareSettingsSection(
          title: strings.versionPanelTitle,
          items: [
            FlareSettingsItem(
              key: 'version',
              label: strings.versionPanelVersion,
              kind: FlareSettingKind.value,
              detail: widget.version,
            ),
            if (build != null)
              FlareSettingsItem(
                key: 'build',
                label: strings.versionPanelBuild,
                kind: FlareSettingKind.value,
                detail: '$build',
              ),
            if (channel != null && channel.isNotEmpty)
              FlareSettingsItem(
                key: 'channel',
                label: strings.versionPanelChannel,
                kind: FlareSettingKind.value,
                detail: flareVersionChannelLabel(channel, strings),
              ),
            FlareSettingsItem(
              key: _rowKey,
              label: flareVersionPanelRowLabel(model.row, strings),
              kind: FlareSettingKind.action,
              detail: detail,
              disabled: handler == null,
            ),
          ],
        ),
      ],
    );
  }
}

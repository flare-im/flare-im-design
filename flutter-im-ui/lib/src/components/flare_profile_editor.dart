import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_input.dart';

/// Profile editor — avatar, name and signature fields with save / cancel.
/// Spec: Profile/ProfileEditor (`FlareProfileEditor`).
class FlareProfileEditor extends StatefulWidget {
  const FlareProfileEditor({
    super.key,
    required this.user,
    this.labels = const FlareProfileEditorLabels(),
    this.busy = false,
    this.onSave,
    this.onCancel,
    this.onPickAvatar,
  });

  final FlareUserProfile user;

  /// Field / button copy — defaults keep today's English text.
  final FlareProfileEditorLabels labels;
  final bool busy;
  final void Function(String name, String signature)? onSave;
  final VoidCallback? onCancel;
  final VoidCallback? onPickAvatar;

  @override
  State<FlareProfileEditor> createState() => _FlareProfileEditorState();
}

class _FlareProfileEditorState extends State<FlareProfileEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _signature =
      TextEditingController(text: widget.user.signature ?? '');

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _signature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final canSave = _name.text.trim().isNotEmpty && !widget.busy;
    return Padding(
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: GestureDetector(
              onTap: widget.onPickAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  FlareAvatar(
                      userId: widget.user.id,
                      displayName: _name.text.isEmpty ? widget.user.name : _name.text,
                      avatarUrl: widget.user.avatarUrl,
                      size: 80),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.photo_camera, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: FlareSizes.spacingLg),
          Text(widget.labels.nickname, style: TextStyle(color: colors.textSecondary)),
          FlareInput(controller: _name, placeholder: widget.labels.nickname, maxLength: 24, clearable: true),
          const SizedBox(height: FlareSizes.spacingMd),
          Text(widget.labels.bio, style: TextStyle(color: colors.textSecondary)),
          FlareInput(controller: _signature, placeholder: widget.labels.bioPlaceholder, multiline: true, maxLength: 60),
          const SizedBox(height: FlareSizes.spacingLg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: widget.onCancel, child: Text(widget.labels.cancel)),
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: FilledButton(
                  onPressed: canSave
                      ? () => widget.onSave?.call(_name.text, _signature.text)
                      : null,
                  style: FilledButton.styleFrom(backgroundColor: colors.primary),
                  child: widget.busy
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.labels.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Localizable copy for [FlareProfileEditor].
class FlareProfileEditorLabels {
  const FlareProfileEditorLabels({
    this.nickname = 'Nickname',
    this.bio = 'Bio',
    this.bioPlaceholder = 'Tell us about yourself',
    this.cancel = 'Cancel',
    this.save = 'Save',
  });

  final String nickname;
  final String bio;
  final String bioPlaceholder;
  final String cancel;
  final String save;
}

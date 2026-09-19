import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/flare_tokens.dart';

@immutable
class FlareCommandPaletteCommand {
  const FlareCommandPaletteCommand({
    required this.id,
    required this.label,
    this.description,
    this.keywords = const [],
    this.shortcut,
    this.disabled = false,
  });

  final String id;
  final String label;
  final String? description;
  final List<String> keywords;
  final String? shortcut;
  final bool disabled;
}

@immutable
class FlareCommandPaletteGroup {
  const FlareCommandPaletteGroup({
    required this.id,
    required this.label,
    required this.commands,
  });

  final String id;
  final String label;
  final List<FlareCommandPaletteCommand> commands;
}

/// Searchable command surface. The host owns command execution and open state.
class FlareCommandPalette extends StatefulWidget {
  const FlareCommandPalette({
    super.key,
    required this.open,
    required this.query,
    required this.groups,
    required this.label,
    required this.placeholder,
    required this.emptyText,
    required this.onQueryChange,
    required this.onInvoke,
    required this.onClose,
    this.busy = false,
    this.selectedId,
    this.onSelectedIdChange,
  });

  final bool open;
  final String query;
  final List<FlareCommandPaletteGroup> groups;
  final String label;
  final String placeholder;
  final String emptyText;
  final bool busy;
  final String? selectedId;
  final ValueChanged<String> onQueryChange;
  final ValueChanged<FlareCommandPaletteCommand> onInvoke;
  final VoidCallback onClose;
  final ValueChanged<String>? onSelectedIdChange;

  @override
  State<FlareCommandPalette> createState() => _FlareCommandPaletteState();
}

class _FlareCommandPaletteState extends State<FlareCommandPalette> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.query,
  );
  final FocusNode _paletteFocusNode = FocusNode(
    debugLabel: 'FlareCommandPalette',
  );
  final FocusNode _focusNode = FocusNode();
  String? _internalSelectedId;

  List<FlareCommandPaletteGroup> get _visibleGroups {
    final query = widget.query.trim().toLowerCase();
    if (query.isEmpty) return widget.groups;
    return widget.groups
        .map(
          (group) => FlareCommandPaletteGroup(
            id: group.id,
            label: group.label,
            commands: group.commands.where((command) {
              return [
                command.label,
                ?command.description,
                ...command.keywords,
              ].any((value) => value.toLowerCase().contains(query));
            }).toList(),
          ),
        )
        .where((group) => group.commands.isNotEmpty)
        .toList();
  }

  List<FlareCommandPaletteCommand> get _enabledCommands => _visibleGroups
      .expand((group) => group.commands)
      .where((command) => !command.disabled)
      .toList();

  String? get _activeId {
    final requested = widget.selectedId ?? _internalSelectedId;
    return _enabledCommands.any((command) => command.id == requested)
        ? requested
        : _enabledCommands.firstOrNull?.id;
  }

  @override
  void initState() {
    super.initState();
    if (widget.open) _requestInitialFocus();
  }

  void _requestInitialFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (widget.busy ? _paletteFocusNode : _focusNode).requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant FlareCommandPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
    if (widget.open && (!oldWidget.open || widget.busy != oldWidget.busy)) {
      _requestInitialFocus();
    }
  }

  void _select(String id) {
    setState(() => _internalSelectedId = id);
    widget.onSelectedIdChange?.call(id);
  }

  void _move(int delta) {
    final commands = _enabledCommands;
    if (commands.isEmpty) return;
    final current = commands.indexWhere((command) => command.id == _activeId);
    _select(
      commands[((current < 0 ? 0 : current) + delta) % commands.length].id,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (event.logicalKey == LogicalKeyboardKey.home &&
        _enabledCommands.isNotEmpty) {
      _select(_enabledCommands.first.id);
    } else if (event.logicalKey == LogicalKeyboardKey.end &&
        _enabledCommands.isNotEmpty) {
      _select(_enabledCommands.last.id);
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      final command = _enabledCommands
          .where((item) => item.id == _activeId)
          .firstOrNull;
      if (command != null && !widget.busy) widget.onInvoke(command);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _controller.dispose();
    _paletteFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();
    final colors = FlareColors.of(context);
    return Semantics(
      label: widget.label,
      scopesRoute: true,
      namesRoute: true,
      container: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: .32),
        child: Align(
          alignment: const Alignment(0, -.72),
          child: Focus(
            focusNode: _paletteFocusNode,
            onKeyEvent: _onKey,
            child: Material(
              color: colors.bgElevated,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                side: BorderSide(color: colors.borderPrimary),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 640,
                  maxHeight: 560,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !widget.busy,
                      decoration: InputDecoration(
                        hintText: widget.placeholder,
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(
                          FlareSizes.spacingMd,
                        ),
                      ),
                      onChanged: widget.onQueryChange,
                    ),
                    Divider(height: 1, color: colors.borderPrimary),
                    Flexible(child: _results(colors)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _results(FlareColors colors) {
    if (_visibleGroups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(FlareSizes.spacingXl),
          child: Text(
            widget.emptyText,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(FlareSizes.spacingXs),
      children: [
        for (final group in _visibleGroups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingSm,
              FlareSizes.spacingMd,
              FlareSizes.spacingSm,
              FlareSizes.spacingXs,
            ),
            child: Text(
              group.label,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: FlareSizes.fontSizeXs,
              ),
            ),
          ),
          for (final command in group.commands)
            ListTile(
              selected: command.id == _activeId,
              enabled: !widget.busy && !command.disabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
              ),
              title: Text(command.label),
              subtitle: command.description == null
                  ? null
                  : Text(command.description!),
              trailing: command.shortcut == null
                  ? null
                  : Text(
                      command.shortcut!,
                      style: TextStyle(color: colors.textTertiary),
                    ),
              onFocusChange: (focused) {
                if (focused && !command.disabled) _select(command.id);
              },
              onTap: widget.busy || command.disabled
                  ? null
                  : () => widget.onInvoke(command),
            ),
        ],
      ],
    );
  }
}

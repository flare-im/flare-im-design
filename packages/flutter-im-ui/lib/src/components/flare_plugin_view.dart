import 'package:flutter/material.dart';
import '../tokens/flare_tokens.dart';
import '../models/directory_data.dart';
import 'flare_button.dart';

class FlarePluginField {
  const FlarePluginField({required this.label, required this.value});
  final String label;
  final String value;
}
class FlarePluginAction {
  const FlarePluginAction({required this.id, required this.label});
  final String id;
  final String label;
}
/// Inert Core SDK result. Never evaluate targets or scripts in this widget.
class FlarePluginView extends StatelessWidget {
  const FlarePluginView({super.key, required this.available, required this.title,
    this.fields = const [], this.actions = const [], this.busy = false, this.onAction});
  final bool available;
  final String title;
  final List<FlarePluginField> fields;
  final List<FlarePluginAction> actions;
  final bool busy;
  final ValueChanged<String>? onAction;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      if (available) ...[
        for (final field in fields) Padding(
          padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(field.label), Text(field.value)])),
        Wrap(spacing: FlareSizes.spacingMd, runSpacing: FlareSizes.spacingMd,
          children: [for (final action in actions) FlareButton(label: action.label,
            variant: FlareButtonVariant.secondary, disabled: busy || onAction == null,
            onPressed: () => onAction?.call(action.id))]),
      ],
    ],
  );
}

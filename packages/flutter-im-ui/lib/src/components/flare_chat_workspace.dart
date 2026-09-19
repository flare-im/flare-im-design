import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Coherent Context -> Header -> Timeline -> Composer chat surface.
class FlareChatWorkspace extends StatelessWidget {
  const FlareChatWorkspace({
    super.key,
    required this.header,
    required this.timeline,
    this.contextBanner,
    this.composer,
    this.semanticLabel,
  });

  final Widget header;
  final Widget timeline;
  final Widget? contextBanner;
  final Widget? composer;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: ColoredBox(
        color: colors.bgSecondary,
        child: Column(
          children: [
            if (contextBanner != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FlareSizes.spacingLg,
                  FlareSizes.spacingSm,
                  FlareSizes.spacingLg,
                  FlareSizes.spacingSm,
                ),
                child: contextBanner,
              ),
            header,
            Expanded(child: timeline),
            if (composer != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.bgPrimary,
                  border: Border(top: BorderSide(color: colors.borderPrimary)),
                ),
                child: SafeArea(top: false, child: composer!),
              ),
          ],
        ),
      ),
    );
  }
}

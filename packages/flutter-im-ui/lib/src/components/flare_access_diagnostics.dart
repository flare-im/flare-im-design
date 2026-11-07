import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/access_diagnostics.dart';
import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_input.dart';
import 'flare_status_banner.dart';

/// The network and line diagnostics page's body. Spec:
/// Feedback/AccessDiagnostics (`FlareAccessDiagnostics`).
///
/// The host passes what `access.getStatus` and `access.listAccessPoints`
/// returned; what the page says is [flareAccessDiagnostics]'s call
/// (`spec/access-diagnostics-vectors.json`, the same in every kit). The widget
/// holds no SDK: it reports intent and draws what the host feeds back. It never
/// touches the clipboard. An action is drawn only when the host passes its
/// handler. Recovery comes first while recovering, because that is what the
/// page is open for then.
class FlareAccessDiagnostics extends StatefulWidget {
  const FlareAccessDiagnostics({
    super.key,
    required this.status,
    this.accessPoints = const [],
    this.refreshing = false,
    this.refreshOutcome,
    this.importing = false,
    this.importOutcome,
    this.importCode,
    this.exporting = false,
    this.exportOutcome,
    this.onPin,
    this.onUnpin,
    this.onRefresh,
    this.onImportRecovery,
    this.onExportDiagnostics,
  });

  /// What `access.getStatus` returned; null until the host has read it.
  final FlareAccessStatus? status;

  /// What `access.listAccessPoints` returned.
  final List<FlareAccessPoint> accessPoints;

  /// `access.refresh` is in flight.
  final bool refreshing;

  /// The `outcome` of the last `access.refresh`.
  final String? refreshOutcome;

  /// `access.importRecovery` is in flight.
  final bool importing;

  /// The `outcome` of the last `access.importRecovery`.
  final String? importOutcome;

  /// Its `code` when rejected.
  final String? importCode;

  /// The host is gathering and copying the diagnostics.
  final bool exporting;

  /// The host's word on the clipboard: `copied` or `failed`.
  final String? exportOutcome;

  /// Pin this access point (`access.pin`).
  final ValueChanged<String>? onPin;

  /// Let go of the pin (`access.unpin`).
  final VoidCallback? onUnpin;

  /// Refresh the manifest now (`access.refresh`).
  final VoidCallback? onRefresh;

  /// Import this recovery link (`access.importRecovery`), already trimmed.
  final ValueChanged<String>? onImportRecovery;

  /// Copy the diagnostics (`access.exportDiagnostics`, then the clipboard).
  final VoidCallback? onExportDiagnostics;

  @override
  State<FlareAccessDiagnostics> createState() => _FlareAccessDiagnosticsState();
}

class _FlareAccessDiagnosticsState extends State<FlareAccessDiagnostics> {
  final _link = TextEditingController();
  final _importAnswer = GlobalKey();
  String? _announced;

  @override
  void initState() {
    super.initState();
    _link.addListener(_linkChanged);
    if (widget.importOutcome != null) _showImportAnswer();
  }

  @override
  void didUpdateWidget(FlareAccessDiagnostics oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An adopted link is done with: left in the field it would only invite a
    // second import.
    if (widget.importOutcome == 'adopted' &&
        oldWidget.importOutcome != 'adopted') {
      _link.clear();
    }
    final answered = oldWidget.importing && !widget.importing;
    // What has arrived above, not what ticks: the page loads while a link is
    // checked, and the lines push the answer down again.
    final loaded =
        (oldWidget.status == null) != (widget.status == null) ||
        oldWidget.accessPoints.length != widget.accessPoints.length;
    if (widget.importOutcome != null &&
        (answered ||
            loaded ||
            widget.importOutcome != oldWidget.importOutcome)) {
      _showImportAnswer();
    }
  }

  /// A link opens this page from outside, at its top, and the answer stands
  /// lower than a phone shows: unseen, a refused link would look like nothing
  /// happened.
  void _showImportAnswer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final answer = _importAnswer.currentContext;
      if (!mounted || answer == null || !answer.mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          answer,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          duration: FlareMotion.normal,
        ),
      );
    });
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _linkChanged() => setState(() {});

  bool get _importable => _link.text.trim().isNotEmpty && !widget.importing;

  void _importLink() {
    if (_importable) widget.onImportRecovery?.call(_link.text.trim());
  }

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
    final model = flareAccessDiagnostics(widget.status, widget.accessPoints);
    final refresh = flareAccessRefreshFeedback(widget.refreshOutcome);
    final import = flareAccessImportFeedback(
      widget.importOutcome,
      widget.importCode,
    );
    final export = flareAccessExportFeedback(widget.exportOutcome);
    final importText = import == null
        ? null
        : flareAccessImportLabel(import.text, strings);
    final refreshText = refresh == null
        ? null
        : flareAccessRefreshLabel(refresh.text, strings);
    final exportText = export == null
        ? null
        : flareAccessExportLabel(export.text, strings);
    // The newest answer, else the page's lead notice, is what is announced.
    _announce(
      importText ??
          refreshText ??
          exportText ??
          (model.notices.isEmpty
              ? null
              : flareAccessNoticeLabel(model.notices.first.text, strings)),
    );

    final current = _CurrentLine(status: widget.status, model: model);
    final lines = _Lines(
      model: model,
      onPin: widget.onPin,
      onUnpin: widget.onUnpin,
    );
    final recovery = _Recovery(
      link: _link,
      importable: _importable,
      refreshing: widget.refreshing,
      refreshText: refreshText,
      refreshTone: refresh?.tone,
      exporting: widget.exporting,
      exportText: exportText,
      exportTone: export?.tone,
      importing: widget.importing,
      importText: importText,
      importTone: import?.tone,
      importAnswer: _importAnswer,
      onRefresh: widget.onRefresh,
      onExportDiagnostics: widget.onExportDiagnostics,
      onImport: widget.onImportRecovery == null ? null : _importLink,
    );
    final recovering = model.state == FlareAccessDiagnosticsState.recovering;
    final sections = recovering
        ? <Widget>[recovery, current, lines]
        : <Widget>[current, lines, recovery];

    return Semantics(
      container: true,
      label: strings.accessDiagnosticsTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FlareSizes.spacingXl,
        children: [
          if (model.notices.isNotEmpty)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FlareSizes.spacingSm,
              children: [
                for (final notice in model.notices)
                  FlareStatusBanner(
                    text: flareAccessNoticeLabel(notice.text, strings),
                    tone: notice.tone,
                    pulse: notice.pulse,
                  ),
              ],
            ),
          ...sections,
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FlareSizes.spacingMd,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: FlareTextRoles.body.fontSize,
              fontWeight: FontWeight.w600,
              height: FlareTextRoles.body.lineHeight,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _CurrentLine extends StatelessWidget {
  const _CurrentLine({required this.status, required this.model});

  final FlareAccessStatus? status;
  final FlareAccessDiagnosticsModel model;

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final status = this.status;
    final grade = model.rtt.grade;
    return _Section(
      title: strings.accessDiagnosticsCurrent,
      children: [
        _Fact(strings.accessDiagnosticsAccessPoint, status?.accessPointId),
        _Fact(strings.accessDiagnosticsRegion, status?.regionId),
        _Fact(
          strings.accessDiagnosticsProtocol,
          flareAccessProtocolLabel(status?.protocol),
        ),
        _Fact(
          strings.accessDiagnosticsRtt,
          flareAccessRttLabel(model.rtt, strings),
          tone: grade == null ? null : flareAccessRttTone(grade),
        ),
        _Fact(
          strings.accessDiagnosticsSerial,
          status != null && status.loaded ? status.serial?.toString() : null,
        ),
        _Fact(
          strings.accessDiagnosticsSource,
          flareAccessSourceLabel(status?.source, strings),
        ),
        _Fact(strings.accessDiagnosticsManifest, switch (model.manifest) {
          FlareAccessManifestState.valid =>
            strings.accessDiagnosticsManifestValid,
          FlareAccessManifestState.stale =>
            strings.accessDiagnosticsManifestStale,
          FlareAccessManifestState.none =>
            strings.accessDiagnosticsManifestNone,
        }),
        _Fact(
          strings.connectionDevelopmentMode,
          status?.developmentMode ?? false
              ? strings.accessDiagnosticsOn
              : strings.accessDiagnosticsOff,
        ),
        if (model.reportedAccessPointId case final reported?)
          _Fact(strings.accessDiagnosticsReportedAccessPoint, reported),
        if (model.recoveryRounds case final rounds?)
          _Fact(strings.accessDiagnosticsRecoveryRounds, '$rounds'),
      ],
    );
  }
}

/// A label and its value on one line; a missing value is a dash, never a blank.
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.tone});

  final String label;
  final String? value;
  final FlareStatusTone? tone;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final value = this.value;
    final tone = this.tone;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FlareSizes.spacingMd,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareTextRoles.body.fontSize,
                height: FlareTextRoles.body.lineHeight,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: value != null && tone != null
                  ? _Tag(value, tone: tone)
                  : Text(
                      value ?? '—',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: value == null
                            ? colors.textTertiary
                            : colors.textPrimary,
                        fontSize: FlareTextRoles.body.fontSize,
                        height: FlareTextRoles.body.lineHeight,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.model, this.onPin, this.onUnpin});

  final FlareAccessDiagnosticsModel model;
  final ValueChanged<String>? onPin;
  final VoidCallback? onUnpin;

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    return _Section(
      title: strings.accessDiagnosticsLines,
      children: [
        if (model.regions.isEmpty)
          Text(
            strings.accessDiagnosticsNoLines,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: FlareTextRoles.body.fontSize,
            ),
          ),
        for (final region in model.regions)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FlareSizes.spacingXs,
            children: [
              if (region.regionId case final regionId?)
                Semantics(
                  header: true,
                  child: Text(
                    regionId,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: FlareTextRoles.caption.fontSize,
                      height: FlareTextRoles.caption.lineHeight,
                    ),
                  ),
                ),
              for (final (index, row) in region.accessPoints.indexed) ...[
                if (index > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.borderSecondary,
                  ),
                _LineRow(row: row, onPin: onPin, onUnpin: onUnpin),
              ],
            ],
          ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.row, this.onPin, this.onUnpin});

  final FlareAccessPointRow row;
  final ValueChanged<String>? onPin;
  final VoidCallback? onUnpin;

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final row = this.row;
    final grade = row.rtt.grade;
    final pin = row.pin;
    final VoidCallback? toggle = switch (pin) {
      FlareAccessPinAction.pin =>
        onPin == null ? null : () => onPin!(row.accessPointId),
      FlareAccessPinAction.unpin => onUnpin,
      null => null,
    };
    return Padding(
      key: ValueKey('flare-access-point-${row.accessPointId}'),
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
      child: Row(
        spacing: FlareSizes.spacingMd,
        children: [
          Expanded(
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: FlareSizes.spacingXs,
                children: [
                  Wrap(
                    spacing: FlareSizes.spacingXs,
                    runSpacing: FlareSizes.spacingXs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        row.accessPointId,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareTextRoles.body.fontSize,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (row.current)
                        _Tag(
                          strings.accessDiagnosticsCurrentTag,
                          tone: FlareStatusTone.info,
                        ),
                      if (row.pinned)
                        _Tag(
                          strings.accessDiagnosticsPinnedTag,
                          tone: FlareStatusTone.neutral,
                        ),
                    ],
                  ),
                  if (row.host case final host?)
                    Text(
                      host,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FlareTextRoles.caption.fontSize,
                        height: FlareTextRoles.caption.lineHeight,
                      ),
                    ),
                  Wrap(
                    spacing: FlareSizes.spacingXs,
                    runSpacing: FlareSizes.spacingXs,
                    children: [
                      _Tag(switch (row.status) {
                        FlareAccessPointState.active =>
                          strings.accessDiagnosticsStatusActive,
                        FlareAccessPointState.draining =>
                          strings.accessDiagnosticsStatusDraining,
                        FlareAccessPointState.disabled =>
                          strings.accessDiagnosticsStatusDisabled,
                        FlareAccessPointState.unknown =>
                          strings.accessDiagnosticsStatusUnknown,
                      }, tone: row.statusTone),
                      if (row.breaker case final breaker?)
                        _Tag(switch (breaker) {
                          FlareAccessBreakerState.open =>
                            strings.accessDiagnosticsBreakerOpen,
                          FlareAccessBreakerState.halfOpen =>
                            strings.accessDiagnosticsBreakerHalfOpen,
                        }, tone: row.breakerTone ?? FlareStatusTone.neutral),
                      if (grade != null)
                        _Tag(
                          flareAccessRttLabel(row.rtt, strings)!,
                          tone: flareAccessRttTone(grade),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (toggle != null)
            FlareButton(
              label: pin == FlareAccessPinAction.pin
                  ? strings.accessDiagnosticsPin
                  : strings.accessDiagnosticsUnpin,
              variant: FlareButtonVariant.secondary,
              size: FlareControlSize.sm,
              maintainTouchTarget: true,
              onPressed: toggle,
            ),
        ],
      ),
    );
  }
}

class _Recovery extends StatelessWidget {
  const _Recovery({
    required this.link,
    required this.importable,
    required this.refreshing,
    this.refreshText,
    this.refreshTone,
    required this.exporting,
    this.exportText,
    this.exportTone,
    required this.importing,
    this.importText,
    this.importTone,
    required this.importAnswer,
    this.onRefresh,
    this.onExportDiagnostics,
    this.onImport,
  });

  final TextEditingController link;
  final bool importable;
  final bool refreshing;
  final String? refreshText;
  final FlareStatusTone? refreshTone;
  final bool exporting;
  final String? exportText;
  final FlareStatusTone? exportTone;
  final bool importing;
  final String? importText;
  final Key importAnswer;
  final FlareStatusTone? importTone;
  final VoidCallback? onRefresh;
  final VoidCallback? onExportDiagnostics;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    final onImport = this.onImport;
    return _Section(
      title: strings.accessDiagnosticsRecovery,
      children: [
        if (onRefresh != null || onExportDiagnostics != null)
          Wrap(
            spacing: FlareSizes.spacingSm,
            runSpacing: FlareSizes.spacingSm,
            children: [
              if (onRefresh != null)
                FlareButton(
                  label: strings.accessDiagnosticsRefresh,
                  variant: FlareButtonVariant.secondary,
                  loading: refreshing,
                  maintainTouchTarget: true,
                  onPressed: onRefresh,
                ),
              if (onExportDiagnostics != null)
                FlareButton(
                  label: strings.accessDiagnosticsExport,
                  variant: FlareButtonVariant.secondary,
                  loading: exporting,
                  maintainTouchTarget: true,
                  onPressed: onExportDiagnostics,
                ),
            ],
          ),
        if (refreshText case final text?)
          FlareStatusBanner(
            text: text,
            tone: refreshTone ?? FlareStatusTone.neutral,
            dot: false,
          ),
        if (exportText case final text?)
          FlareStatusBanner(
            text: text,
            tone: exportTone ?? FlareStatusTone.neutral,
            dot: false,
          ),
        if (onImport != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FlareSizes.spacingXs,
            children: [
              Text(
                strings.accessDiagnosticsImportLabel,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FlareTextRoles.caption.fontSize,
                  height: FlareTextRoles.caption.lineHeight,
                ),
              ),
              Row(
                spacing: FlareSizes.spacingSm,
                children: [
                  Expanded(
                    child: FlareInput(
                      controller: link,
                      placeholder: strings.accessDiagnosticsImportPlaceholder,
                      semanticLabel: strings.accessDiagnosticsImportLabel,
                      disabled: importing,
                      monospace: true,
                      onSubmitted: (_) => onImport(),
                    ),
                  ),
                  FlareButton(
                    label: strings.accessDiagnosticsImport,
                    loading: importing,
                    disabled: !importable,
                    maintainTouchTarget: true,
                    onPressed: onImport,
                  ),
                ],
              ),
              Text(
                strings.accessDiagnosticsImportHint,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FlareTextRoles.caption.fontSize,
                  height: FlareTextRoles.caption.lineHeight,
                ),
              ),
              if (importText case final text?)
                FlareStatusBanner(
                  key: importAnswer,
                  text: text,
                  tone: importTone ?? FlareStatusTone.neutral,
                  dot: false,
                ),
            ],
          ),
      ],
    );
  }
}

/// The kit tag's look in a status tone: the tone's ink on a faint tint of the
/// tone over the primary surface, caption size. It is words, never a control.
class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.tone});

  final String text;
  final FlareStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final ink = switch (tone) {
      FlareStatusTone.info => colors.infoText,
      FlareStatusTone.success => colors.successText,
      FlareStatusTone.warning => colors.warningText,
      FlareStatusTone.danger => colors.errorText,
      FlareStatusTone.neutral => colors.textSecondary,
    };
    final tint = switch (tone) {
      FlareStatusTone.info => colors.info,
      FlareStatusTone.success => colors.success,
      FlareStatusTone.warning => colors.warning,
      FlareStatusTone.danger => colors.error,
      FlareStatusTone.neutral => colors.textTertiary,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: FlareOpacity.tintWeak),
        borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacing2xs),
        child: Text(
          text,
          style: TextStyle(
            color: ink,
            fontSize: FlareTextRoles.caption.fontSize,
            fontWeight: FontWeight.w500,
            height: FlareTextRoles.caption.lineHeight,
          ),
        ),
      ),
    );
  }
}

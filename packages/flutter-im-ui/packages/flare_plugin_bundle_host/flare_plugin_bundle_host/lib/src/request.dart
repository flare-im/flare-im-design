import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Where a bundle is shown (the bridge's `presentation`, design 8.9).
enum FlarePluginBundlePresentation {
  /// A page of its own.
  page('page'),

  /// A card's detail, in a sheet.
  detail('detail'),

  /// A composer "+" form: `ui.close` carries the operation result.
  composerForm('composerForm');

  const FlarePluginBundlePresentation(this.wire);

  /// The name the engine reads.
  final String wire;
}

/// What a host asks the engine to open (`plugin_bundle_open`), less the theme
/// the native host adds.
@immutable
class FlarePluginBundleOpenRequest {
  const FlarePluginBundleOpenRequest({
    required this.pluginId,
    required this.contributionId,
    this.route,
    this.arguments = const {},
    this.presentation = FlarePluginBundlePresentation.page,
    this.conversationId,
    this.conversationType,
    this.locale = '',
  });

  final String pluginId;

  /// The contribution whose selected variant is the bundle: a page id, a
  /// card's or a composer entry's contribution.
  final String contributionId;

  /// A route inside the bundle; null opens the contribution's own route.
  final String? route;

  /// The page's arguments (an action's payload).
  final Map<String, Object?> arguments;
  final FlarePluginBundlePresentation presentation;
  final String? conversationId;

  /// The conversation's type as the host names it (`single`, `group`).
  final String? conversationType;

  /// BCP-47 tag the bundle reads its strings by.
  final String locale;

  /// The request without the theme, as the native hosts read it:
  /// `{pluginId, contributionId, route?, arguments, presentation, conversation?, locale}`.
  Map<String, Object?> toJson() {
    final conversation = conversationId?.trim() ?? '';
    final bundleRoute = route?.trim() ?? '';
    return {
      'pluginId': pluginId,
      'contributionId': contributionId,
      if (bundleRoute.isNotEmpty) 'route': bundleRoute,
      'arguments': arguments,
      'presentation': presentation.wire,
      if (conversation.isNotEmpty)
        'conversation': {
          'id': conversation,
          'type': conversationType ?? 'single',
        },
      'locale': locale,
    };
  }

  /// Everything but the locale: a change of any of it opens another page, a
  /// change of the locale is told to the page that is open.
  String get identity => jsonEncode({...toJson(), 'locale': null});

  FlarePluginBundleOpenRequest copyWith({String? route, String? locale}) =>
      FlarePluginBundleOpenRequest(
        pluginId: pluginId,
        contributionId: contributionId,
        route: route ?? this.route,
        arguments: arguments,
        presentation: presentation,
        conversationId: conversationId,
        conversationType: conversationType,
        locale: locale ?? this.locale,
      );

  @override
  bool operator ==(Object other) =>
      other is FlarePluginBundleOpenRequest &&
      other.identity == identity &&
      other.locale == locale;

  @override
  int get hashCode => Object.hash(identity, locale);
}

/// Where `ui.navigate` asks to go.
@immutable
sealed class FlarePluginBundleNavigation {
  const FlarePluginBundleNavigation(this.arguments);

  /// What the bundle passes along.
  final Map<String, Object?> arguments;

  /// `ui.navigate` params (`{page | bundleRoute, arguments?}`); null when
  /// neither or both are given.
  static FlarePluginBundleNavigation? of(Map<String, Object?> params) {
    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;
    final page = text(params['page']);
    final route = text(params['bundleRoute']);
    final raw = params['arguments'];
    final arguments = raw is Map
        ? Map<String, Object?>.from(raw)
        : const <String, Object?>{};
    if (page != null && route == null) {
      return FlarePluginBundlePageTarget(page, arguments: arguments);
    }
    if (route != null && page == null) {
      return FlarePluginBundleRouteTarget(route, arguments: arguments);
    }
    return null;
  }
}

/// A declarative page of the same plugin.
final class FlarePluginBundlePageTarget extends FlarePluginBundleNavigation {
  const FlarePluginBundlePageTarget(
    this.page, {
    Map<String, Object?> arguments = const {},
  }) : super(arguments);
  final String page;

  @override
  bool operator ==(Object other) =>
      other is FlarePluginBundlePageTarget &&
      other.page == page &&
      jsonEncode(other.arguments) == jsonEncode(arguments);

  @override
  int get hashCode => Object.hash(page, jsonEncode(arguments));
}

/// Another route of the same bundle.
final class FlarePluginBundleRouteTarget extends FlarePluginBundleNavigation {
  const FlarePluginBundleRouteTarget(
    this.route, {
    Map<String, Object?> arguments = const {},
  }) : super(arguments);
  final String route;

  @override
  bool operator ==(Object other) =>
      other is FlarePluginBundleRouteTarget &&
      other.route == route &&
      jsonEncode(other.arguments) == jsonEncode(arguments);

  @override
  int get hashCode => Object.hash(route, jsonEncode(arguments));
}

/// `ui.confirm` copy, bounded (design 8.6): title ≤ 64 characters, message ≤
/// 512, label ≤ 16. Null without a title.
@immutable
class FlarePluginBundleConfirm {
  const FlarePluginBundleConfirm({
    required this.title,
    this.message,
    this.confirmLabel,
  });

  final String title;
  final String? message;
  final String? confirmLabel;

  static FlarePluginBundleConfirm? of(Map<String, Object?> params) {
    String? bounded(Object? value, int limit) {
      if (value is! String) return null;
      final text = value.trim();
      if (text.isEmpty) return null;
      final runes = text.runes.toList();
      return runes.length <= limit
          ? text
          : String.fromCharCodes(runes.take(limit));
    }

    final title = bounded(params['title'], 64);
    if (title == null) return null;
    return FlarePluginBundleConfirm(
      title: title,
      message: bounded(params['message'], 512),
      confirmLabel: bounded(params['confirmLabel'], 16),
    );
  }
}

/// An external link the bridge may open (D-13): an absolute `https` address
/// with a host and no credentials, at most 2048 characters.
Uri? flarePluginBundleExternalUrl(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  if (text.isEmpty || text.length > 2048) return null;
  final uri = Uri.tryParse(text);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

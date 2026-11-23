/// The plugin web bundle host (L3) for Flutter: the Android and Apple kits'
/// native hosts in a platform view, their engine calls carried to the app's
/// core SDK over a method channel.
///
/// An app installs the engine once ([FlarePluginBundleBindings.install]),
/// reports [FlarePluginBundleRuntime.profile] as `bundleRuntime` in
/// `plugin.set_host_profile`, hands event 7004 to
/// [FlarePluginBundleEvents.dispatch], and shows [FlarePluginBundleHost] where
/// a page, a card detail or a composer form may be a bundle, falling back to
/// the declarative variant when it reports so.
library;

export 'src/bindings.dart';
export 'src/host.dart';
export 'src/request.dart';

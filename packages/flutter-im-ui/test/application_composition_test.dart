import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('application composition', () {
    test('resolves responsive and navigation presentations', () {
      expect(
        flareApplicationResponsiveModeForWidth(390),
        FlareApplicationResponsiveMode.mobile,
      );
      expect(
        flareApplicationResponsiveModeForWidth(700),
        FlareApplicationResponsiveMode.tablet,
      );
      expect(
        flareApplicationResponsiveModeForWidth(1100),
        FlareApplicationResponsiveMode.desktop,
      );
      expect(
        flareApplicationResponsiveModeForWidth(1600),
        FlareApplicationResponsiveMode.wideDesktop,
      );
      expect(
        flareApplicationResponsiveModeForWidth(1100, textScale: 2),
        FlareApplicationResponsiveMode.mobile,
      );
      expect(
        flareNavigationPresentation(FlareApplicationResponsiveMode.mobile),
        FlareNavigationPresentation.bottom,
      );
      expect(
        flareNavigationPresentation(FlareApplicationResponsiveMode.wideDesktop),
        FlareNavigationPresentation.expandedSidebar,
      );
    });

    test('filters host actions without coupling to an SDK', () {
      const actions = <FlareMessageActionExtension<int>>[
        FlareMessageActionExtension(id: 'always', label: 'Always'),
        FlareMessageActionExtension(
          id: 'positive',
          label: 'Positive only',
          available: _isPositive,
        ),
      ];

      expect(
        resolveFlareMessageActionExtensions(
          actions,
          -1,
        ).map((action) => action.id),
        ['always'],
      );
      expect(
        resolveFlareMessageActionExtensions(
          actions,
          1,
        ).map((action) => action.id),
        ['always', 'positive'],
      );
    });

    test('keeps navigation defaults replaceable and ordered', () {
      const strings = FlareStrings();
      expect(flareDefaultIMNavigation(strings).map((item) => item.id), [
        'chats',
        'contacts',
        'profile',
      ]);
      // The names come from the strings table, not from English literals.
      expect(flareDefaultIMNavigation(strings).map((item) => item.label), [
        strings.navigationChats,
        strings.navigationContacts,
        strings.navigationProfile,
      ]);
      expect(flareDefaultContactNavigation(strings).map((item) => item.id), [
        'friends',
        'groups',
        'newFriends',
        'favorites',
      ]);
      expect(
        flareDefaultContactNavigation(
          strings.copyWith(navigationFriends: '联系人'),
        ).first.label,
        '联系人',
      );
      final items = resolveFlareNavigationItems(
        flareDefaultIMNavigation(strings),
        items: const [
          FlareNavigationItem(
            id: 'profile',
            label: 'Me',
            icon: 'person',
            order: 3,
          ),
          FlareNavigationItem(
            id: 'work',
            label: 'Work',
            icon: 'settings',
            order: 2,
          ),
          FlareNavigationItem(
            id: 'contacts',
            label: 'Contacts',
            icon: 'people',
            visible: false,
          ),
          FlareNavigationItem(
            id: 'chats',
            label: 'Chats',
            icon: 'chats',
            order: 0,
          ),
        ],
      );
      expect(items.map((item) => item.id), ['chats', 'work', 'profile']);
    });

    test('keeps feature and capability contracts host controlled', () {
      const configuration = FlareIMAppConfiguration(
        features: FlareFeatureSet({'contacts', 'search'}),
        capabilities: FlareCapabilitySet({'message.send'}),
        navigation: [],
      );

      expect(configuration.features.contains('contacts'), isTrue);
      expect(configuration.features.contains('calls'), isFalse);
      expect(configuration.capabilities.contains('message.send'), isTrue);
    });
  });
}

bool _isPositive(int value) => value > 0;

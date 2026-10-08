import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortcut_tools/data/shortcuts_catalog.dart';
import 'package:shortcut_tools/main.dart';
import 'package:shortcut_tools/services/favorites_service.dart';
import 'package:shortcut_tools/services/onboarding_service.dart';
import 'package:shortcut_tools/services/recents_service.dart';
import 'package:shortcut_tools/services/theme_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('tools/shortcut'),
      (MethodCall call) async {
        if (call.method == 'getSystemInfo') {
          return {
            'manufacturer': 'Infinix',
            'brand': 'Infinix',
            'model': 'X6833B',
            'androidVersion': '14',
            'sdkInt': 34,
            'batteryPercent': 64,
            'isCharging': false,
            'hasWriteSecureSettings': false,
            'privateDnsMode': 'hostname',
            'privateDnsSpecifier': 'p2.freedns.controld.com',
          };
        }
        if (call.method == 'getGlobalSetting') {
          return 'hostname';
        }
        if (call.method == 'getTileShortcutId') {
          return null;
        }
        if (call.method == 'consumePinnedShortcut') {
          return null;
        }
        return true;
      },
    );
    SharedPreferences.setMockInitialValues({});
    await ThemeService.instance.init();
    await OnboardingService.instance.markSeen();
  });

  testWidgets('App renders catalog with search and category filters',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ShortcutToolsApp());
    await tester.pumpAndSettle();

    // Verify title
    expect(find.text('Shortcut Tools'), findsOneWidget);

    // Verify search field exists
    expect(find.byType(TextField), findsOneWidget);

    // Verify category chips exist
    expect(find.widgetWithText(ChoiceChip, 'Semua'), findsOneWidget);
    for (final cat in kCategories) {
      expect(find.widgetWithText(ChoiceChip, cat), findsOneWidget);
    }

    // Verify some known shortcuts exist in the catalog
    expect(find.text('Private DNS'), findsOneWidget);
    expect(find.text('WiFi'), findsOneWidget);

    // Test search filtering
    await tester.enterText(find.byType(TextField), 'dns');
    await tester.pumpAndSettle();

    expect(find.text('Private DNS'), findsOneWidget);
    expect(find.text('WiFi'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('WiFi'), findsOneWidget);
  });

  testWidgets('Category chip filters shortcuts', (WidgetTester tester) async {
    await tester.pumpWidget(const ShortcutToolsApp());
    await tester.pumpAndSettle();

    // Select category 'Sistem'
    await tester.tap(find.widgetWithText(ChoiceChip, 'Sistem'));
    await tester.pumpAndSettle();

    expect(find.text('Lokasi'), findsOneWidget);
    expect(find.text('WiFi'), findsNothing);
  });

  test('FavoritesService and RecentsService unit tests', () async {
    SharedPreferences.setMockInitialValues({});
    final fav = FavoritesService.instance;
    final rec = RecentsService.instance;

    expect(await fav.getFavorites(), isEmpty);
    final dns = kShortcuts.firstWhere((s) => s.id == 'private_dns');

    await fav.toggleFavorite(dns);
    expect(await fav.isFavorite('private_dns'), isTrue);
    expect(await fav.getFavorites(), contains('private_dns'));

    await fav.toggleFavorite(dns);
    expect(await fav.isFavorite('private_dns'), isFalse);

    // Test recents
    expect(await rec.getRecents(), isEmpty);
    await rec.recordOpen('private_dns');
    await rec.recordOpen('wifi');
    final recents = await rec.getRecents();
    expect(recents.first, 'wifi');
    expect(recents.length, 2);

    await rec.clear();
    expect(await rec.getRecents(), isEmpty);
  });

  testWidgets('Tapping Private DNS opens DnsManagerSheet with presets',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShortcutToolsApp());
    await tester.pumpAndSettle();

    // Tap Private DNS card
    await tester.tap(find.text('Private DNS'));
    await tester.pumpAndSettle();

    // Verify DnsManagerSheet content
    expect(find.text('DNS Pribadi (Private DNS)'), findsOneWidget);
    expect(find.text('Control D (Adblock & Tracking)'), findsOneWidget);
    expect(find.text('Control D (Family Friendly)'), findsOneWidget);
    expect(find.text('AdGuard DNS'), findsOneWidget);
  });
}

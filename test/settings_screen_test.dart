import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_launcher/constants/app_alignment.dart';
import 'package:think_launcher/constants/app_theme.dart';
import 'package:think_launcher/screens/settings_screen.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockGeolocator();
  });

  tearDown(() {
    appThemeNotifier.value = AppThemeMode.auto;
    clearCommonMethodChannelMocks();
  });

  testWidgets(
    'persists appearance settings',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'appTheme': AppThemeMode.auto.storageKey,
        'colorMode': true,
        'showIcons': true,
        'clockFontSize': 18.0,
        'appIconSize': 35.0,
        'showSearchButton': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(wrapForTest(SettingsScreen(prefs: prefs)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(prefs.getString('appTheme'), AppThemeMode.dark.storageKey);
      expect(appThemeNotifier.value, AppThemeMode.dark);

      await tester.tap(find.text('Color mode'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('colorMode'), isFalse);

      await tester.tap(find.text('Show icons'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('showIcons'), isFalse);

      await tester.scrollUntilVisible(find.text('Clock font size'), 400);
      await setSliderValue(tester, min: 18, max: 64, value: 24);
      expect(prefs.getDouble('clockFontSize'), 24);

      await tester.scrollUntilVisible(find.text('App icon size'), 400);
      await setSliderValue(tester, min: 16, max: 128, value: 56);
      expect(prefs.getDouble('appIconSize'), 56);

      await tester.scrollUntilVisible(find.text('Show search button'), 400);
      await tester.tap(find.text('Show search button'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('showSearchButton'), isFalse);
    },
  );

  testWidgets(
    'persists behavior and layout settings',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'use24HourClock': false,
        'appFontSize': 18.0,
        'enableScroll': true,
        'wakeOnNotification': false,
        'scrollToTop': false,
        'showFolderChevron': true,
        'appAlignment': AppAlignment.left.storageKey,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(wrapForTest(SettingsScreen(prefs: prefs)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Use 24-hour clock'), 400);
      await tester.tap(find.text('Use 24-hour clock'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('use24HourClock'), isTrue);

      await tester.scrollUntilVisible(find.text('App font size'), 400);
      await setSliderValue(tester, min: 14, max: 32, value: 22);
      expect(prefs.getDouble('appFontSize'), 22);

      await tester.scrollUntilVisible(find.text('Enable list scrolling'), 400);
      await tester.tap(find.text('Enable list scrolling'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('enableScroll'), isFalse);

      await tester.scrollUntilVisible(find.text('Wake on notification'), 400);
      await tester.tap(find.text('Wake on notification'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('wakeOnNotification'), isTrue);

      await tester.scrollUntilVisible(
        find.text('Auto scroll on folder close'),
        400,
      );
      await tester.tap(find.text('Auto scroll on folder close'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('scrollToTop'), isTrue);

      await tester.scrollUntilVisible(find.text('Show folder chevron'), 400);
      await tester.tap(find.text('Show folder chevron'));
      await tester.pumpAndSettle();
      expect(prefs.getBool('showFolderChevron'), isFalse);

      await tester.scrollUntilVisible(find.text('App alignment'), 400);
      await tester.tap(find.text('Right'));
      await tester.pumpAndSettle();
      expect(prefs.getString('appAlignment'), AppAlignment.right.storageKey);
    },
  );

  testWidgets(
    'persists wallpaper display settings when wallpaper exists',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'wallpaperPath': '/tmp/test-wallpaper.png',
        'wallpaperBlur': 3.0,
        'wallpaperOpacity': 1.0,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(wrapForTest(SettingsScreen(prefs: prefs)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Wallpaper blur'), 400);
      await setSliderValue(tester, min: 1, max: 10, value: 7);
      expect(prefs.getDouble('wallpaperBlur'), 7);

      await tester.scrollUntilVisible(find.text('Wallpaper opacity'), 400);
      await setSliderValue(tester, min: 0, max: 1, value: 0.4);
      expect(prefs.getDouble('wallpaperOpacity'), 0.4);
    },
  );
}

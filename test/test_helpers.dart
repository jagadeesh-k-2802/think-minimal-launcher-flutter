import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:think_launcher/l10n/app_localizations.dart';

Widget wrapForTest(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void mockGeolocator({bool serviceEnabled = false}) {
  const channel = MethodChannel('flutter.baseflow.com/geolocator');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'isLocationServiceEnabled':
        return serviceEnabled;
      case 'checkPermission':
        return 2; // LocationPermission.whileInUse.
      case 'getCurrentPosition':
        return {
          'latitude': 12.9716,
          'longitude': 77.5946,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'accuracy': 1.0,
          'altitude': 0.0,
          'heading': 0.0,
          'speed': 0.0,
          'speed_accuracy': 0.0,
          'floor': null,
          'is_mocked': false,
        };
      default:
        return null;
    }
  });
}

void mockPathProvider() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  final directory =
      Directory('${Directory.systemTemp.path}/think_launcher_tests')
        ..createSync(recursive: true);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'getApplicationDocumentsDirectory':
      case 'getApplicationSupportDirectory':
      case 'getTemporaryDirectory':
      case 'getApplicationCacheDirectory':
        return directory.path;
      default:
        return null;
    }
  });
}

void mockBattery() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/battery'),
    (call) async {
      switch (call.method) {
        case 'getBatteryLevel':
          return 88;
        case 'getBatteryState':
          return 'charging';
        case 'isInBatterySaveMode':
          return false;
        default:
          return null;
      }
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/charging'),
    (call) async => null,
  );
}

void mockNotificationListener() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('x-slayer/notifications_channel'),
    (call) async {
      switch (call.method) {
        case 'isPermissionGranted':
          return false;
        case 'getActiveNotifications':
          return <Map<String, Object?>>[];
        default:
          return false;
      }
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('x-slayer/notifications_event'),
    (call) async => null,
  );
}

void clearCommonMethodChannelMocks() {
  const channels = [
    MethodChannel('flutter.baseflow.com/geolocator'),
    MethodChannel('plugins.flutter.io/path_provider'),
    MethodChannel('dev.fluttercommunity.plus/battery'),
    MethodChannel('dev.fluttercommunity.plus/charging'),
    MethodChannel('x-slayer/notifications_channel'),
    MethodChannel('x-slayer/notifications_event'),
    MethodChannel('installed_apps'),
    MethodChannel('com.jackappsdev.think_minimal_launcher/shortcuts'),
    MethodChannel('com.jackappsdev.think_minimal_launcher/icon_packs'),
    MethodChannel('com.jackappsdev.think_minimal_launcher/wake'),
  ];

  for (final channel in channels) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }
}

Finder sliderWithRange(double min, double max) {
  return find.byWidgetPredicate(
    (widget) => widget is Slider && widget.min == min && widget.max == max,
  );
}

Future<void> setSliderValue(
  WidgetTester tester, {
  required double min,
  required double max,
  required double value,
}) async {
  final slider = tester.widget<Slider>(sliderWithRange(min, max));
  slider.onChanged?.call(value);
  await tester.pumpAndSettle();
}

Map<String, Object?> installedApp({
  required String name,
  required String packageName,
  int installedTimestamp = 100,
}) {
  return {
    'name': name,
    'package_name': packageName,
    'version_name': '1.0.0',
    'version_code': 1,
    'installed_timestamp': installedTimestamp,
    'is_system_app': false,
    'is_launchable_app': true,
  };
}

void mockInstalledApps({
  required List<Map<String, Object?>> apps,
  List<MethodCall>? calls,
}) {
  final appsByPackage = {
    for (final app in apps) app['package_name'] as String: app,
  };

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('installed_apps'),
    (call) async {
      calls?.add(call);
      final arguments = call.arguments as Map?;
      final packageName = arguments?['package_name'] as String?;

      switch (call.method) {
        case 'getInstalledApps':
          return apps;
        case 'getAppInfo':
          return appsByPackage[packageName];
        case 'isAppInstalled':
          return appsByPackage.containsKey(packageName);
        case 'startApp':
        case 'uninstallApp':
          return true;
        default:
          return null;
      }
    },
  );
}

void mockShortcutChannel({List<MethodCall>? calls}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.jackappsdev.think_minimal_launcher/shortcuts'),
    (call) async {
      calls?.add(call);
      switch (call.method) {
        case 'getPendingShortcuts':
          return <Map<String, Object?>>[];
        case 'launchShortcut':
        case 'unpinShortcut':
          return true;
        default:
          return null;
      }
    },
  );
}

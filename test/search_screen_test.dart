import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_launcher/screens/search_screen.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(clearCommonMethodChannelMocks);

  testWidgets('filters apps and launches the selected result', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final installedAppsCalls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('installed_apps'),
      (call) async {
        installedAppsCalls.add(call);
        switch (call.method) {
          case 'getInstalledApps':
            return [
              installedApp(
                name: 'Calculator',
                packageName: 'com.example.calculator',
                installedTimestamp: 100,
              ),
              installedApp(
                name: 'Notes',
                packageName: 'com.example.notes',
                installedTimestamp: 200,
              ),
            ];
          case 'startApp':
            return true;
          default:
            return null;
        }
      },
    );

    await tester.pumpWidget(
      wrapForTest(SearchScreen(prefs: prefs, autoFocus: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'note');
    await tester.pumpAndSettle();

    expect(find.text('Calculator'), findsNothing);
    expect(find.text('Notes'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(
      installedAppsCalls.any(
        (call) =>
            call.method == 'startApp' &&
            (call.arguments as Map)['package_name'] == 'com.example.notes',
      ),
      isTrue,
    );
  });
}

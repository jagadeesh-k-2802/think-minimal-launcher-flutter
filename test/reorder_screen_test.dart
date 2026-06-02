import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_launcher/models/folder.dart';
import 'package:think_launcher/screens/reorder_screen.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(mockPathProvider);

  tearDown(clearCommonMethodChannelMocks);

  testWidgets('persists app order changes on the home reorder screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selectedApps': [
        'com.reorder.calculator',
        'com.reorder.notes',
        'com.reorder.camera',
      ],
      'folders': '[]',
      'shortcuts': '[]',
      'showIcons': false,
    });
    final prefs = await SharedPreferences.getInstance();
    mockInstalledApps(
      apps: [
        installedApp(
          name: 'Calculator',
          packageName: 'com.reorder.calculator',
        ),
        installedApp(
          name: 'Notes',
          packageName: 'com.reorder.notes',
        ),
        installedApp(
          name: 'Camera',
          packageName: 'com.reorder.camera',
        ),
      ],
    );

    await tester.pumpWidget(wrapForTest(ReorderAppsScreen(prefs: prefs)));
    await tester.pumpAndSettle();

    final reorderableList =
        tester.widget<ReorderableListView>(find.byType(ReorderableListView));
    reorderableList.onReorderItem?.call(0, 2);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(
      prefs.getStringList('selectedApps'),
      [
        'com.reorder.notes',
        'com.reorder.camera',
        'com.reorder.calculator',
      ],
    );
  });

  testWidgets('persists app order changes inside a folder', (tester) async {
    const folder = Folder(
      id: 'folder-1',
      name: 'Work',
      appPackageNames: [
        'com.folder.mail',
        'com.folder.calendar',
        'com.folder.docs',
      ],
      order: 0,
    );
    SharedPreferences.setMockInitialValues({
      'selectedApps': folder.appPackageNames,
      'folders': jsonEncode([folder.toJson()]),
      'shortcuts': '[]',
      'showIcons': false,
    });
    final prefs = await SharedPreferences.getInstance();
    mockInstalledApps(
      apps: [
        installedApp(name: 'Mail', packageName: 'com.folder.mail'),
        installedApp(name: 'Calendar', packageName: 'com.folder.calendar'),
        installedApp(name: 'Docs', packageName: 'com.folder.docs'),
      ],
    );

    await tester.pumpWidget(
      wrapForTest(ReorderAppsScreen(prefs: prefs, folder: folder)),
    );
    await tester.pumpAndSettle();

    final reorderableList =
        tester.widget<ReorderableListView>(find.byType(ReorderableListView));
    reorderableList.onReorderItem?.call(2, 0);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    final foldersJson = prefs.getString('folders')!;
    final folders = jsonDecode(foldersJson) as List<dynamic>;
    expect(
      (folders.first as Map<String, dynamic>)['appPackageNames'],
      [
        'com.folder.docs',
        'com.folder.mail',
        'com.folder.calendar',
      ],
    );
  });
}

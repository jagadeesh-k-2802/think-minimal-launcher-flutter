# Think Launcher Agent Guide

## Project Identity

Think Launcher is a minimalist Android launcher built with Flutter. It is tuned
for quiet, low-distraction home screens, including OLED and E-Ink style usage.
Keep changes simple, readable, and in sympathy with a launcher that users open
many times a day.

## Stack

- Flutter and Dart for the app UI and state orchestration.
- Android Kotlin for launcher integrations and platform APIs.
- SharedPreferences for most persisted user settings and launcher state.
- MethodChannels for native Android features that Flutter cannot provide
  directly.
- Generated Flutter localization files are checked in under `lib/l10n`.

## High-Level Architecture

- `lib/main.dart` starts the Flutter app and wires the top-level theme and
  localization setup.
- `lib/screens/main_screen.dart` is the main launcher surface. It owns the home
  screen layout, selected apps, folders, pinned shortcuts, wallpaper display,
  text contrast, gestures, notifications, weather display, and package cleanup.
- `lib/screens/settings_screen.dart` owns user preferences and routes into
  supporting settings flows.
- `lib/screens/reorder_screen.dart` owns app, folder, and shortcut ordering.
  The `reorderable_grid_view` callback used here already adjusts destination
  indexes, so do not manually subtract one from `newIndex`.
- `lib/screens/search_screen.dart` is the app search and launch surface.
- `lib/screens/folder_management_screen.dart`, `app_selection_screen.dart`, and
  `single_app_selection_screen.dart` handle focused launcher configuration
  flows.
- `lib/models` contains mostly plain data objects that serialize to and from
  JSON for SharedPreferences.
- `lib/services/icon_pack_service.dart` and
  `lib/services/weather_service.dart` isolate external or platform-backed data
  lookups used by the UI.
- `android/app/src/main/kotlin/com/jackappsdev/think_minimal_launcher/MainActivity.kt`
  is the main native bridge. It handles pinned shortcut create/launch/remove,
  source app metadata, package removal events, launcher/default-app checks,
  wake-screen behaviour, and MethodChannel calls.
- `android/app/src/main/kotlin/com/jackappsdev/think_minimal_launcher/IconPackManager.kt`
  handles Android icon-pack discovery and icon extraction.

## Persistence Notes

- Launcher state is mostly stored in SharedPreferences. Preserve existing key
  names unless the migration path is explicit and tested.
- App custom names are stored separately from installed app metadata.
- Shortcut custom names live on `ShortcutInfo.customName`; clearing a custom
  name must write `null`, not silently preserve the old value.
- Shortcut icon files are stored under the app documents directory, currently in
  `shortcut_icons`.
- Source app badge icons for shortcuts are stored separately under
  `shortcut_source_icons`.
- For shortcut flows, `shortcut.packageName` is the package that created the
  shortcut. For example, a Gspace-created YouTube shortcut belongs to the Gspace
  package even when the visible shortcut label is YouTube.

## Best Practices

- Keep launcher UI changes restrained. Prefer clear text, stable spacing, and
  predictable touch targets over decorative UI.
- MainScreen is intentionally broad because it is the launcher hub. Keep edits
  scoped and avoid broad extraction or architectural rewrites without a system
  blueprint and user approval.
- Use existing model serialization patterns when adding fields. Maintain
  backward compatibility for old SharedPreferences payloads.
- When a nullable model field must be clearable, do not implement `copyWith`
  using only `value ?? this.value`. Use an explicit sentinel or clear flag.
- Preserve shortcut metadata during rename, reset, reorder, backup, restore, and
  cleanup flows. In particular, do not drop `sourceAppName`, source icon data,
  `customName`, or `order`.
- Package uninstall handling should react to native package removal events and
  clean the launcher state without requiring a manual reload.
- Wallpaper text contrast must account for the displayed wallpaper opacity, not
  only the raw image color.
- Keep English and Dutch localization entries in sync when adding user-facing
  strings. If generated localization files are updated manually, mirror the ARB
  changes in the same patch.
- Avoid broad formatting churn. Format files you touched, then inspect the diff.
- Check the dirty worktree before and after changes. Never revert user changes
  unless explicitly asked.

## Android And Shortcut Gotchas

- Pinned shortcuts can outlive the source app unless the launcher cleans them
  up on package removal.
- Shortcut options must use shortcut-specific wording. Avoid app-only actions
  such as app rename, wallpaper removal, or app-only reorder labels for shortcut
  rows.
- The default Android launcher shows a small badge for the app that created a
  shortcut. This launcher should preserve that signal using the source app name
  and source app icon where available.
- In the reorder screen, shortcut source badges should be visually smaller than
  app icons so shortcut icons remain legible.
- Native package removal receivers must ignore replacement updates and should be
  unregistered with the activity lifecycle.

## Verification

- Dart-only UI/model changes: run `dart analyze lib`.
- Native Android, Gradle, or MethodChannel changes: run
  `dart analyze lib` and `./gradlew :app:assembleDebug` from `android/`.
- Localization changes: verify ARB files and generated localization files stay
  consistent.
- Shortcut behaviour changes should be checked on an emulator when practical,
  especially create, launch, rename, reset name, reorder, remove, and source app
  uninstall flows.
- Gradle builds may emit deprecation or plugin warnings. Treat a successful
  assemble as useful, but still surface warnings if they are newly introduced or
  related to the change.

## Dependency Notes

- `installed_apps` is intentionally pinned at `2.1.0` in this project history.
  Do not bump it casually without verifying the Android build.
- Kotlin, Android Gradle Plugin, and Gradle versions live in the Android Gradle
  files and wrapper. Keep them compatible with the current Flutter toolchain.

## Agent Operating Rules

- Prefer `rg` and `rg --files` for searches.
- Use `apply_patch` for manual edits.
- Do not perform destructive git or filesystem actions without explicit user
  approval.
- If a change touches launcher behaviour, explain the user-visible effect in
  the final status report.
- Keep final reports concise: changed files, integrity checks, and any residual
  risk.

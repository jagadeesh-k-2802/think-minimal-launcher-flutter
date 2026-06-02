import 'dart:typed_data';

class AppInfo {
  static const Object _unset = Object();

  final String name;
  final Uint8List? icon;
  final String packageName;
  final String versionName;
  final int versionCode;
  final int installedTimestamp;
  final String? customName;

  AppInfo({
    required this.name,
    this.icon,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.installedTimestamp,
    this.customName,
  });

  /// Returns the display name - custom name if set, otherwise system name
  String get displayName => customName ?? name;

  /// Creates a copy of this AppInfo with updated fields
  AppInfo copyWith({
    String? name,
    Uint8List? icon,
    String? packageName,
    String? versionName,
    int? versionCode,
    int? installedTimestamp,
    Object? customName = _unset,
  }) {
    return AppInfo(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      packageName: packageName ?? this.packageName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      installedTimestamp: installedTimestamp ?? this.installedTimestamp,
      customName: identical(customName, _unset)
          ? this.customName
          : customName as String?,
    );
  }

  factory AppInfo.fromInstalledApps(dynamic app) {
    return AppInfo(
      name: app.name as String,
      icon: app.icon as Uint8List?,
      packageName: app.packageName as String,
      versionName: app.versionName as String,
      versionCode: app.versionCode as int,
      installedTimestamp: app.installedTimestamp as int,
    );
  }

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      name: json['name'] as String,
      icon: json['icon'] as Uint8List?,
      packageName: json['packageName'] as String,
      versionName: json['versionName'] as String,
      versionCode: json['versionCode'] as int,
      installedTimestamp: json['installedTimestamp'] as int,
      customName: json['customName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'packageName': packageName,
      'versionName': versionName,
      'versionCode': versionCode,
      'installedTimestamp': installedTimestamp,
      'customName': customName,
    };
  }
}

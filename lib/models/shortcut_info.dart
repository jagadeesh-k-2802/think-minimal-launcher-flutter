class ShortcutInfo {
  static const Object _unset = Object();

  final String id;
  final String packageName;
  final String displayName;
  final String label; // Original label from the system
  final String? customName; // User override
  final String? sourceAppName; // App that published this shortcut
  final int order; // Order position on the home screen

  ShortcutInfo({
    required this.id,
    required this.packageName,
    required this.displayName,
    required this.label,
    this.customName,
    this.sourceAppName,
    required this.order,
  });

  String get name => customName ?? displayName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'displayName': displayName,
      'label': label,
      'customName': customName,
      'sourceAppName': sourceAppName,
      'order': order,
    };
  }

  factory ShortcutInfo.fromJson(Map<String, dynamic> json) {
    return ShortcutInfo(
      id: json['id'] as String,
      packageName: json['packageName'] as String,
      displayName: json['displayName'] as String,
      label: json['label'] as String? ?? json['displayName'] as String,
      customName: json['customName'] as String?,
      sourceAppName: json['sourceAppName'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  ShortcutInfo copyWith({
    String? id,
    String? packageName,
    String? displayName,
    String? label,
    Object? customName = _unset,
    Object? sourceAppName = _unset,
    int? order,
  }) {
    return ShortcutInfo(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      label: label ?? this.label,
      customName: identical(customName, _unset)
          ? this.customName
          : customName as String?,
      sourceAppName: identical(sourceAppName, _unset)
          ? this.sourceAppName
          : sourceAppName as String?,
      order: order ?? this.order,
    );
  }
}

enum AssetSnapshotStatus { unavailable, loading, ready, error }

class AssetSnapshotModel {
  const AssetSnapshotModel({
    required this.status,
    this.updatedAt,
    this.values = const <String, int>{},
    this.message,
  });

  const AssetSnapshotModel.unavailable()
    : status = AssetSnapshotStatus.unavailable,
      updatedAt = null,
      values = const <String, int>{},
      message = '资产采集接口尚未接入，当前保留界面入口。';

  factory AssetSnapshotModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString().trim().toLowerCase();
    final status = switch (rawStatus) {
      'ready' => AssetSnapshotStatus.ready,
      'loading' => AssetSnapshotStatus.loading,
      'error' => AssetSnapshotStatus.error,
      _ => AssetSnapshotStatus.unavailable,
    };
    final rawValues = json['values'];
    final values = <String, int>{};
    if (rawValues is Map) {
      for (final entry in rawValues.entries) {
        final value = entry.value;
        if (value is num) {
          values[entry.key.toString()] = value.toInt();
        } else if (value is String) {
          values[entry.key.toString()] = int.tryParse(value) ?? 0;
        }
      }
    }
    return AssetSnapshotModel(
      status: status,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      values: values,
      message: json['message']?.toString(),
    );
  }

  final AssetSnapshotStatus status;
  final DateTime? updatedAt;
  final Map<String, int> values;
  final String? message;

  bool get isReady => status == AssetSnapshotStatus.ready;

  int quantity(String variableName) => values[variableName] ?? 0;

  String get formattedUpdatedAt {
    final value = updatedAt;
    if (value == null) return '';
    String two(int input) => input.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}

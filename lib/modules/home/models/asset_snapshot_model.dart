enum AssetSnapshotStatus { unavailable, loading, ready, error }

class AssetSnapshotModel {
  const AssetSnapshotModel({
    required this.status,
    this.updatedAt,
    this.values = const <String, int>{},
    this.message,
    this.snapshotId,
    this.identityId,
    this.reportDate,
    this.assets = const {},
    this.capture,
  });

  const AssetSnapshotModel.unavailable()
    : status = AssetSnapshotStatus.unavailable,
      updatedAt = null,
      values = const <String, int>{},
      message = '暂无资产快照，点击刷新资产执行一次采集。',
      snapshotId = null,
      identityId = null,
      reportDate = null,
      assets = const {},
      capture = null;

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
      snapshotId: (json['snapshotId'] as num?)?.toInt(),
      identityId: json['identityId']?.toString(),
      reportDate: json['reportDate']?.toString(),
      assets: {
        if (json['assets'] is Map)
          for (final e in (json['assets'] as Map).entries)
            e.key.toString(): AssetObservation.fromJson(
              Map<String, dynamic>.from(e.value as Map),
            ),
      },
      capture: json['capture'] is Map
          ? AssetCapture.fromJson(Map<String, dynamic>.from(json['capture']))
          : null,
    );
  }

  final AssetSnapshotStatus status;
  final DateTime? updatedAt;
  final Map<String, int> values;
  final String? message;
  final int? snapshotId;
  final String? identityId;
  final String? reportDate;
  final Map<String, AssetObservation> assets;
  final AssetCapture? capture;

  bool get isReady => status == AssetSnapshotStatus.ready;

  int quantity(String variableName) => values[variableName] ?? 0;

  String get formattedUpdatedAt {
    final value = updatedAt == null
        ? null
        : (updatedAt!.isUtc
              ? updatedAt!.add(const Duration(hours: 8))
              : updatedAt);
    if (value == null) return '';
    String two(int input) => input.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}

class AssetObservation {
  const AssetObservation({
    this.quantity,
    this.source = 'legacy_unknown',
    this.observedAt,
    this.precision = 'unknown',
    this.delta,
    this.approximate = false,
    this.changeStatus = 'no_baseline',
    this.explanation = '',
  });
  factory AssetObservation.fromJson(Map<String, dynamic> json) {
    final change = json['change'] is Map ? json['change'] as Map : const {};
    return AssetObservation(
      quantity: (json['quantity'] as num?)?.toInt(),
      source: json['source']?.toString() ?? 'legacy_unknown',
      observedAt: json['observedAt']?.toString(),
      precision: json['precision']?.toString() ?? 'unknown',
      delta: (change['delta'] as num?)?.toInt(),
      approximate: change['approximate'] == true,
      changeStatus: change['status']?.toString() ?? 'no_baseline',
      explanation:
          '${change['fromObservedAt'] ?? '无比较基准'} → ${change['toObservedAt'] ?? json['observedAt'] ?? '未观测'}',
    );
  }
  final int? quantity;
  final String source, precision, changeStatus, explanation;
  final String? observedAt;
  final int? delta;
  final bool approximate;
  bool get hasVisibleChange =>
      source == 'observed' && delta != null && delta != 0;
  String get badge => switch (source) {
    'carried' => '沿用',
    'assumed_zero' => '缺测',
    'unsupported' => '不支持',
    'legacy_unknown' => '旧版本',
    _ => '',
  };
  String get description => switch (source) {
    'carried' => '本轮未观测到此项，沿用 $observedAt 的旧记录，不计入本次变化',
    'assumed_zero' => '本轮未确认数量，不能认定已消耗完毕',
    'unsupported' => '当前版本未启用该资产的识别',
    'legacy_unknown' => '来自旧版数据，需两次新版有效采集后展示较上次变化',
    _ => delta == null ? '暂无有效比较基准' : '库存净变化，$explanation',
  };
}

class AssetCapture {
  const AssetCapture({
    required this.requestId,
    required this.status,
    this.snapshotId,
    this.message,
  });
  factory AssetCapture.fromJson(Map<String, dynamic> json) => AssetCapture(
    requestId: json['requestId'].toString(),
    status: json['status']?.toString() ?? 'queued',
    snapshotId: (json['snapshotId'] as num?)?.toInt(),
    message: json['message']?.toString(),
  );
  final String requestId, status;
  final int? snapshotId;
  final String? message;
  bool get active => status == 'queued' || status == 'running';
}

String formatAssetNumber(int value) {
  final absolute = value.abs();
  final unit = absolute >= 100000000
      ? 100000000
      : absolute >= 10000
      ? 10000
      : 1;
  if (unit == 1) return value.toString();
  final number = (value / unit)
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'\.?0+$'), '');
  return '$number${unit == 10000 ? '万' : '亿'}';
}

String formatAssetDelta(int? value, {bool approximate = false}) {
  if (value == null) return '—';
  if (value == 0) return '0';
  return '${approximate ? '≈' : ''}${value > 0 ? '↑ +' : '↓ -'}${formatAssetNumber(value.abs())}';
}

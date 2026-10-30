/// Lifecycle state reserved for the future OAS asset snapshot endpoint.
enum AssetSnapshotStatus { unavailable, loading, ready, error }

/// UI-side snapshot model kept separate from the future backend response.
class AssetSnapshotModel {
  const AssetSnapshotModel({
    required this.status,
    this.updatedAt,
    this.values = const <String, Object?>{},
    this.message,
  });

  const AssetSnapshotModel.unavailable()
    : status = AssetSnapshotStatus.unavailable,
      updatedAt = null,
      values = const <String, Object?>{},
      message = '资产采集接口尚未接入，当前保留界面入口。';

  final AssetSnapshotStatus status;
  final DateTime? updatedAt;
  final Map<String, Object?> values;
  final String? message;

  bool get isReady => status == AssetSnapshotStatus.ready;
}

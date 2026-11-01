part of 'api_client.dart';

extension ApiClientAssetSnapshotX on ApiClient {
  Future<AssetSnapshotModel> getAssetSnapshot(String scriptName) async {
    final res = await request(
      () => get('/${Uri.encodeComponent(scriptName)}/asset_snapshot'),
    );
    if (!res.isSuccess || res.data is! Map) {
      return AssetSnapshotModel(
        status: AssetSnapshotStatus.error,
        message: res.error ?? '资产快照接口请求失败',
      );
    }
    return AssetSnapshotModel.fromJson(
      Map<String, dynamic>.from(res.data as Map),
    );
  }
}

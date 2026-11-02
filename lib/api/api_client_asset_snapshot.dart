part of 'api_client.dart';

extension ApiClientAssetSnapshotX on ApiClient {
  Options get _assetOptions => Options(
    extra: _cacheOptions.copyWith(policy: CachePolicy.noCache).toExtra(),
  );
  Future<Map<String, dynamic>> _assetGet(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await request(
      () => get(path, queryParameters: query, options: _assetOptions),
    );
    if (!res.isSuccess || res.data is! Map) {
      throw Exception(res.error ?? '资产接口响应无效');
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<AssetSnapshotModel> getAssetSnapshot(
    String scriptName, {
    String compare = 'previous',
  }) async => AssetSnapshotModel.fromJson(
    await _assetGet(
      '/${Uri.encodeComponent(scriptName)}/asset_snapshot',
      query: {'compare': compare},
    ),
  );
  Future<AssetHistoryModel> getAssetHistory(
    String scriptName,
    String asset,
    int snapshotId,
    String reportDate,
  ) async => AssetHistoryModel.fromJson(
    await _assetGet(
      '/${Uri.encodeComponent(scriptName)}/asset_snapshot/history',
      query: {
        'asset': asset,
        'days': 7,
        'as_of_snapshot_id': snapshotId,
        'report_date': reportDate,
      },
    ),
  );
  Future<AssetCapture> captureAssets(
    String scriptName,
    String idempotencyKey,
  ) async {
    final res = await request(
      () => post(
        '/${Uri.encodeComponent(scriptName)}/asset_snapshot/captures',
        data: {'idempotencyKey': idempotencyKey},
        options: _assetOptions,
      ),
    );
    if (!res.isSuccess || res.data is! Map) {
      throw Exception(res.error ?? '采集请求提交失败');
    }
    return AssetCapture.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<AssetCapture> getAssetCapture(
    String scriptName,
    String requestId,
  ) async => AssetCapture.fromJson(
    await _assetGet(
      '/${Uri.encodeComponent(scriptName)}/asset_snapshot/captures/${Uri.encodeComponent(requestId)}',
    ),
  );
}

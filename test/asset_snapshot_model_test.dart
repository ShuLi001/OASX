import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/models/asset_snapshot_model.dart';

void main() {
  test('parses a ready OAS snapshot and normalizes numeric values', () {
    final model = AssetSnapshotModel.fromJson({
      'status': 'ready',
      'updatedAt': '2026-11-01T16:49:15',
      'values': {'gold': 9050000, 'mystic_talisman': '32', 'missing': null},
    });

    expect(model.isReady, isTrue);
    expect(model.updatedAt?.year, 2026);
    expect(model.quantity('gold'), 9050000);
    expect(model.quantity('mystic_talisman'), 32);
    expect(model.quantity('missing'), 0);
  });

  test('invalid and unavailable snapshots expose a user-facing message', () {
    final model = AssetSnapshotModel.fromJson({
      'status': 'error',
      'message': '读取失败',
      'values': <String, dynamic>{},
    });

    expect(model.status, AssetSnapshotStatus.error);
    expect(model.message, '读取失败');
    expect(model.isReady, isFalse);
  });
}

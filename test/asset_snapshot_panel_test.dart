import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/widgets/asset_snapshot_panel.dart';
import 'package:oasx/modules/home/models/asset_snapshot_model.dart';

void main() {
  testWidgets('renders the shared snapshot surface and refresh action', (
    tester,
  ) async {
    var refreshed = false;
    await tester.binding.setSurfaceSize(const Size(320, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetSnapshotPanel(
            compact: true,
            model: AssetSnapshotModel.fromJson({
              'status': 'ready',
              'updatedAt': '2026-11-01T16:49:15',
              'values': {'gold': 9050000},
            }),
            onRefresh: () => refreshed = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('资产快照'), findsOneWidget);
    expect(find.text('货币'), findsOneWidget);
    expect(find.text('物品库·资源'), findsOneWidget);
    expect(find.text('更新时间：2026-11-01 16:49:15'), findsOneWidget);
    expect(find.text('金币'), findsOneWidget);
    expect(find.text('905万'), findsOneWidget);
    expect(find.text('9050000'), findsNothing);
    expect(find.text('神秘的符咒'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('asset-snapshot-currencies-two-column'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('asset-snapshot-resources-two-column')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('刷新资产'));
    expect(refreshed, isTrue);
  });

  testWidgets('shows an unavailable message when no snapshot exists', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetSnapshotPanel(
            compact: true,
            model: AssetSnapshotModel.unavailable(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('资产采集接口尚未接入，当前保留界面入口。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to one column at the narrowest width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(260, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AssetSnapshotPanel(
            compact: true,
            model: AssetSnapshotModel(
              status: AssetSnapshotStatus.ready,
              values: <String, int>{'gold': 1},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey<String>('asset-snapshot-currencies-one-column'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('asset-snapshot-resources-one-column')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

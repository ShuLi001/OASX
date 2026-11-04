import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:oasx/modules/home/controllers/asset_controller.dart';
import 'package:oasx/modules/home/models/asset_history_model.dart';
import 'package:oasx/modules/home/models/asset_snapshot_model.dart';
import 'package:oasx/modules/home/models/asset_snapshot_catalog.dart';
import 'package:oasx/modules/home/widgets/asset_snapshot_panel.dart';
import 'package:oasx/modules/home/widgets/asset_history_chart.dart';

AssetSnapshotModel snapshot([int id = 1]) => AssetSnapshotModel.fromJson({
  'status': 'ready',
  'snapshotId': id,
  'identityId': 'test',
  'reportDate': '2026-11-02',
  'updatedAt': '2026-11-02T12:00:00Z',
  'values': {
    for (final e in [
      ...AssetSnapshotCatalog.currencies,
      ...AssetSnapshotCatalog.resources,
    ])
      e.variableName: 1234567,
  },
  'assets': {
    for (final e in [
      ...AssetSnapshotCatalog.currencies,
      ...AssetSnapshotCatalog.resources,
    ])
      e.variableName: {
        'quantity': 1234567,
        'source': e.variableName == 'jade' ? 'carried' : 'observed',
        'precision': 'exact',
        'observedAt': '2026-11-02T12:00:00Z',
        'change': {
          'status': 'ok',
          'delta': e.variableName == 'jade' ? null : -12600,
          'approximate': e.variableName == 'gold',
        },
      },
  },
});

AssetHistoryModel history([
  String asset = 'gold',
]) => AssetHistoryModel.fromJson({
  'asset': asset,
  'window': {
    'startDate': '2026-10-27',
    'endDate': '2026-11-02',
    'todayProvisional': true,
  },
  'summary': {
    'netChange': -12600,
    'observedDayCount': 6,
    'comparableDayCount': 4,
    'hasGaps': true,
    'missingDates': ['2026-10-29'],
    'recordCount': 7,
    'observedRecordCount': 6,
    'comparableRecordCount': 5,
  },
  'records': [
    for (var i = 0; i < 7; i++)
      {
        'snapshotId': i + 1,
        'queriedAt':
            '${['2026-10-27', '2026-10-28', '2026-10-29', '2026-10-30', '2026-10-31', '2026-11-01', '2026-11-02'][i]}T12:00:00+08:00',
        'quantity': i == 2 ? null : 126000 - i * 2000,
        'observed': i != 2,
        'delta': i == 2 || i == 3 ? null : -2000,
      },
  ],
  'daily': [
    for (var i = 0; i < 7; i++)
      {
        'date': [
          '2026-10-27',
          '2026-10-28',
          '2026-10-29',
          '2026-10-30',
          '2026-10-31',
          '2026-11-01',
          '2026-11-02',
        ][i],
        'closeValue': i == 2 ? null : 126000 - i * 2000,
        'delta': i == 2 || i == 3 ? null : -2000,
      },
  ],
});

void main() {
  setUpAll(() async {
    final font = File('C:/Windows/Fonts/msyh.ttc');
    if (font.existsSync()) {
      final loader = FontLoader('AssetReviewSans')
        ..addFont(
          font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
    final icons = File(
      'D:/AndroidDev/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
          icons.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
  });
  test('nullable delta, quality, UTC+8 time and signed compact values', () {
    final model = snapshot();
    expect(model.formattedUpdatedAt, '2026-11-02 20:00:00');
    expect(model.assets['jade']!.delta, isNull);
    expect(model.assets['jade']!.badge, '沿用');
    expect(formatAssetDelta(null), '—');
    expect(formatAssetDelta(0), '0');
    expect(formatAssetDelta(-12600, approximate: true), '≈↓ -1.26万');
    expect(formatAssetDelta(20), '↑ +20');
    expect(
      const AssetObservation(
        source: 'observed',
        quantity: 10,
        delta: 0,
      ).hasVisibleChange,
      isFalse,
    );
    expect(
      const AssetObservation(
        source: 'carried',
        quantity: 10,
        delta: 20,
      ).hasVisibleChange,
      isFalse,
    );
    expect(
      const AssetObservation(
        source: 'observed',
        quantity: 10,
        delta: null,
      ).hasVisibleChange,
      isFalse,
    );
    expect(
      const AssetObservation(
        source: 'observed',
        quantity: 10,
        delta: -1,
      ).hasVisibleChange,
      isTrue,
    );
  });

  testWidgets('capture submits once, polls real states and reloads success', (
    tester,
  ) async {
    final submit = Completer<AssetCapture>();
    var posts = 0, polls = 0, reads = 0;
    final controller = HomeAssetController(
      'test',
      'fake',
      loadSnapshot: (_) async {
        reads++;
        return snapshot(reads + 1);
      },
      loadHistory: (asset, id, date) async => history(asset),
      submitCapture: (_) {
        posts++;
        return submit.future;
      },
      loadCapture: (_) async => AssetCapture(
        requestId: 'request',
        status: ++polls == 1 ? 'running' : 'succeeded',
        snapshotId: 2,
      ),
    );
    addTearDown(controller.disposeState);
    final first = controller.captureOnce();
    await controller.captureOnce();
    expect(posts, 1);
    expect(controller.refreshState, 'submitting');
    submit.complete(const AssetCapture(requestId: 'request', status: 'queued'));
    await first;
    expect(controller.refreshState, 'queued');
    await tester.pump(const Duration(seconds: 2));
    expect(controller.refreshState, 'running');
    await tester.pump(const Duration(seconds: 2));
    expect(controller.refreshState, 'succeeded');
    expect(reads, 1);
    expect(controller.snapshot.snapshotId, 2);
    await tester.pump(const Duration(milliseconds: 2500));
    expect(controller.refreshState, 'idle');
    controller.disposeState();
  });

  testWidgets(
    'uncertain transport retry retains its idempotency key and data',
    (tester) async {
      final keys = <String>[];
      final controller = HomeAssetController(
        'test',
        'fake',
        loadSnapshot: (_) async => snapshot(),
        submitCapture: (key) async {
          keys.add(key);
          if (keys.length == 1) throw Exception('network timeout');
          return const AssetCapture(requestId: 'same', status: 'queued');
        },
      );
      addTearDown(controller.disposeState);
      controller.snapshot = snapshot();
      await controller.captureOnce();
      expect(controller.snapshot.isReady, isTrue);
      expect(controller.refreshState, 'failed');
      await controller.captureOnce();
      expect(keys[0], keys[1]);
      controller.disposeState();
    },
  );

  testWidgets(
    'older response and disposed controller cannot overwrite new state',
    (tester) async {
      final old = Completer<AssetSnapshotModel>();
      var calls = 0;
      final controller = HomeAssetController(
        'test',
        'fake',
        loadSnapshot: (_) =>
            ++calls == 1 ? old.future : Future.value(snapshot(2)),
        loadHistory: (asset, id, date) async => history(asset),
      );
      addTearDown(controller.disposeState);
      final first = controller.reload();
      await controller.reload();
      old.complete(snapshot(1));
      await first;
      expect(controller.snapshot.snapshotId, 2);
      final later = Completer<AssetSnapshotModel>();
      final disposed = HomeAssetController(
        'other',
        'fake',
        loadSnapshot: (_) => later.future,
      );
      final pending = disposed.reload();
      disposed.disposeState();
      later.complete(snapshot(9));
      await pending;
      expect(disposed.snapshot.isReady, isFalse);
      controller.disposeState();
    },
  );

  testWidgets('selection rejects old history responses', (tester) async {
    final first = Completer<AssetHistoryModel>();
    final controller = HomeAssetController(
      'test',
      'fake',
      loadSnapshot: (_) async => snapshot(),
      loadHistory: (asset, id, date) =>
          asset == 'gold' ? first.future : Future.value(history(asset)),
    );
    addTearDown(controller.disposeState);
    controller.snapshot = snapshot();
    final request = controller.reloadHistory();
    controller.select('mystic_talisman');
    await tester.pump();
    first.complete(history('gold'));
    await request;
    expect(controller.history!.asset, 'mystic_talisman');
  });

  testWidgets('background pauses polling and resume reloads current snapshot', (
    tester,
  ) async {
    var reads = 0;
    final controller = HomeAssetController(
      'test',
      'fake',
      loadSnapshot: (_) async {
        reads++;
        return snapshot();
      },
      loadHistory: (asset, id, date) async => history(asset),
    );
    controller.start();
    await tester.pump();
    expect(reads, 1);
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 40));
    expect(reads, 1);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(reads, 2);
    controller.disposeState();
  });

  testWidgets('chart connects across missing dates without inventing samples', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: AssetHistoryChart(model: history()),
          ),
        ),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.single.isCurved, isFalse);
    expect(find.text('10/27'), findsOneWidget);
    expect(find.text('11/02'), findsOneWidget);
    expect(chart.data.lineBarsData.single.spots, hasLength(6));
    expect(chart.data.lineBarsData.single.spots.map((spot) => spot.x), [
      12,
      36,
      84,
      108,
      132,
      156,
    ]);
    expect(
      chart.data.lineBarsData.single.spots.any((spot) => spot.isNull()),
      isFalse,
    );
    await tester.tap(find.text('变化'));
    await tester.pump();
    final bars = tester.widget<BarChart>(find.byType(BarChart));
    expect(bars.data.barGroups[2].barRods, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple queries within a day remain distinct points and bars', (
    tester,
  ) async {
    final model = AssetHistoryModel.fromJson({
      'asset': 'gold',
      'window': {'startDate': '2026-10-27', 'endDate': '2026-11-02'},
      'records': [
        {
          'snapshotId': 10,
          'queriedAt': '2026-11-02T09:00:00+08:00',
          'quantity': 100,
          'delta': 10,
          'observed': true,
        },
        {
          'snapshotId': 11,
          'queriedAt': '2026-11-02T12:00:00+08:00',
          'quantity': 100,
          'delta': 0,
          'observed': true,
        },
        {
          'snapshotId': 12,
          'queriedAt': '2026-11-02T18:00:00+08:00',
          'quantity': 120,
          'delta': 20,
          'observed': true,
        },
      ],
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AssetHistoryChart(model: model)),
      ),
    );
    final line = tester.widget<LineChart>(find.byType(LineChart));
    expect(line.data.lineBarsData.single.spots.map((point) => point.x), [
      153,
      156,
      162,
    ]);
    expect(line.data.lineBarsData.single.spots.map((point) => point.y), [
      100,
      100,
      120,
    ]);
    await tester.tap(find.text('变化'));
    await tester.pump();
    final bars = tester.widget<BarChart>(find.byType(BarChart));
    expect(bars.data.barGroups, hasLength(3));
    expect(bars.data.barGroups[1].barRods.single.toY, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'chart hover stays in a fixed readout with only a highlighted dot',
    (tester) async {
      final model = AssetHistoryModel.fromJson({
        'asset': 'jade',
        'window': {'startDate': '2026-10-27', 'endDate': '2026-11-02'},
        'records': [
          {
            'snapshotId': 1,
            'queriedAt': '2026-11-02T18:00:00+08:00',
            'quantity': 9704,
            'observed': false,
          },
          {
            'snapshotId': 2,
            'queriedAt': '2026-11-02T23:59:59+08:00',
            'quantity': 11265,
            'delta': 207,
            'observed': true,
          },
        ],
      });
      for (final width in [260.0, 360.0, 600.0]) {
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              fontFamily: 'AssetReviewSans',
              colorSchemeSeed: const Color(0xFF7556FF),
            ),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: Container(
                    width: width,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFF7F3FA),
                    child: AssetHistoryChart(
                      key: ValueKey(width),
                      model: model,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final chart = tester.widget<LineChart>(find.byType(LineChart));
        final data = chart.data;
        final bar = data.lineBarsData.single;
        final indicator = data.lineTouchData.getTouchedSpotIndicator(bar, [
          1,
        ]).single!;
        expect(indicator.indicatorBelowLine.strokeWidth, 0);
        final dot =
            indicator.touchedSpotDotData.getDotPainter(
                  bar.spots.last,
                  1,
                  bar,
                  1,
                )
                as FlDotCirclePainter;
        expect(dot.radius, 5);
        expect(
          data.lineTouchData.touchTooltipData.getTooltipItems([
            LineBarSpot(bar, 0, bar.spots.last),
          ]),
          [null],
        );
        final rect = tester.getRect(find.byType(LineChart));
        final point = bar.spots.last;
        final position = Offset(
          rect.left + 42 + (rect.width - 42) * point.x / data.maxX,
          rect.bottom -
              36 -
              (rect.height - 36) *
                  (point.y - data.minY) /
                  (data.maxY - data.minY),
        );
        final mouse = await tester.createGesture(
          kind: ui.PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: const Offset(790, 590));
        await mouse.moveTo(position);
        await tester.pumpAndSettle();
        final time = find.text('11/02 23:59:59');
        expect(time, findsOneWidget);
        expect(find.text('11265'), findsOneWidget);
        final readout = tester.getRect(
          find.byKey(const ValueKey('asset-chart-readout')),
        );
        final trendButton = tester.getRect(
          find.widgetWithText(ChoiceChip, '趋势'),
        );
        final changeButton = tester.getRect(
          find.widgetWithText(ChoiceChip, '变化'),
        );
        expect(trendButton.width, lessThan(60));
        expect(changeButton.width, lessThan(60));
        expect(changeButton.right, lessThan(readout.left));
        expect(changeButton.top, closeTo(trendButton.top, .1));
        expect(readout.top, closeTo(trendButton.top, .1));
        expect(readout.contains(tester.getCenter(time)), isTrue);
        expect(readout.right, lessThanOrEqualTo(width));
        expect(readout.bottom, lessThanOrEqualTo(rect.top));
        expect(tester.getRect(find.byType(LineChart)), rect);
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            'build/asset_changes_review/chart_readout_${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await mouse.moveTo(const Offset(790, 590));
        await tester.pumpAndSettle();
        expect(time, findsNothing);
        expect(tester.getRect(find.byType(LineChart)), rect);
        await mouse.removePointer();
        await tester.tap(find.text('变化'));
        await tester.pumpAndSettle();
        expect(time, findsNothing);
        final bars = tester.widget<BarChart>(find.byType(BarChart));
        final barsRect = tester.getRect(find.byType(BarChart));
        final positive = bars.data.barGroups.last;
        // Exercise the bar callback while its tooltip is disabled as well.
        bars.data.barTouchData.touchCallback!(
          FlTapDownEvent(TapDownDetails()),
          BarTouchResponse(
            BarTouchedSpot(
              positive,
              1,
              positive.barRods.single,
              0,
              null,
              -1,
              const FlSpot(1, 207),
              Offset.zero,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(time, findsOneWidget);
        expect(find.text('+207'), findsOneWidget);
        expect(tester.getRect(find.byType(BarChart)), barsRect);
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final width in [260.0, 310.0, 360.0, 620.0, 980.0, 1200.0]) {
    testWidgets(
      'responsive assets $width has no overflow and can select cards',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final controller = HomeAssetController(
          'test',
          'fake',
          loadSnapshot: (_) async => snapshot(),
          loadHistory: (asset, id, date) async => history(asset),
        );
        addTearDown(controller.disposeState);
        controller.snapshot = snapshot();
        controller.history = history();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AssetSnapshotPanel(
                controller: controller,
                compact: width < 600,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('↓ -1.26万'), findsWidgets);
        await tester.tap(find.text('体力').first);
        await tester.pumpAndSettle();
        expect(controller.selectedAsset, 'stamina');
        expect(tester.takeException(), isNull);
        if (width == 360 || width == 1200) {
          final key = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                fontFamily: 'AssetReviewSans',
                colorSchemeSeed: const Color(0xFF7556FF),
              ),
              home: Scaffold(
                body: RepaintBoundary(
                  key: key,
                  child: Theme(
                    data: ThemeData(
                      fontFamily: 'AssetReviewSans',
                      colorSchemeSeed: const Color(0xFF7556FF),
                    ),
                    child: ColoredBox(
                      color: const Color(0xFFF7F7FC),
                      child: AssetSnapshotPanel(
                        controller: controller,
                        compact: width < 600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final dir = Directory('build/asset_changes_review')
              ..createSync(recursive: true);
            File(
              '${dir.path}/assets_${width.toInt()}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
  }

  testWidgets('large type and dark theme keep cards readable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(body: AssetSnapshotPanel(model: snapshot())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero and missing observations leave card suffix empty', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AssetSnapshotPanel(
            model: AssetSnapshotModel(
              status: AssetSnapshotStatus.ready,
              values: {'gold': 100, 'stamina': 200},
              assets: {
                'gold': AssetObservation(
                  source: 'observed',
                  quantity: 100,
                  delta: 0,
                ),
                'stamina': AssetObservation(source: 'carried', quantity: 200),
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
    expect(find.text('200'), findsOneWidget);
    expect(find.text('—'), findsNothing);
    expect(find.text('沿用'), findsNothing);
    expect(find.text('定位趋势'), findsNothing);
    expect(find.text('返回列表'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [260.0, 360.0, 620.0, 1200.0]) {
    testWidgets('inline trend follows selected row at width $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = HomeAssetController(
        'test',
        'fake',
        loadSnapshot: (_) async => snapshot(),
        loadHistory: (asset, id, date) async => history(asset),
      );
      controller.snapshot = snapshot();
      controller.history = history();
      addTearDown(controller.disposeState);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            fontFamily: 'AssetReviewSans',
            colorSchemeSeed: const Color(0xFF7556FF),
          ),
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
              child: ColoredBox(
                color: const Color(0xFFF7F7FC),
                child: AssetSnapshotPanel(
                  controller: controller,
                  compact: width < 600,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final trend = find.byKey(const ValueKey('asset-inline-trend'));
      expect(trend, findsNothing);
      expect(find.text('定位趋势'), findsNothing);
      final visibleObservedCount =
          AssetSnapshotCatalog.currencies.length +
          AssetSnapshotCatalog.resources.length -
          1; // Jade is carried in this fixture.
      expect(find.text('本次更新$visibleObservedCount项'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('asset-card-gold')));
      await tester.pumpAndSettle();
      expect(trend, findsOneWidget);
      final panel = tester.getRect(trend);
      final row = tester.getRect(
        find.byKey(const ValueKey('asset-currencies-row-0')),
      );
      expect(panel.top, greaterThan(row.bottom));
      if (width < 1000) {
        final next = tester.getRect(
          find.byKey(const ValueKey('asset-currencies-row-1')),
        );
        expect(panel.bottom, lessThan(next.top));
      }
      expect(find.textContaining('近7天净变化'), findsNothing);
      expect(find.textContaining('未有效观测日期'), findsNothing);
      expect(find.textContaining('UTC+08:00'), findsNothing);
      expect(find.textContaining('观测时间：'), findsNothing);
      expect(find.textContaining('全部查询记录'), findsNothing);
      expect(find.byKey(const ValueKey('asset-query-7')), findsNothing);
      if (width == 360 || width == 1200) {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('build/asset_changes_review')
            ..createSync(recursive: true);
          File(
            '${dir.path}/assets_inline_${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      final stamina = find.byKey(const ValueKey('asset-card-stamina'));
      await tester.ensureVisible(stamina);
      await tester.tap(stamina);
      await tester.pumpAndSettle();
      expect(trend, findsOneWidget);
      expect(find.text('七日变化量 · 体力'), findsOneWidget);
      await tester.ensureVisible(stamina);
      await tester.tap(stamina);
      await tester.pumpAndSettle();
      expect(trend, findsNothing);
      final material = find.byKey(const ValueKey('asset-card-mystic_talisman'));
      await tester.ensureVisible(material);
      await tester.tap(material);
      await tester.pumpAndSettle();
      expect(trend, findsOneWidget);
      expect(find.text('七日变化量 · 神秘的符咒'), findsOneWidget);
      final materialPanel = tester.getRect(trend);
      final columns = width == 260
          ? 1
          : width == 360
          ? 2
          : width == 620
          ? 3
          : 4;
      final resourceRow = columns == 1 ? 1 : 0;
      expect(
        materialPanel.top,
        greaterThan(
          tester
              .getRect(find.byKey(ValueKey('asset-resources-row-$resourceRow')))
              .bottom,
        ),
      );
      expect(
        materialPanel.bottom,
        lessThan(
          tester
              .getRect(
                find.byKey(ValueKey('asset-resources-row-${resourceRow + 1}')),
              )
              .top,
        ),
      );
      await tester.ensureVisible(find.byTooltip('收起趋势'));
      await tester.tap(find.byTooltip('收起趋势'));
      await tester.pumpAndSettle();
      expect(trend, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty inline trend stays compact', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = HomeAssetController(
      'test',
      'fake',
      loadSnapshot: (_) async => snapshot(),
    );
    controller.snapshot = snapshot();
    controller.history = AssetHistoryModel.fromJson({
      'asset': 'gold',
      'records': [],
      'window': {'startDate': '2026-10-27', 'endDate': '2026-11-02'},
    });
    addTearDown(controller.disposeState);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AssetSnapshotPanel(controller: controller)),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('asset-card-gold')));
    await tester.pumpAndSettle();
    expect(find.text('近7天暂无查询记录，更新后将自动积累'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('asset-inline-trend'))).height,
      lessThan(150),
    );
    expect(tester.takeException(), isNull);
  });
}

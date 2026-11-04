import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_nb_net/flutter_net.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/home/models/taskitem_model.dart';
import 'package:oasx/modules/home/widgets/active_config_panel.dart';
import 'package:oasx/modules/home/widgets/task_status_row.dart';
import 'package:oasx/translation/i18n.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/websocket_service.dart';

class _Storage implements HomeDashboardStorage {
  @override
  dynamic read(String key) => null;
  @override
  void write(String key, dynamic value) {}
}

class _Scripts extends ScriptService {
  @override
  // ignore: must_call_super
  Future<void> onInit() async {}
  @override
  Future<void> onClose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HomeDashboardController dashboard;
  late List<String> actions;
  final previewKey = GlobalKey();

  setUpAll(() async {
    final directory = Directory.systemTemp.createTempSync('mobile_layout_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    await GetStorage('GetStorage', directory.path).initStorage;
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });

  setUp(() {
    Get.testMode = true;
    actions = [];
    final model = ScriptModel('日常大号');
    model.state.value = ScriptState.running;
    model.waitingTaskList.assignAll([
      for (final name in ['结界蹭卡', '悬赏封印', '花合战', '每日独享'])
        TaskItemModel(model.name, name, '2026-11-03 08:25:00'),
    ]);
    Get.put(WebSocketService());
    Get.put<ScriptService>(_Scripts()).addScriptModel(model);
    Get.put(ArgsController());
    dashboard = HomeDashboardController(storage: _Storage());
    dashboard.activeScriptName.value = model.name;
  });
  tearDown(() => Get.reset());

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(360, 740),
    double scale = 1,
    TargetPlatform platform = TargetPlatform.android,
    bool dark = false,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        locale: const Locale('zh', 'CN'),
        translations: Messages(),
        theme: (dark ? darkTheme : lightTheme).copyWith(platform: platform),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: RepaintBoundary(
              key: previewKey,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ActiveConfigPanel(
                  controller: dashboard,
                  layoutMode: HomeWorkbenchLayoutMode.singlePane,
                  onChangeTab: (tab) async {
                    dashboard.activeWorkbenchTab.value = tab;
                  },
                  onOpenTask: (name, _) async => actions.add('edit:$name'),
                  onTogglePower: (name, enabled) async =>
                      actions.add('power:$enabled'),
                  onRenameScript: (_) async {},
                  onDeleteScript: (_) async {},
                  onSetNextRun: (_, __) async {},
                  onQuickRun: (name) async => actions.add('run:$name'),
                  onQuickWait: (name) async => actions.add('wait:$name'),
                  onBulkQuickRun: () async => actions.add('bulk:run'),
                  onBulkQuickWait: () async => actions.add('bulk:wait'),
                  onBackToScripts: () => actions.add('back'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  void mockTaskCatalog() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => 'wifi',
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/connectivity'),
            null,
          ),
    );
    ApiClient();
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response(
          requestOptions: options,
          data: {
            'data': {
              '日常任务': ['结界蹭卡', '悬赏封印', '花合战'],
            },
          },
        ),
      ),
    );
    NetOptions.instance.dio.interceptors.insert(0, interceptor);
    addTearDown(() => NetOptions.instance.dio.interceptors.remove(interceptor));
    dashboard.activeWorkbenchTab.value = HomeWorkbenchTab.tasks;
  }

  for (final width in [320.0, 360.0, 412.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'Android $width wide at ${scale}x keeps header and tasks usable',
        (tester) async {
          await mount(tester, size: Size(width, 740), scale: scale);
          expect(tester.takeException(), isNull);
          final title = tester.getRect(find.text('日常大号'));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text('日常大号'),
          );
          expect(paragraph.constraints.maxWidth, greaterThan(width / 2));
          expect(title.height, lessThan(40 * scale));
          final row = find.byType(TaskStatusRow).first;
          final rowRect = tester.getRect(row);
          Rect? previous;
          for (final action in [
            (I18n.homeQuickRun.tr, 'run'),
            (I18n.homeQuickWait.tr, 'wait'),
            (I18n.homeOpenTaskParams.tr, 'edit'),
          ]) {
            final button = find.descendant(
              of: row,
              matching: find.byTooltip(action.$1),
            );
            final rect = tester.getRect(button);
            expect(rect.left, greaterThanOrEqualTo(rowRect.left));
            expect(rect.right, lessThanOrEqualTo(rowRect.right));
            expect(rect.top, greaterThanOrEqualTo(rowRect.top));
            expect(rect.bottom, lessThanOrEqualTo(rowRect.bottom));
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            if (previous != null) {
              expect(rect.left, greaterThanOrEqualTo(previous.right));
            }
            expect(
              rect.overlaps(tester.getRect(find.text('结界蹭卡').first)),
              isFalse,
            );
            previous = rect;
            await tester.tap(button, warnIfMissed: false);
            expect(actions.last, '${action.$2}:结界蹭卡');
          }
          expect(find.byTooltip('任务操作'), findsNothing);
          final chips = find.byType(ChoiceChip);
          final top = tester.getTopLeft(chips.first).dy;
          for (final chip in chips.evaluate()) {
            expect(tester.getTopLeft(find.byWidget(chip.widget)).dy, top);
          }
        },
      );
    }
  }

  testWidgets('Android inline buttons preserve quick actions and parameters', (
    tester,
  ) async {
    await mount(tester);
    for (final action in [
      (I18n.homeQuickRun.tr, 'run'),
      (I18n.homeQuickWait.tr, 'wait'),
      (I18n.homeOpenTaskParams.tr, 'edit'),
    ]) {
      await tester.tap(find.byTooltip(action.$1).first);
      await tester.pumpAndSettle();
      expect(actions.last, '${action.$2}:结界蹭卡');
    }
    await tester.tap(find.widgetWithText(OutlinedButton, I18n.stop.tr));
    await tester.tap(find.byTooltip(I18n.homeQuickRunAll.tr));
    expect(actions, containsAll(['power:false', 'bulk:run']));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bulk scheduling disables quick buttons but retains editing', (
    tester,
  ) async {
    dashboard.bulkQuickScheduleMode.value = HomeBulkQuickScheduleMode.runNow;
    await mount(tester);
    final row = find.byType(TaskStatusRow).first;
    final buttons = tester
        .widgetList<IconButton>(
          find.descendant(of: row, matching: find.byType(IconButton)),
        )
        .toList();
    expect(buttons.map((button) => button.onPressed != null), [
      false,
      false,
      true,
    ]);
    await tester.tap(find.byTooltip(I18n.homeOpenTaskParams.tr).first);
    expect(actions, ['edit:结界蹭卡']);
  });

  testWidgets(
    'selected offscreen tab is revealed and keeps selection on resize',
    (tester) async {
      await mount(tester);
      await tester.drag(
        find.byKey(const ValueKey('home-scrollable-tabs')),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('指引'));
      await tester.pumpAndSettle();
      expect(dashboard.activeWorkbenchTab.value, HomeWorkbenchTab.guide);
      await tester.binding.setSurfaceSize(const Size(740, 360));
      await tester.pumpAndSettle();
      expect(dashboard.activeWorkbenchTab.value, HomeWorkbenchTab.guide);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(480, 320),
    const Size(900, 600),
    const Size(1200, 740),
  ]) {
    testWidgets('landscape and tablet $size fit without clipping', (
      tester,
    ) async {
      await mount(tester, size: size, dark: true);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('desktop retains inline task buttons and wide header', (
    tester,
  ) async {
    await mount(
      tester,
      size: const Size(1200, 740),
      platform: TargetPlatform.windows,
    );
    expect(find.byKey(const ValueKey('home-compact-header')), findsNothing);
    expect(find.byTooltip('任务操作'), findsNothing);
    await tester.tap(find.byTooltip(I18n.homeOpenTaskParams.tr).first);
    expect(actions, ['edit:结界蹭卡']);
    expect(tester.takeException(), isNull);
  });

  for (final paneWidth in [419.0, 420.0, 480.0, 600.0, 607.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'PC overview pane $paneWidth at ${scale}x retains desktop columns',
        (tester) async {
          // This theme has zero card margin; outer and inner padding each use 24px.
          await mount(
            tester,
            size: Size(paneWidth + 48, 740),
            scale: scale,
            platform: TargetPlatform.windows,
          );
          final grid = find.byKey(
            const PageStorageKey<String>('home-task-status-list'),
          );
          expect(tester.getSize(grid).width, closeTo(paneWidth, .01));
          final rows = find.byType(TaskStatusRow);
          final first = tester.getTopLeft(rows.at(0));
          final second = tester.getTopLeft(rows.at(1));
          if (paneWidth >= 420) {
            expect(second.dy, first.dy);
            expect(second.dx, greaterThan(first.dx));
          } else {
            expect(second.dy, greaterThan(first.dy));
          }
          final edit = find.descendant(
            of: rows.first,
            matching: find.byTooltip(I18n.homeOpenTaskParams.tr),
          );
          expect(tester.getSize(edit).width, lessThan(48));
          await tester.tap(edit);
          expect(actions, ['edit:结界蹭卡']);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final platform in [TargetPlatform.windows, TargetPlatform.android]) {
    testWidgets('$platform task catalog retains its platform column rules', (
      tester,
    ) async {
      mockTaskCatalog();
      await mount(tester, size: const Size(1200, 740), platform: platform);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      final grid = tester.widget<GridView>(find.byType(GridView).first);
      if (platform == TargetPlatform.windows) {
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
        expect(delegate.maxCrossAxisExtent, 390);
        final buttons = find.byTooltip(I18n.homeOpenTaskParams.tr);
        expect(
          tester.getTopLeft(buttons.at(0)).dy,
          tester.getTopLeft(buttons.at(2)).dy,
        );
      } else {
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, 2);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'short viewport above Android keyboard can scroll to task actions',
    (tester) async {
      await mount(tester, size: const Size(360, 280), scale: 2);
      expect(tester.takeException(), isNull);
      final button = find.byTooltip(I18n.homeOpenTaskParams.tr).first;
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(actions, ['edit:结界蹭卡']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Android task catalog keeps cards readable at narrow and large fonts',
    (tester) async {
      mockTaskCatalog();
      await mount(tester, size: const Size(320, 740), scale: 2);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byTooltip(I18n.homeOpenTaskParams.tr).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(I18n.homeOpenTaskParams.tr).first);
      expect(actions, ['edit:结界蹭卡']);
    },
  );

  if (const bool.fromEnvironment('CAPTURE_LAYOUT')) {
    testWidgets('render Android layout preview', (tester) async {
      final font = FontLoader('Microsoft YaHei')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('C:/Windows/Fonts/msyh.ttc').readAsBytesSync(),
            ),
          ),
        );
      await font.load();
      await (FontLoader(
        'LatoLato',
      )..addFont(rootBundle.load('assets/Lato-Regular.ttf'))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await mount(tester);
      final boundary =
          previewKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/android-layout-preview.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    });
  }
}

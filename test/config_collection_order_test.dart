import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/config_collection_panel.dart';
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
  // Skip networking; this test exercises the real order and persistence code.
  // ignore: must_call_super
  Future<void> onInit() async {}
  @override
  Future<void> onClose() async {}
}

class _Sockets extends WebSocketService {
  @override
  Future<void> close(
    String name, {
    int code = 1000,
    String reason = 'normal close',
    bool reconnect = false,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Scripts scripts;
  late HomeDashboardController dashboard;
  late GetStorage storage;
  setUpAll(() async {
    final directory = Directory.systemTemp.createTempSync('config_order_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    storage = GetStorage('GetStorage', directory.path);
    await storage.initStorage;
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });
  setUp(() async {
    Get.testMode = true;
    await storage.erase();
    ApiClient().setAddress('http://order-test.local:22288');
    Get.put<WebSocketService>(_Sockets());
    scripts = Get.put<ScriptService>(_Scripts()) as _Scripts;
    scripts.syncScriptOrder(['A', 'hidden', 'B', 'C']);
    for (final name in ['A', 'B', 'C']) {
      scripts.findScriptModel(name)!.state.value = ScriptState.inactive;
    }
    scripts.findScriptModel('hidden')!.state.value = ScriptState.running;
    dashboard = HomeDashboardController(storage: _Storage());
    dashboard.activeScriptName.value = 'A';
  });
  tearDown(() {
    ApiClient().resetAddress();
    Get.reset();
  });

  test(
    'filtered order keeps hidden slots and survives refresh and service recreation',
    () async {
      await dashboard.reorderVisibleScripts(['A', 'B', 'C'], 0, 2);
      expect(scripts.scriptOrderList, ['B', 'hidden', 'C', 'A']);
      expect(dashboard.activeScriptName.value, 'A');
      scripts.syncScriptOrder(['A', 'B', 'C', 'hidden', 'new']);
      expect(scripts.scriptOrderList, ['B', 'hidden', 'C', 'A', 'new']);
      final recreated = _Scripts();
      recreated.syncScriptOrder(['A', 'B', 'C', 'hidden', 'new']);
      expect(recreated.scriptOrderList, scripts.scriptOrderList);
      recreated.syncScriptOrder(['A', 'C', 'hidden', 'new']);
      expect(recreated.scriptOrderList, ['hidden', 'C', 'A', 'new']);
      recreated.syncScriptOrder(['A', 'B', 'C', 'hidden', 'new']);
      expect(recreated.scriptOrderList, ['hidden', 'C', 'A', 'new', 'B']);
    },
  );

  test(
    'manual orders are isolated by backend and reject stale drag snapshots',
    () async {
      await dashboard.reorderVisibleScripts(['A', 'hidden', 'B', 'C'], 3, 0);
      expect(scripts.scriptOrderList, ['C', 'A', 'hidden', 'B']);
      ApiClient().setAddress('http://other-order-test.local:22288');
      scripts.syncScriptOrder(['A', 'hidden', 'B', 'C']);
      expect(scripts.scriptOrderList, ['A', 'hidden', 'B', 'C']);
      ApiClient().setAddress('http://order-test.local:22288');
      scripts.syncScriptOrder(['A', 'hidden', 'B', 'C']);
      expect(scripts.scriptOrderList, ['C', 'A', 'hidden', 'B']);
      await dashboard.reorderVisibleScripts(['deleted', 'A'], 0, 1);
      await scripts.saveScriptOrder(['C', 'A']);
      expect(scripts.scriptOrderList, ['C', 'A', 'hidden', 'B']);
    },
  );

  Future<void> mountPanel(WidgetTester tester, double width) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: ConfigCollectionPanel(
              controller: dashboard,
              fillHeight: true,
              loadingAddScript: false,
              refreshingScripts: false,
              onAddScriptTap: () {},
              onRefreshScriptsTap: () {},
              onActivateScript: (name) async => dashboard.setActiveScript(name),
              onRenameScript: (_) async {},
              onExportScript: (_) async {},
              onDeleteScript: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'handle drag sorts visible rows without toggling power or changing selection',
    (tester) async {
      dashboard.stateFilter.value = HomeScriptStateFilter.stopped;
      await mountPanel(tester, 320);
      expect(find.byIcon(Icons.power_settings_new_rounded), findsNothing);
      expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(3));
      final first = find.byKey(const ValueKey('config-reorder-handle-A'));
      final last = find.byKey(const ValueKey('config-reorder-handle-C'));
      final target = tester.getBottomLeft(last) + const Offset(16, 80);
      final gesture = await tester.startGesture(tester.getCenter(first));
      await tester.pump();
      await gesture.moveTo(target);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(scripts.scriptOrderList, ['B', 'hidden', 'C', 'A']);
      expect(dashboard.activeScriptName.value, 'A');
      expect(
        scripts.findScriptModel('hidden')!.state.value,
        ScriptState.running,
      );
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      expect(dashboard.activeScriptName.value, 'B');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact linked rows keep handles and menus without overflow', (
    tester,
  ) async {
    dashboard.isLinkModeEnabled.value = true;
    await mountPanel(tester, 180);
    expect(find.byIcon(Icons.power_settings_new_rounded), findsNothing);
    expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(4));
    expect(find.byType(PopupMenuButton<String>), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}

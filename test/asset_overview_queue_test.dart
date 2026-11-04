import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/taskitem_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/websocket_service.dart';

class _Storage implements HomeDashboardStorage {
  @override
  dynamic read(String key) => null;
  @override
  void write(String key, dynamic value) {}
}

class _Args extends ArgsController {
  final actions = <String>[];
  String? nextRun;
  @override
  Future<bool> updateScriptTask(String config, String task, bool enable) async {
    actions.add('enable:$config:$task:$enable');
    return true;
  }

  @override
  Future<bool> updateScriptTaskNextRun(
    String config,
    String task,
    String nextRun,
  ) async {
    actions.add('queue:$config:$task');
    this.nextRun = nextRun;
    return true;
  }
}

class _Scripts extends ScriptService {
  @override
  // Skip network/storage bootstrap in this scheduler wiring test.
  // ignore: must_call_super
  Future<void> onInit() async {}
  @override
  Future<void> onClose() async {}
}

class _WebSockets extends WebSocketService {
  final sent = <String>[];
  @override
  Future<WebSocketClient> connect({
    required String name,
    String? url,
    MessageListener? listener,
    bool force = false,
  }) async => WebSocketClient(name: name, url: 'ws://test');
  @override
  Future<void> send(String name, String message) async {
    sent.add('$name:$message');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Args args;
  late _Scripts scripts;
  late HomeDashboardController dashboard;
  late _WebSockets sockets;
  late Directory storage;
  setUpAll(() async {
    storage = Directory.systemTemp.createTempSync('asset_queue_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => storage.path,
        );
    await GetStorage('GetStorage', storage.path).initStorage;
  });
  tearDownAll(() {
    // GetStorage retains an open Windows file handle until the test process exits.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });
  setUp(() {
    Get.testMode = true;
    sockets = Get.put<WebSocketService>(_WebSockets()) as _WebSockets;
    scripts = Get.put<ScriptService>(_Scripts()) as _Scripts;
    args = Get.put<ArgsController>(_Args()) as _Args;
    scripts.addScriptModel('test');
    scripts.addScriptModel('other');
    dashboard = HomeDashboardController(storage: _Storage());
    dashboard.isLinkModeEnabled.value = true;
    dashboard.linkedScriptList.assignAll(['test', 'other']);
  });
  tearDown(() {
    Get.reset();
  });

  test(
    'asset refresh uses normal overview scheduler only for current profile',
    () async {
      expect(await dashboard.enqueueAssetSnapshot('test'), isTrue);
      expect(args.actions, [
        'enable:test:AssetSnapshot:true',
        'queue:test:AssetSnapshot',
      ]);
      expect(DateTime.parse(args.nextRun!).isBefore(DateTime.now()), isTrue);
      expect(sockets.sent, ['test:start']);
    },
  );

  test(
    'an already running asset task is reused without requeuing or restarting',
    () async {
      final model = scripts.findScriptModel('test')!;
      model.state.value = ScriptState.running;
      model.runningTask.value = TaskItemModel('test', 'AssetSnapshot', 'now');
      expect(await dashboard.enqueueAssetSnapshot('test'), isTrue);
      expect(args.actions, isEmpty);
      expect(sockets.sent, isEmpty);
    },
  );
}

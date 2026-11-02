import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/models/asset_snapshot_model.dart';
import 'package:oasx/modules/home/models/asset_history_model.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/service/script_service.dart';

/// One state/polling owner for both asset surfaces of one backend/profile.
class HomeAssetController extends GetxController with WidgetsBindingObserver {
  HomeAssetController(
    this.scriptName,
    this.backend, {
    Future<AssetSnapshotModel> Function(String)? loadSnapshot,
    Future<AssetHistoryModel> Function(String, int, String)? loadHistory,
    Future<AssetCapture> Function(String)? submitCapture,
    Future<AssetCapture> Function(String)? loadCapture,
  }) : _loadSnapshot = loadSnapshot,
       _loadHistory = loadHistory,
       _submitCapture = submitCapture,
       _loadCapture = loadCapture;
  static final _pool = <String, HomeAssetController>{};
  static HomeAssetController acquire(String script, String backend) {
    final controller = _pool.putIfAbsent(
      '$backend\n$script',
      () => HomeAssetController(script, backend),
    );
    if (controller._references++ == 0) controller.start();
    return controller;
  }

  void release() {
    if (--_references > 0) return;
    _pool.remove('$backend\n$scriptName');
    disposeState();
  }

  final String scriptName, backend;
  final Future<AssetSnapshotModel> Function(String)? _loadSnapshot;
  final Future<AssetHistoryModel> Function(String, int, String)? _loadHistory;
  final Future<AssetCapture> Function(String)? _submitCapture;
  final Future<AssetCapture> Function(String)? _loadCapture;
  final revision = 0.obs;
  AssetSnapshotModel snapshot = const AssetSnapshotModel.unavailable();
  AssetHistoryModel? history;
  AssetCapture? capture;
  String selectedAsset = 'gold',
      compare = 'previous',
      error = '',
      historyError = '';
  bool loading = false,
      historyLoading = false,
      _foreground = true,
      _disposed = false;
  String refreshState = 'idle';
  String? _idempotencyKey;
  int? _queuedSnapshotId;
  DateTime? _queuedAt;
  bool _sawSchedulerRun = false;
  Timer? _timer, _successTimer;
  int _references = 0, _snapshotEpoch = 0, _historyEpoch = 0, _captureEpoch = 0;
  bool get busy =>
      ['submitting', 'queued', 'running', 'succeeded'].contains(refreshState);
  bool get _current =>
      !_disposed && (_loadSnapshot != null || ApiClient().address == backend);
  void start() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(reload());
    _schedule();
  }

  void _notify() {
    if (!_disposed) revision.value++;
  }

  void _schedule() {
    _timer?.cancel();
    if (_disposed || !_foreground) return;
    _timer = Timer(
      Duration(
        seconds: capture?.active == true
            ? 2
            : error.isEmpty
            ? 30
            : 60,
      ),
      () async {
        if (_current) {
          if (capture?.active == true) {
            await _pollCapture();
          } else {
            await reload();
          }
        }
        _schedule();
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      unawaited(capture?.active == true ? _pollCapture() : reload());
    }
    _schedule();
  }

  Future<void> reload() async {
    if (!_current) return;
    final epoch = ++_snapshotEpoch;
    loading = true;
    _notify();
    try {
      final result =
          await (_loadSnapshot?.call(compare) ??
              ApiClient().getAssetSnapshot(scriptName, compare: compare));
      if (!_current || epoch != _snapshotEpoch) return;
      final changed =
          snapshot.snapshotId != result.snapshotId ||
          snapshot.reportDate != result.reportDate ||
          snapshot.identityId != result.identityId;
      if (snapshot.identityId != result.identityId) {
        history = null;
        _historyEpoch++;
        if (snapshot.identityId != null) {
          _captureEpoch++;
          capture = null;
          _idempotencyKey = null;
          refreshState = 'idle';
        }
      }
      snapshot = result;
      error = '';
      if (_submitCapture != null && result.capture?.active == true) {
        capture = result.capture;
        refreshState = capture!.status;
      }
      if (['failed', 'interrupted'].contains(refreshState)) {
        error = capture?.message ?? error;
      }
      if (changed || history == null) unawaited(reloadHistory());
    } catch (e) {
      if (_current && epoch == _snapshotEpoch) error = e.toString();
    } finally {
      if (_current && epoch == _snapshotEpoch) {
        loading = false;
        _notify();
        _schedule();
      }
    }
  }

  void select(String asset) {
    selectedAsset = asset;
    history = null;
    _notify();
    unawaited(reloadHistory());
  }

  void setCompare(String value) {
    if (compare == value) return;
    compare = value;
    unawaited(reload());
  }

  Future<void> reloadHistory() async {
    final id = snapshot.snapshotId,
        date = snapshot.reportDate,
        asset = selectedAsset;
    if (!_current || id == null || date == null) return;
    final epoch = ++_historyEpoch;
    historyLoading = true;
    historyError = '';
    _notify();
    try {
      final result =
          await (_loadHistory?.call(asset, id, date) ??
              ApiClient().getAssetHistory(scriptName, asset, id, date));
      if (!_current || epoch != _historyEpoch || snapshot.snapshotId != id) {
        return;
      }
      history = result;
    } catch (e) {
      if (_current && epoch == _historyEpoch) historyError = e.toString();
    } finally {
      if (_current && epoch == _historyEpoch) {
        historyLoading = false;
        _notify();
      }
    }
  }

  Future<void> captureOnce() async {
    if (!_current || busy) return;
    refreshState = 'submitting';
    error = '';
    _notify();
    final epoch = _captureEpoch;
    _idempotencyKey ??=
        '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    try {
      final result =
          await (_submitCapture?.call(_idempotencyKey!) ??
              _enqueueInOverview());
      if (!_current || epoch != _captureEpoch) return;
      capture = result;
      await _applyCapture();
    } catch (e) {
      if (_current && epoch == _captureEpoch) {
        refreshState = 'failed';
        error = '$e（重试会核对同一次请求）';
      }
    }
    _notify();
    _schedule();
  }

  Future<void> _pollCapture() async {
    final id = capture?.requestId;
    if (!_current || id == null) return;
    final epoch = _captureEpoch;
    try {
      final result =
          await (_loadCapture?.call(id) ?? _schedulerCaptureStatus(id));
      if (!_current || epoch != _captureEpoch) return;
      capture = result;
      error = '';
      await _applyCapture();
    } catch (e) {
      if (_current) error = '采集状态查询失败，稍后继续核对：$e';
    }
    _notify();
  }

  Future<void> _applyCapture() async {
    refreshState = capture!.status;
    if (!capture!.active) _idempotencyKey = null;
    if (capture!.status == 'succeeded') {
      await reload();
      if (!_current) return;
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(milliseconds: 2500), () {
        refreshState = 'idle';
        _notify();
      });
    } else if (!capture!.active) {
      error = capture!.message ?? '采集已中断，请重试';
    }
  }

  Future<AssetCapture> _enqueueInOverview() async {
    final baseline = await ApiClient().getAssetSnapshot(
      scriptName,
      compare: compare,
    );
    if (!_current) throw Exception('服务端已切换，未提交采集任务');
    _queuedSnapshotId = baseline.snapshotId;
    _queuedAt = DateTime.now();
    _sawSchedulerRun = false;
    final queued = await Get.find<HomeDashboardController>()
        .enqueueAssetSnapshot(scriptName);
    if (!queued) throw Exception('资产快照任务加入总览队列失败');
    return AssetCapture(
      requestId: 'scheduler-${_queuedAt!.microsecondsSinceEpoch}',
      status: 'queued',
    );
  }

  Future<AssetCapture> _schedulerCaptureStatus(String requestId) async {
    final result = await ApiClient().getAssetSnapshot(
      scriptName,
      compare: compare,
    );
    if (!_current) {
      return AssetCapture(requestId: requestId, status: 'interrupted');
    }
    if (result.snapshotId != null && result.snapshotId != _queuedSnapshotId) {
      return AssetCapture(
        requestId: requestId,
        status: 'succeeded',
        snapshotId: result.snapshotId,
      );
    }
    final model = Get.find<ScriptService>().findScriptModel(scriptName);
    final running = model?.state.value == ScriptState.running;
    if (running && model?.runningTask.value.taskName.value == 'AssetSnapshot') {
      _sawSchedulerRun = true;
      return AssetCapture(requestId: requestId, status: 'running');
    }
    final queued =
        model?.pendingTaskList.any(
          (task) => task.taskName.value == 'AssetSnapshot',
        ) ??
        false;
    if ((_sawSchedulerRun && !queued) ||
        (!running && DateTime.now().difference(_queuedAt!).inSeconds > 10)) {
      return AssetCapture(
        requestId: requestId,
        status: 'failed',
        message: '资产采集未完成或调度已停止，请查看总览与日志',
      );
    }
    return AssetCapture(requestId: requestId, status: 'queued');
  }

  void disposeState() {
    _disposed = true;
    _snapshotEpoch++;
    _historyEpoch++;
    _timer?.cancel();
    _successTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

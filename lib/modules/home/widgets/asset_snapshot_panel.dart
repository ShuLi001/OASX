import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/controllers/asset_controller.dart';
import 'package:oasx/modules/home/models/asset_snapshot_catalog.dart';
import 'package:oasx/modules/home/models/asset_snapshot_model.dart';
import 'package:oasx/modules/home/widgets/asset_history_chart.dart';

class AssetSnapshotPanel extends StatefulWidget {
  const AssetSnapshotPanel({
    super.key,
    this.compact = false,
    this.scriptName,
    this.model,
    this.loadSnapshot,
    this.onRefresh,
    this.controller,
  });
  final bool compact;
  final String? scriptName;
  final AssetSnapshotModel? model;
  final Future<AssetSnapshotModel> Function(String)? loadSnapshot;
  final VoidCallback? onRefresh;
  final HomeAssetController? controller;
  @override
  State<AssetSnapshotPanel> createState() => _AssetSnapshotPanelState();
}

class _AssetSnapshotPanelState extends State<AssetSnapshotPanel> {
  HomeAssetController? _controller;
  final _scroll = ScrollController();
  final _trendKey = GlobalKey();
  final _viewportKey = GlobalKey();
  bool _expanded = false, _owned = false;
  String _selected = 'gold';
  AssetSnapshotModel _injected = const AssetSnapshotModel.unavailable();
  int _loadEpoch = 0;
  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    _expanded = false;
    if (_owned) _controller?.release();
    _owned = false;
    _controller = widget.controller;
    _loadEpoch++;
    _injected = widget.model ?? const AssetSnapshotModel.unavailable();
    if (_controller == null &&
        widget.model == null &&
        (widget.scriptName?.isNotEmpty ?? false)) {
      if (widget.loadSnapshot != null) {
        final epoch = _loadEpoch;
        widget.loadSnapshot!(widget.scriptName!).then((value) {
          if (mounted && epoch == _loadEpoch) setState(() => _injected = value);
        });
      } else {
        _owned = true;
        _controller = HomeAssetController.acquire(
          widget.scriptName!,
          ApiClient().address,
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant AssetSnapshotPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptName != widget.scriptName ||
        oldWidget.controller != widget.controller ||
        oldWidget.model != widget.model) {
      _bind();
    }
  }

  @override
  void dispose() {
    _loadEpoch++;
    if (_owned) _controller?.release();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return _surface(_injected);
    return Obx(() {
      _controller!.revision.value;
      if (_owned) {
        ApiClient().addressRevision.value;
        if (_controller!.backend != ApiClient().address) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(_bind);
          });
          return const Center(child: CircularProgressIndicator());
        }
      }
      return _surface(_controller!.snapshot);
    });
  }

  String get _asset => _controller?.selectedAsset ?? _selected;
  AssetSnapshotEntry get _entry => [
    ...AssetSnapshotCatalog.currencies,
    ...AssetSnapshotCatalog.resources,
  ].firstWhere((e) => e.variableName == _asset);
  void _select(String asset) {
    final closing = _expanded && _asset == asset;
    setState(() {
      _expanded = !closing;
      _selected = asset;
    });
    if (_controller != null) {
      if (!closing &&
          (_controller!.selectedAsset != asset ||
              _controller!.history == null)) {
        _controller!.select(asset);
      }
    }
    if (!closing) _revealTrendIfNeeded();
  }

  void _revealTrendIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_expanded || _trendKey.currentContext == null) return;
      final panel = _trendKey.currentContext!.findRenderObject();
      final viewport = _viewportKey.currentContext?.findRenderObject();
      if (panel is! RenderBox ||
          viewport is! RenderBox ||
          !panel.hasSize ||
          !viewport.hasSize) {
        return;
      }
      final bottom = panel.localToGlobal(Offset(0, panel.size.height)).dy;
      final viewportBottom = viewport
          .localToGlobal(Offset(0, viewport.size.height))
          .dy;
      if (bottom > viewportBottom) {
        unawaited(
          Scrollable.ensureVisible(
            _trendKey.currentContext!,
            alignment: panel.size.height > viewport.size.height ? 0 : .8,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    });
  }

  Widget _surface(AssetSnapshotModel model) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : 360.0;
      final effective = width - 20;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final columns = effective < 290 || scale > 1.3
          ? 1
          : effective < 600
          ? 2
          : ((effective + 8) / 178).floor().clamp(3, 4);
      return SingleChildScrollView(
        key: _viewportKey,
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(model),
            if (_controller?.error.isNotEmpty ?? false)
              _notice(_controller!.error),
            if (_controller?.loading == true)
              const LinearProgressIndicator(minHeight: 2),
            if (!model.isReady)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(model.message ?? '暂无资产快照，点击刷新资产执行一次采集。'),
              )
            else ...[
              const SizedBox(height: 12),
              _section(
                '货币',
                AssetSnapshotCatalog.currencies,
                model,
                columns,
                true,
              ),
              const SizedBox(height: 16),
              _section(
                '物品库·资源',
                AssetSnapshotCatalog.resources,
                model,
                columns,
                false,
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _header(AssetSnapshotModel model) {
    final state = _controller?.refreshState ?? 'idle';
    final busy = _controller?.busy ?? false;
    final label = switch (state) {
      'submitting' => '提交中…',
      'queued' => '排队中',
      'running' => '正在采集…',
      'succeeded' => '采集完成',
      'failed' || 'interrupted' => '重试采集',
      _ => '刷新资产',
    };
    final color = switch (state) {
      'queued' => Colors.orange,
      'succeeded' => const Color(0xFF0C9F70),
      'failed' || 'interrupted' => const Color(0xFFD95768),
      _ => Theme.of(context).colorScheme.primary,
    };
    final button = Tooltip(
      message: '刷新资产',
      child: OutlinedButton.icon(
        onPressed: busy || (_controller == null && widget.onRefresh == null)
            ? null
            : () {
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                } else {
                  unawaited(_controller!.captureOnce());
                }
              },
        icon: ['submitting', 'running'].contains(state)
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                state == 'succeeded'
                    ? Icons.check
                    : state == 'queued'
                    ? Icons.schedule
                    : Icons.refresh,
                size: 16,
                color: color,
              ),
        label: Text(label, style: TextStyle(fontSize: 12, color: color)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 34),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              const Text(
                '资产快照',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              button,
            ],
          ),
        ),
        if (model.formattedUpdatedAt.isNotEmpty)
          Text(
            '更新时间：${model.formattedUpdatedAt}',
            style: const TextStyle(fontSize: 11),
          ),
        if (model.assets.isNotEmpty)
          Text(
            '本次更新${[...AssetSnapshotCatalog.currencies, ...AssetSnapshotCatalog.resources].where((entry) => model.assets[entry.variableName]?.source == 'observed').length}项',
            style: const TextStyle(fontSize: 10),
          ),
        const SizedBox(height: 4),
        Text(switch (state) {
          'queued' => '已加入总览任务队列，将按调度顺序采集',
          'running' => '正在游戏中采集，请勿手动干预模拟器',
          _ => '刷新将进入游戏采集一次，约需一分钟',
        }, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _notice(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context).colorScheme.error,
      ),
    ),
  );

  Widget _section(
    String title,
    List<AssetSnapshotEntry> entries,
    AssetSnapshotModel model,
    int columns,
    bool currency,
  ) {
    final group = currency ? 'currencies' : 'resources';
    final rows = <Widget>[];
    for (var start = 0; start < entries.length; start += columns) {
      final end = (start + columns).clamp(0, entries.length);
      final rowEntries = entries.sublist(start, end);
      final active =
          _expanded && rowEntries.any((entry) => entry.variableName == _asset);
      rows.add(
        IntrinsicHeight(
          key: ValueKey('asset-$group-row-${start ~/ columns}'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var column = 0; column < columns; column++) ...[
                if (column > 0) const SizedBox(width: 8),
                Expanded(
                  child: column >= rowEntries.length
                      ? const SizedBox.shrink()
                      : _card(rowEntries[column], model, currency),
                ),
              ],
            ],
          ),
        ),
      );
      if (active) {
        rows.add(const SizedBox(height: 6));
        rows.add(_trend());
        if (end < entries.length) rows.add(const SizedBox(height: 10));
      } else if (end < entries.length) {
        rows.add(const SizedBox(height: 6));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Column(
          key: ValueKey(
            'asset-snapshot-$group-${columns == 1 ? 'one' : 'two'}-column',
          ),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ],
    );
  }

  Widget _card(
    AssetSnapshotEntry entry,
    AssetSnapshotModel model,
    bool currency,
  ) {
    final selected = _expanded && _asset == entry.variableName;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: double.infinity,
          key: ValueKey('asset-card-${entry.variableName}'),
          child: _AssetCard(
            entry: entry,
            observation: model.assets[entry.variableName],
            quantity: model.quantity(entry.variableName),
            selected: selected,
            currency: currency,
            compact: widget.compact,
            onTap: () => _select(entry.variableName),
          ),
        ),
        if (selected)
          Positioned(
            bottom: -10,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _trend() {
    final history = _controller?.history;
    final loading = _controller?.historyLoading ?? false;
    final error = _controller?.historyError ?? '';
    final hasRecords = history != null && history.records.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: _trendKey,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        key: const ValueKey('asset-inline-trend'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '七日变化量 · ${_entry.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: '收起趋势',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(6),
                iconSize: 16,
                onPressed: () => setState(() => _expanded = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (history != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${history.window['startDate']} — ${history.window['endDate']}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (error.isNotEmpty)
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: scheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: scheme.error),
                  ),
                ),
                TextButton(
                  onPressed: () => _controller?.reloadHistory(),
                  child: const Text('重试', style: TextStyle(fontSize: 11)),
                ),
              ],
            )
          else if (hasRecords)
            AssetHistoryChart(model: history)
          else if (loading)
            SizedBox(
              height: 180,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < 3; i++)
                    Divider(
                      color: scheme.outlineVariant.withValues(alpha: .35),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_chart_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '近7天暂无查询记录，更新后将自动积累',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.entry,
    required this.quantity,
    required this.observation,
    required this.selected,
    required this.currency,
    required this.compact,
    required this.onTap,
  });
  final AssetSnapshotEntry entry;
  final int quantity;
  final AssetObservation? observation;
  final bool selected, currency, compact;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = observation;
    final amount = item?.quantity ?? quantity;
    final quantityText = entry.variableName == 'jade'
        ? amount.toString()
        : formatAssetNumber(amount);
    final delta = item?.delta;
    final color = delta == null || delta == 0
        ? scheme.onSurfaceVariant
        : delta > 0
        ? const Color(0xFF0C9F70)
        : const Color(0xFFD95768);
    final iconSize = currency
        ? (compact ? 34.0 : 38.0)
        : (compact ? 32.0 : 36.0);
    return Tooltip(
      message: '${entry.name}\n当前库存：${item?.quantity ?? quantity}\n点击展开近七日数据',
      child: Material(
        color: selected
            ? scheme.surfaceContainerHighest
            : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(currency ? 10 : 8),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: currency ? (compact ? 58 : 62) : (compact ? 50 : 54),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: Row(
                children: [
                  Image.asset(
                    entry.iconAsset,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        Icon(Icons.inventory_2_outlined, size: iconSize),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              quantityText,
                              style: TextStyle(
                                fontSize: currency ? 14 : 13,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            if (item?.hasVisibleChange == true)
                              Text(
                                formatAssetDelta(delta),
                                style: TextStyle(
                                  fontSize: currency ? 12 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

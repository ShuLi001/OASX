import 'package:flutter/material.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/home/models/asset_snapshot_catalog.dart';
import 'package:oasx/modules/home/models/asset_snapshot_model.dart';

class AssetSnapshotPanel extends StatefulWidget {
  const AssetSnapshotPanel({
    super.key,
    this.compact = false,
    this.scriptName,
    this.model,
    this.loadSnapshot,
    this.onRefresh,
  });

  final bool compact;
  final String? scriptName;
  final AssetSnapshotModel? model;
  final Future<AssetSnapshotModel> Function(String scriptName)? loadSnapshot;
  final VoidCallback? onRefresh;

  @override
  State<AssetSnapshotPanel> createState() => _AssetSnapshotPanelState();
}

class _AssetSnapshotPanelState extends State<AssetSnapshotPanel> {
  AssetSnapshotModel _model = const AssetSnapshotModel.unavailable();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _model = widget.model ?? const AssetSnapshotModel.unavailable();
    if (widget.model == null && _scriptName.isNotEmpty) _load();
  }

  @override
  void didUpdateWidget(covariant AssetSnapshotPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != null) {
      _model = widget.model!;
    } else if (oldWidget.scriptName != widget.scriptName &&
        _scriptName.isNotEmpty) {
      _load();
    }
  }

  String get _scriptName => widget.scriptName?.trim() ?? '';

  Future<void> _load() async {
    if (_scriptName.isEmpty || _loading) return;
    setState(() => _loading = true);
    AssetSnapshotModel model;
    try {
      model =
          await (widget.loadSnapshot?.call(_scriptName) ??
              ApiClient().getAssetSnapshot(_scriptName));
    } catch (error) {
      model = AssetSnapshotModel(
        status: AssetSnapshotStatus.error,
        message: error.toString(),
      );
    }
    if (!mounted) return;
    setState(() {
      _model = model;
      _loading = false;
    });
  }

  void _refresh() {
    widget.onRefresh?.call();
    if (widget.onRefresh == null) _load();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 360.0;
        final twoColumns = width >= 290;
        final padding = widget.compact
            ? const EdgeInsets.fromLTRB(4, 4, 4, 12)
            : const EdgeInsets.fromLTRB(8, 4, 8, 16);
        final model = _loading
            ? const AssetSnapshotModel(status: AssetSnapshotStatus.loading)
            : _model;
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SnapshotHeader(
                compact: widget.compact,
                model: model,
                onRefresh: _refresh,
              ),
              const SizedBox(height: 12),
              if (model.status == AssetSnapshotStatus.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!model.isReady)
                _UnavailableState(model: model)
              else ...[
                if (model.formattedUpdatedAt.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('更新时间：${model.formattedUpdatedAt}'),
                  ),
                _AssetSection(
                  key: ValueKey(
                    twoColumns
                        ? 'asset-snapshot-currencies-two-column'
                        : 'asset-snapshot-currencies-one-column',
                  ),
                  title: '货币',
                  entries: AssetSnapshotCatalog.currencies,
                  model: model,
                  compact: widget.compact,
                  twoColumns: twoColumns,
                  cardType: _AssetCardType.currency,
                ),
                const SizedBox(height: 16),
                _AssetSection(
                  key: ValueKey(
                    twoColumns
                        ? 'asset-snapshot-resources-two-column'
                        : 'asset-snapshot-resources-one-column',
                  ),
                  title: '物品库·资源',
                  entries: AssetSnapshotCatalog.resources,
                  model: model,
                  compact: widget.compact,
                  twoColumns: twoColumns,
                  cardType: _AssetCardType.resource,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SnapshotHeader extends StatelessWidget {
  const _SnapshotHeader({
    required this.compact,
    required this.model,
    required this.onRefresh,
  });
  final bool compact;
  final AssetSnapshotModel model;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (model.status) {
      AssetSnapshotStatus.ready => 'OAS 资产快照',
      AssetSnapshotStatus.loading => '正在读取资产快照',
      AssetSnapshotStatus.error => '资产快照读取失败',
      AssetSnapshotStatus.unavailable => '暂无资产快照',
    };
    final refresh = model.status == AssetSnapshotStatus.loading
        ? null
        : onRefresh;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '资产快照',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Tooltip(
          message: '刷新资产',
          child: compact
              ? IconButton(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                )
              : OutlinedButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('刷新资产'),
                ),
        ),
      ],
    );
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.model});
  final AssetSnapshotModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(model.message ?? '暂无资产快照数据'),
    );
  }
}

enum _AssetCardType { currency, resource }

class _AssetSection extends StatelessWidget {
  const _AssetSection({
    super.key,
    required this.title,
    required this.entries,
    required this.model,
    required this.compact,
    required this.twoColumns,
    required this.cardType,
  });
  final String title;
  final List<AssetSnapshotEntry> entries;
  final AssetSnapshotModel model;
  final bool compact;
  final bool twoColumns;
  final _AssetCardType cardType;

  @override
  Widget build(BuildContext context) {
    final cardHeight = cardType == _AssetCardType.currency
        ? (compact ? 58.0 : 60.0)
        : (compact ? 48.0 : 52.0);
    final iconSize = cardType == _AssetCardType.currency
        ? (compact ? 36.0 : 40.0)
        : (compact ? 34.0 : 36.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: twoColumns ? 2 : 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: compact ? 6 : 8,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) => _AssetCard(
            entry: entries[index],
            quantity: model.quantity(entries[index].variableName),
            height: cardHeight,
            iconSize: iconSize,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.entry,
    required this.quantity,
    required this.height,
    required this.iconSize,
    required this.compact,
  });
  final AssetSnapshotEntry entry;
  final int quantity;
  final double height;
  final double iconSize;
  final bool compact;

  String get _quantityText {
    final useWan =
        entry.variableName == 'gold' ||
        (entry.variableName == 'jade' && quantity > 10000);
    if (!useWan) {
      return quantity.toString();
    }
    final amount = (quantity / 10000).toStringAsFixed(2);
    return '${amount.replaceFirst(RegExp(r'\.?0+$'), '')}万';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: 5,
          ),
          child: Row(
            children: [
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    entry.iconAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_not_supported_outlined,
                      size: iconSize * 0.62,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _quantityText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

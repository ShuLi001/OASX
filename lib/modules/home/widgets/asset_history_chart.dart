import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:oasx/modules/home/models/asset_history_model.dart';
import 'package:oasx/modules/home/models/asset_snapshot_model.dart';

class AssetHistoryChart extends StatefulWidget {
  const AssetHistoryChart({super.key, required this.model, this.wide = false});
  final AssetHistoryModel model;
  final bool wide;
  @override
  State<AssetHistoryChart> createState() => _AssetHistoryChartState();
}

class _AssetHistoryChartState extends State<AssetHistoryChart> {
  bool _changes = false;
  Map<String, dynamic>? _selection;

  @override
  void didUpdateWidget(covariant AssetHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) _selection = null;
  }

  void _select(Map<String, dynamic>? row) {
    if (identical(row, _selection)) return;
    setState(() => _selection = row);
  }

  void _setMode(bool changes) {
    if (_changes == changes) return;
    setState(() {
      _changes = changes;
      _selection = null;
    });
  }

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = _selection;
    final value = row?[_changes ? 'delta' : 'quantity'] as num?;
    final color = !_changes || value == null || value == 0
        ? scheme.onSurface
        : value > 0
        ? const Color(0xFF0C9F70)
        : const Color(0xFFD95768);
    final modes = Wrap(
      spacing: 6,
      children: [
        ChoiceChip(
          showCheckmark: false,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          labelStyle: const TextStyle(fontSize: 11),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          padding: EdgeInsets.zero,
          label: const Text('趋势'),
          selected: !_changes,
          onSelected: (_) => _setMode(false),
        ),
        ChoiceChip(
          showCheckmark: false,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          labelStyle: const TextStyle(fontSize: 11),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          padding: EdgeInsets.zero,
          label: const Text('变化'),
          selected: _changes,
          onSelected: (_) => _setMode(true),
        ),
      ],
    );
    final readout = SizedBox(
      key: const ValueKey('asset-chart-readout'),
      width: 130,
      height: 36,
      child: row == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatAssetQueryTime(row['queriedAt']),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      text:
                          '${_changes && value != null && value > 0 ? '+' : ''}${value ?? ''}',
                      children: [
                        if (!_changes && row['observed'] != true)
                          TextSpan(
                            text: '（上次数据）',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: scheme.outline,
                            ),
                          ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: modes),
            const SizedBox(width: 8),
            SizedBox(
              width: math.min(130, constraints.maxWidth * .5),
              child: readout,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.model.records;
    final scheme = Theme.of(context).colorScheme;
    final values = rows
        .map((row) => row[_changes ? 'delta' : 'quantity'] as num?)
        .toList();
    final existing = values.whereType<num>().map((v) => v.toDouble()).toList();
    final start =
        DateTime.tryParse(
          '${widget.model.window['startDate']}T00:00:00+08:00',
        ) ??
        DateTime.utc(2000);
    final end =
        DateTime.tryParse('${widget.model.window['endDate']}T00:00:00+08:00') ??
        start.add(const Duration(days: 6));
    final hours = (end.difference(start).inDays + 1) * 24.0;
    double x(Map<String, dynamic> row) =>
        (DateTime.tryParse(row['queriedAt']?.toString() ?? '') ?? start)
            .difference(start)
            .inMilliseconds /
        Duration.millisecondsPerHour;
    final plotted = rows.where((row) => row['quantity'] is num).toList();
    var min = existing.isEmpty ? 0.0 : existing.reduce(math.min);
    var max = existing.isEmpty ? 1.0 : existing.reduce(math.max);
    if (_changes) {
      min = math.min(0, min);
      max = math.max(0, max);
    }
    final padding = math.max(1.0, (max - min) * .15);
    min = _changes || min < 0 ? min - padding : math.max(0, min - padding);
    max += padding;
    final labelStep = math.max(1, (rows.length / 4).ceil());
    final titles = FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 42,
          getTitlesWidget: (value, meta) => Text(
            formatAssetNumber(value.toInt()),
            style: const TextStyle(fontSize: 9),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          interval: _changes ? 1 : 24,
          getTitlesWidget: (value, meta) {
            String label;
            if (_changes) {
              final index = value.toInt();
              if (value != index ||
                  index < 0 ||
                  index >= rows.length ||
                  (index % labelStep != 0 && index != rows.length - 1)) {
                return const SizedBox.shrink();
              }
              final time = formatAssetQueryTime(rows[index]['queriedAt']);
              label = time.length >= 11
                  ? '${time.substring(0, 5)}\n${time.substring(6, 11)}'
                  : time;
            } else {
              if (value < 0 || value >= hours || value % 24 != 0) {
                return const SizedBox.shrink();
              }
              final time = start.add(Duration(hours: value.toInt()));
              label = formatAssetQueryTime(
                time.toIso8601String(),
              ).substring(0, 5);
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9),
              ),
            );
          },
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: existing.isEmpty
              ? Center(
                  child: Text(
                    rows.isEmpty ? '近7天暂无查询记录' : '暂无可绘制数值，全部查询保留在明细中',
                  ),
                )
              : _changes
              ? BarChart(
                  BarChartData(
                    minY: min,
                    maxY: max,
                    titlesData: titles,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(drawVerticalLine: false),
                    barTouchData: BarTouchData(
                      touchCallback: (event, response) {
                        final index = response?.spot?.touchedBarGroupIndex;
                        _select(
                          event.isInterestedForInteractions && index != null
                              ? rows[index]
                              : null,
                        );
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (_, _, _, _) => null,
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < values.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            if (values[i] != null)
                              BarChartRodData(
                                toY: values[i]!.toDouble(),
                                width: 10,
                                color: values[i]! > 0
                                    ? const Color(0xFF0C9F70)
                                    : values[i]! < 0
                                    ? const Color(0xFFD95768)
                                    : scheme.outline,
                                borderRadius: BorderRadius.circular(3),
                              ),
                          ],
                        ),
                    ],
                  ),
                )
              : LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: hours,
                    minY: min,
                    maxY: max,
                    titlesData: titles,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(drawVerticalLine: false),
                    lineTouchData: LineTouchData(
                      touchCallback: (event, response) {
                        final spots = response?.lineBarSpots;
                        _select(
                          event.isInterestedForInteractions &&
                                  spots != null &&
                                  spots.isNotEmpty
                              ? plotted[spots.first.spotIndex]
                              : null,
                        );
                      },
                      getTouchedSpotIndicator: (bar, indices) => [
                        for (final _ in indices)
                          TouchedSpotIndicatorData(
                            const FlLine(
                              color: Colors.transparent,
                              strokeWidth: 0,
                            ),
                            FlDotData(
                              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                                radius: 5,
                                color: scheme.primary,
                                strokeWidth: 2,
                                strokeColor: scheme.surface,
                              ),
                            ),
                          ),
                      ],
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) =>
                            spots.map((_) => null).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: false,
                        color: scheme.primary,
                        barWidth: 2,
                        spots: [
                          for (final row in plotted)
                            FlSpot(x(row), (row['quantity'] as num).toDouble()),
                        ],
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 3,
                                color: plotted[index]['observed'] == true
                                    ? scheme.primary
                                    : scheme.outline,
                                strokeWidth: 0,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

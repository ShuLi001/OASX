import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/modules/home/widgets/asset_snapshot_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Hosts the desktop right sidebar for logs, stats, assets and the guide.
class WorkbenchSidebarPanel extends StatelessWidget {
  /// Creates the right workbench sidebar.
  const WorkbenchSidebarPanel({
    super.key,
    required this.controller,
    required this.scriptName,
    this.expanded = false,
    this.onToggleExpansion,
  });

  /// Dashboard controller that owns sidebar tab state.
  final HomeDashboardController controller;

  /// Active script rendered by the sidebar.
  final String scriptName;

  final bool expanded;
  final VoidCallback? onToggleExpansion;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          final tabs = controller.workbenchSidebarTabsFor(
            HomeWorkbenchLayoutMode.threePane,
          );
          final currentTab = controller.displayedWorkbenchSidebarTabFor(
            HomeWorkbenchLayoutMode.threePane,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tabs
                          .map(
                            (tab) => ChoiceChip(
                              label: Text(_tabLabel(tab)),
                              showCheckmark: false,
                              selected: currentTab == tab,
                              onSelected: (_) => controller
                                  .setActiveWorkbenchSidebarTabValue(tab),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (onToggleExpansion != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      key: const ValueKey(
                        'home-workbench-toggle-sidebar-expansion',
                      ),
                      tooltip: expanded ? '收起并恢复布局' : '展开右侧栏',
                      onPressed: onToggleExpansion,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: expanded
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        backgroundColor: expanded
                            ? Theme.of(context).colorScheme.secondaryContainer
                                  .withValues(alpha: .4)
                            : Colors.transparent,
                        hoverColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: Icon(
                        expanded
                            ? Icons.close_fullscreen_rounded
                            : Icons.open_in_full_rounded,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: switch (currentTab) {
                  HomeWorkbenchTab.stats => const ScriptStatisticsPanel(),
                  HomeWorkbenchTab.logs => LogCenterPanel(
                    scriptName: scriptName,
                  ),
                  HomeWorkbenchTab.assets => AssetSnapshotPanel(
                    compact: true,
                    scriptName: scriptName,
                  ),
                  HomeWorkbenchTab.guide => const _GuidePanel(),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Resolves a localized label for one sidebar tab.
  String _tabLabel(HomeWorkbenchTab value) {
    return switch (value) {
      HomeWorkbenchTab.stats => I18n.homeStatsTab.tr,
      HomeWorkbenchTab.logs => I18n.log.tr,
      HomeWorkbenchTab.assets => '资产',
      HomeWorkbenchTab.guide => '指引',
      _ => '',
    };
  }
}

class _GuidePanel extends StatelessWidget {
  const _GuidePanel();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      children: [
        Text('使用指引', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 14),
        _GuideItem(
          icon: Icons.play_circle_outline_rounded,
          title: '启动脚本',
          body: '点击顶部启动按钮连接 OAS 服务，运行状态会通过实时连接更新。',
          style: style,
        ),
        _GuideItem(
          icon: Icons.flash_on_rounded,
          title: '立即排队',
          body: '闪电按钮会把任务排到优先队列，不会强制打断正在执行的任务。',
          style: style,
        ),
        _GuideItem(
          icon: Icons.tune_rounded,
          title: '任务参数',
          body: '点击任务卡片右侧的设置按钮，编辑参数并保存到当前配置。',
          style: style,
        ),
      ],
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.style,
  });

  final IconData icon;
  final String title;
  final String body;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: style?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: style?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

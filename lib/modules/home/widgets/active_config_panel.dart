import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/home/models/home_task_card_metrics.dart';
import 'package:oasx/modules/home/widgets/asset_snapshot_panel.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/modules/home/widgets/task_catalog_panel.dart';
import 'package:oasx/modules/home/widgets/task_status_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

class ActiveConfigPanel extends StatelessWidget {
  const ActiveConfigPanel({
    super.key,
    required this.controller,
    required this.layoutMode,
    required this.onChangeTab,
    required this.onOpenTask,
    required this.onTogglePower,
    required this.onRenameScript,
    required this.onDeleteScript,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onBulkQuickRun,
    required this.onBulkQuickWait,
    this.onExpandRightSidebar,
    this.onBackToScripts,
  });

  final HomeDashboardController controller;
  final HomeWorkbenchLayoutMode layoutMode;
  final Future<void> Function(HomeWorkbenchTab tab) onChangeTab;
  final Future<void> Function(
    String taskName,
    HomeTaskParameterEntrySource source,
  )
  onOpenTask;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;
  final Future<void> Function(String scriptName) onRenameScript;
  final Future<void> Function(String scriptName) onDeleteScript;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function() onBulkQuickRun;
  final Future<void> Function() onBulkQuickWait;
  final VoidCallback? onExpandRightSidebar;
  final VoidCallback? onBackToScripts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Obx(() {
          final script = controller.activeScriptModel;
          final currentTab = controller.displayedWorkbenchTabFor(layoutMode);
          final tabs = controller.workbenchTabsFor(layoutMode);
          if (script == null) {
            return Center(child: Text(I18n.homeNoScriptSelected.tr));
          }
          final isRunning = script.state.value == ScriptState.running;
          final runningTaskName = script.runningTask.value.taskName.value
              .trim();
          final stateSubtitle = isRunning
              ? '运行中 · 当前任务：${runningTaskName.isEmpty ? '调度中' : runningTaskName.tr}'
              : '已停止 · 调度已暂停';
          final bulkMode = controller.bulkQuickScheduleMode.value;
          final hasBulkTasks = controller
              .quickSchedulableTaskNamesFor(script)
              .isNotEmpty;
          final isBulkIdle = bulkMode == HomeBulkQuickScheduleMode.none;
          return LayoutBuilder(
            builder: (context, viewport) {
              final panel = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact =
                          constraints.maxWidth <
                          600 *
                              (MediaQuery.textScalerOf(context).scale(14) / 14);
                      final identity = Row(
                        children: [
                          if (onBackToScripts != null)
                            IconButton(
                              tooltip: I18n.scriptList.tr,
                              onPressed: onBackToScripts,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  script.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stateSubtitle,
                                  maxLines: compact ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: isRunning
                                            ? const Color(0xff0c9f70)
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                      final actions = [
                        _BulkQuickScheduleButton(
                          icon: Icons.flash_on_rounded,
                          tooltip: I18n.homeQuickRunAll.tr,
                          loading: bulkMode == HomeBulkQuickScheduleMode.runNow,
                          onPressed: isBulkIdle && hasBulkTasks
                              ? onBulkQuickRun
                              : null,
                        ),
                        _BulkQuickScheduleButton(
                          icon: Icons.schedule_rounded,
                          tooltip: I18n.homeQuickWaitAll.tr,
                          loading:
                              bulkMode == HomeBulkQuickScheduleMode.waitNow,
                          onPressed: isBulkIdle && hasBulkTasks
                              ? onBulkQuickWait
                              : null,
                        ),
                        const SizedBox(width: 8),
                        _PowerActionButton(
                          label: I18n.run.tr,
                          icon: Icons.play_arrow_rounded,
                          active: !isRunning,
                          color: const Color(0xff0c9f70),
                          onPressed: !isRunning
                              ? () => onTogglePower(script.name, true)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        _PowerActionButton(
                          label: I18n.stop.tr,
                          icon: Icons.stop_rounded,
                          active: isRunning,
                          color: const Color(0xffd95768),
                          onPressed: isRunning
                              ? () => onTogglePower(script.name, false)
                              : null,
                        ),
                        if (onExpandRightSidebar != null)
                          const SizedBox(width: 8),
                        if (onExpandRightSidebar != null)
                          IconButton.filledTonal(
                            key: const ValueKey<String>(
                              'home-workbench-expand-right-sidebar',
                            ),
                            tooltip: I18n.homeRestoreSidebar.tr,
                            onPressed: onExpandRightSidebar,
                            icon: const Icon(
                              Icons.keyboard_double_arrow_left_rounded,
                            ),
                          ),
                      ];
                      if (compact) {
                        return Column(
                          key: const ValueKey('home-compact-header'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            identity,
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 4,
                              children: actions,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: identity),
                          ...actions,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _WorkbenchTabs(
                    tabs: tabs,
                    selected: currentTab,
                    label: _tabLabel,
                    onSelected: onChangeTab,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildTabContent(script, currentTab)),
                ],
              );
              // Let the header scroll away in landscape or above the soft keyboard.
              // The inner task list still receives a finite, usable viewport.
              final minimumHeight =
                  320 + MediaQuery.textScalerOf(context).scale(120);
              if (viewport.maxHeight >= minimumHeight) return panel;
              return SingleChildScrollView(
                key: const ValueKey('home-short-viewport'),
                child: SizedBox(height: minimumHeight, child: panel),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(ScriptModel script, HomeWorkbenchTab currentTab) {
    return switch (currentTab) {
      HomeWorkbenchTab.status => TaskStatusPanel(
        controller: controller,
        scriptModel: script,
        canQuickScheduleTask: (taskName) =>
            controller.canQuickScheduleTask(script, taskName),
        onSetNextRun: onSetNextRun,
        onQuickRun: onQuickRun,
        onQuickWait: onQuickWait,
        onEditTask: (taskName) =>
            onOpenTask(taskName, HomeTaskParameterEntrySource.overview),
      ),
      HomeWorkbenchTab.tasks => TaskCatalogPanel(
        controller: controller,
        scriptModel: script,
        onOpenTask: (taskName) =>
            onOpenTask(taskName, HomeTaskParameterEntrySource.tasks),
        onQuickRun: onQuickRun,
        onQuickWait: onQuickWait,
      ),
      HomeWorkbenchTab.stats => const ScriptStatisticsPanel(),
      HomeWorkbenchTab.logs => LogCenterPanel(scriptName: script.name),
      HomeWorkbenchTab.assets => AssetSnapshotPanel(scriptName: script.name),
      HomeWorkbenchTab.guide => const _GuideInlinePanel(),
    };
  }

  String _tabLabel(HomeWorkbenchTab value) {
    return switch (value) {
      HomeWorkbenchTab.status => I18n.overview.tr,
      HomeWorkbenchTab.tasks => I18n.homeTasksTab.tr,
      HomeWorkbenchTab.stats => I18n.homeStatsTab.tr,
      HomeWorkbenchTab.logs => I18n.log.tr,
      HomeWorkbenchTab.assets => '资产',
      HomeWorkbenchTab.guide => '指引',
    };
  }
}

/// Keeps every tab reachable without consuming a second row on phones.
class _WorkbenchTabs extends StatefulWidget {
  const _WorkbenchTabs({
    required this.tabs,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<HomeWorkbenchTab> tabs;
  final HomeWorkbenchTab selected;
  final String Function(HomeWorkbenchTab) label;
  final ValueChanged<HomeWorkbenchTab> onSelected;

  @override
  State<_WorkbenchTabs> createState() => _WorkbenchTabsState();
}

class _WorkbenchTabsState extends State<_WorkbenchTabs> {
  final _keys = {for (final tab in HomeWorkbenchTab.values) tab: GlobalKey()};

  @override
  void initState() {
    super.initState();
    _revealSelection();
  }

  @override
  void didUpdateWidget(covariant _WorkbenchTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _revealSelection();
  }

  void _revealSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedContext = _keys[widget.selected]?.currentContext;
      if (selectedContext != null) {
        Scrollable.ensureVisible(selectedContext, alignment: 0.5);
      }
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth <
          600 * (MediaQuery.textScalerOf(context).scale(14) / 14);
      final chips = widget.tabs
          .map(
            (tab) => Padding(
              key: _keys[tab],
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(widget.label(tab)),
                materialTapTargetSize: compact
                    ? MaterialTapTargetSize.padded
                    : null,
                showCheckmark: false,
                selected: widget.selected == tab,
                onSelected: (_) => widget.onSelected(tab),
              ),
            ),
          )
          .toList();
      return compact
          ? SingleChildScrollView(
              key: const ValueKey('home-scrollable-tabs'),
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            )
          : Wrap(runSpacing: 8, children: chips);
    },
  );
}

class _GuideInlinePanel extends StatelessWidget {
  const _GuideInlinePanel();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('指引内容将在后续版本继续补充。'));
  }
}

class _BulkQuickScheduleButton extends StatelessWidget {
  const _BulkQuickScheduleButton({
    required this.icon,
    required this.tooltip,
    required this.loading,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: loading ? null : onPressed,
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Icon(icon),
    );
  }
}

class _PowerActionButton extends StatelessWidget {
  const _PowerActionButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? color : Theme.of(context).colorScheme.outline,
        side: BorderSide(
          color: active
              ? color.withValues(alpha: 0.42)
              : Theme.of(context).colorScheme.outlineVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        minimumSize: Size(0, homeUsesTouchTargets(context) ? 48 : 38),
      ),
    );
  }
}

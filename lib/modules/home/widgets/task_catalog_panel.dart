import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/common/models/config_drag_payload.dart';
import 'package:oasx/modules/common/widgets/drag_copy_feedback.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/home_task_card_metrics.dart';
import 'package:oasx/modules/home/widgets/task_parameter_panel.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/time_utils.dart';

class TaskCatalogPanel extends StatefulWidget {
  const TaskCatalogPanel({
    super.key,
    required this.controller,
    required this.scriptModel,
    required this.onOpenTask,
    required this.onQuickRun,
    required this.onQuickWait,
  });

  final HomeDashboardController controller;
  final ScriptModel scriptModel;
  final Future<void> Function(String taskName) onOpenTask;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;

  @override
  State<TaskCatalogPanel> createState() => _TaskCatalogPanelState();
}

class _TaskCatalogPanelState extends State<TaskCatalogPanel> {
  late final Future<Map<String, List<String>>> _menuFuture;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _enabledOverrides = <String, bool>{};
  final Set<String> _togglingTasks = <String>{};
  String _searchQuery = '';
  HomeTaskCatalogFilter _filter = HomeTaskCatalogFilter.all;

  @override
  void initState() {
    super.initState();
    _menuFuture = ApiClient().getScriptMenu();
  }

  @override
  void didUpdateWidget(covariant TaskCatalogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptModel.name == widget.scriptModel.name) {
      return;
    }
    _enabledOverrides.clear();
    _scrollTaskListToTop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeTask = widget.controller.activeTaskName.value.trim();
      final dragPayload = widget.controller.activeDragPayload.value;
      final quickScheduleLocked = widget.controller.isBulkQuickScheduling;
      return IndexedStack(
        index: activeTask.isEmpty ? 0 : 1,
        children: [
          _buildTaskList(context, dragPayload, quickScheduleLocked),
          TaskParameterPanel(
            controller: widget.controller,
            scriptModel: widget.scriptModel,
            onBack: _handleBackFromParameters,
          ),
        ],
      );
    });
  }

  Widget _buildTaskList(
    BuildContext context,
    ConfigDragPayload? dragPayload,
    bool quickScheduleLocked,
  ) {
    return Column(
      children: [
        _buildToolbar(),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '点击任务卡片可编辑参数；⚡立即排队，开关控制是否加入调度器。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: FutureBuilder<Map<String, List<String>>>(
            future: _menuFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('${I18n.error.tr}: ${snapshot.error}'),
                );
              }
              final enabledTaskNames = widget.controller.enabledTaskNamesFor(
                widget.scriptModel,
              );
              final nextRunByTask = _nextRunByTask();
              _syncEnabledOverrides(enabledTaskNames);
              final sections = _sections(
                snapshot.data ?? const <String, List<String>>{},
                enabledTaskNames,
              );
              if (sections.isEmpty) {
                return Center(child: Text(I18n.taskNotFound.tr));
              }
              return ListView.separated(
                key: const PageStorageKey<String>('home-task-catalog-list'),
                controller: _scrollController,
                itemCount: sections.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: kHomeTaskGroupGap),
                itemBuilder: (context, index) => _CatalogSectionCard(
                  controller: widget.controller,
                  sourceScriptName: widget.scriptModel.name,
                  nextRunByTask: nextRunByTask,
                  section: sections[index],
                  togglingTasks: _togglingTasks,
                  onToggleEnabled: (task, value) =>
                      _handleToggleTaskEnabled(task, value),
                  onOpenTask: widget.onOpenTask,
                  onQuickRun: widget.onQuickRun,
                  onQuickWait: widget.onQuickWait,
                  canQuickScheduleTask: (taskName) => widget.controller
                      .canQuickScheduleTask(widget.scriptModel, taskName),
                  quickScheduleLocked: quickScheduleLocked,
                  dragEnabled: widget.controller.canUseDesktopDragCopy,
                  activeDragPayload: dragPayload,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final searchField = TextField(
      controller: _searchController,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: I18n.taskSearchHint.tr,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => setState(() {
        _searchQuery = value.trim().toLowerCase();
      }),
    );
    return Row(
      children: [
        Expanded(child: searchField),
        const SizedBox(width: 10),
        PopupMenuButton<HomeTaskCatalogFilter>(
          tooltip: _filterLabel(_filter),
          initialValue: _filter,
          onSelected: (value) => setState(() {
            _filter = value;
          }),
          itemBuilder: (context) => HomeTaskCatalogFilter.values
              .map(
                (value) => PopupMenuItem<HomeTaskCatalogFilter>(
                  value: value,
                  child: Text(_filterLabel(value)),
                ),
              )
              .toList(),
          icon: Icon(
            Icons.filter_list_rounded,
            color: _filter == HomeTaskCatalogFilter.all
                ? null
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Map<String, String> _nextRunByTask() {
    final result = <String, String>{};
    final running = widget.scriptModel.runningTask.value;
    final runningName = running.taskName.value.trim();
    if (runningName.isNotEmpty) {
      result[runningName] = '正在执行';
    }
    for (final task in [
      ...widget.scriptModel.pendingTaskList,
      ...widget.scriptModel.waitingTaskList,
    ]) {
      final name = task.taskName.value.trim();
      if (name.isEmpty || result.containsKey(name)) {
        continue;
      }
      final nextRun = task.nextRun.value.trim();
      if (nextRun.isNotEmpty) {
        result[name] = formatTaskNextRunSchedule(nextRun);
      }
    }
    return result;
  }

  List<_CatalogSectionData> _sections(
    Map<String, List<String>> menu,
    Set<String> enabledTaskNames,
  ) {
    final sections = <_CatalogSectionData>[];
    for (final entry in menu.entries) {
      final tasks = <_CatalogTaskData>[];
      final allTaskNames = <String>[];
      for (final rawTask in entry.value) {
        final taskName = rawTask.trim();
        if (taskName.isEmpty) {
          continue;
        }
        allTaskNames.add(taskName);
        final enabled =
            _enabledOverrides[taskName] ?? enabledTaskNames.contains(taskName);
        if (!_matchesFilter(taskName, enabled)) {
          continue;
        }
        tasks.add(
          _CatalogTaskData(
            name: taskName,
            groupName: entry.key,
            enabled: enabled,
          ),
        );
      }
      if (tasks.isNotEmpty) {
        sections.add(
          _CatalogSectionData(
            groupName: entry.key,
            tasks: tasks,
            allTaskNames: allTaskNames,
          ),
        );
      }
    }
    return sections;
  }

  bool _matchesFilter(String taskName, bool enabled) {
    final visible = switch (_filter) {
      HomeTaskCatalogFilter.all => true,
      HomeTaskCatalogFilter.enabled => enabled,
      HomeTaskCatalogFilter.disabled => !enabled,
    };
    if (!visible) {
      return false;
    }
    if (_searchQuery.isEmpty) {
      return true;
    }
    final localized = taskName.tr.toLowerCase();
    final original = taskName.toLowerCase();
    return localized.contains(_searchQuery) || original.contains(_searchQuery);
  }

  String _filterLabel(HomeTaskCatalogFilter value) {
    return switch (value) {
      HomeTaskCatalogFilter.all => I18n.homeTaskFilterAll.tr,
      HomeTaskCatalogFilter.enabled => I18n.homeTaskFilterEnabled.tr,
      HomeTaskCatalogFilter.disabled => I18n.homeTaskFilterDisabled.tr,
    };
  }

  Future<void> _handleBackFromParameters() async {
    await Get.find<ArgsController>().discardDraftChanges();
    await widget.controller.closeTaskParameters();
  }

  void _scrollTaskListToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(0);
    });
  }

  void _syncEnabledOverrides(Set<String> enabledTaskNames) {
    final syncedKeys = _enabledOverrides.entries
        .where((entry) => entry.value == enabledTaskNames.contains(entry.key))
        .map((entry) => entry.key)
        .toList();
    if (syncedKeys.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || syncedKeys.isEmpty) {
        return;
      }
      setState(() {
        for (final key in syncedKeys) {
          _enabledOverrides.remove(key);
        }
      });
    });
  }

  Future<void> _handleToggleTaskEnabled(
    _CatalogTaskData task,
    bool enable,
  ) async {
    if (_togglingTasks.contains(task.name)) {
      return;
    }
    setState(() {
      _togglingTasks.add(task.name);
    });
    final ret = await widget.controller.quickToggleTaskEnabled(
      scriptName: widget.scriptModel.name,
      taskName: task.name,
      enable: enable,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _togglingTasks.remove(task.name);
      if (!ret) {
        return;
      }
      _enabledOverrides[task.name] = enable;
      task.enabled = enable;
    });
  }
}

class _CatalogSectionTitle extends StatelessWidget {
  const _CatalogSectionTitle({
    required this.controller,
    required this.sourceScriptName,
    required this.section,
    required this.dragEnabled,
    required this.activeDragPayload,
  });

  final HomeDashboardController controller;
  final String sourceScriptName;
  final _CatalogSectionData section;
  final bool dragEnabled;
  final ConfigDragPayload? activeDragPayload;

  @override
  Widget build(BuildContext context) {
    final payload = controller.buildTaskCatalogGroupDragPayload(
      sourceConfig: sourceScriptName,
      groupName: section.groupName,
      taskNames: section.allTaskNames,
    );
    final isDraggingGroup =
        activeDragPayload?.matchesTaskCatalogGroup(
          sourceScriptName,
          section.groupName,
        ) ??
        false;
    return Row(
      children: [
        if (dragEnabled) ...[
          Draggable<ConfigDragPayload>(
            data: payload,
            feedback: DragCopyFeedback(label: payload.displayLabel),
            onDragStarted: () => controller.startConfigDrag(payload),
            onDragCompleted: controller.clearConfigDrag,
            onDraggableCanceled: (_, __) => controller.clearConfigDrag(),
            onDragEnd: (_) => controller.clearConfigDrag(),
            child: Icon(
              Icons.drag_indicator_outlined,
              color: isDraggingGroup
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            section.groupName.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${section.tasks.length}',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CatalogTaskRow extends StatelessWidget {
  const _CatalogTaskRow({
    required this.controller,
    required this.sourceScriptName,
    required this.task,
    required this.timeText,
    required this.loading,
    required this.onToggleEnabled,
    required this.onOpenTask,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.canQuickScheduleTask,
    required this.quickScheduleLocked,
    required this.dragEnabled,
    required this.activeDragPayload,
  });

  final HomeDashboardController controller;
  final String sourceScriptName;
  final _CatalogTaskData task;
  final String timeText;
  final bool loading;
  final ValueChanged<bool> onToggleEnabled;
  final Future<void> Function(String taskName) onOpenTask;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final bool Function(String taskName) canQuickScheduleTask;
  final bool quickScheduleLocked;
  final bool dragEnabled;
  final ConfigDragPayload? activeDragPayload;
  @override
  Widget build(BuildContext context) {
    final isDraggingTask =
        activeDragPayload?.matchesTask(sourceScriptName, task.name) ?? false;
    final scheme = Theme.of(context).colorScheme;
    final dragColor = Theme.of(
      context,
    ).colorScheme.primaryContainer.withValues(alpha: 0.42);
    final isScriptGroup = task.groupName == I18n.script;
    final supportsEnable = !isScriptGroup || task.name == I18n.restart;
    final payload = controller.buildTaskDragPayload(
      sourceConfig: sourceScriptName,
      taskName: task.name,
    );
    final nameLabel = Text(
      task.name.tr,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );
    final title = dragEnabled
        ? Draggable<ConfigDragPayload>(
            data: payload,
            feedback: DragCopyFeedback(label: payload.displayLabel),
            onDragStarted: () => controller.startConfigDrag(payload),
            onDragCompleted: controller.clearConfigDrag,
            onDraggableCanceled: (_, __) => controller.clearConfigDrag(),
            onDragEnd: (_) => controller.clearConfigDrag(),
            child: nameLabel,
          )
        : nameLabel;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: isDraggingTask ? dragColor : scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                _TaskBadge(task.name, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(child: title),
                if (supportsEnable)
                  Transform.scale(
                    scale: 0.82,
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 26,
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Switch.adaptive(
                              value: task.enabled,
                              onChanged: onToggleEnabled,
                            ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                task.enabled ? (timeText.isEmpty ? '已启用' : timeText) : '未启用',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: task.enabled
                      ? const Color(0xff0c9f70)
                      : scheme.outline,
                ),
              ),
              const Spacer(),
              _IconOnlyButton(
                icon: Icons.flash_on_rounded,
                tooltip: '立即排队',
                onPressed:
                    task.enabled &&
                        canQuickScheduleTask(task.name) &&
                        !quickScheduleLocked
                    ? () => onQuickRun(task.name)
                    : null,
              ),
              _IconOnlyButton(
                icon: Icons.tune_rounded,
                tooltip: I18n.homeOpenTaskParams.tr,
                onPressed: () => onOpenTask(task.name),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  const _TaskBadge(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label.tr.isEmpty ? '?' : label.tr.substring(0, 1),
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _CatalogSectionCard extends StatelessWidget {
  const _CatalogSectionCard({
    required this.controller,
    required this.sourceScriptName,
    required this.nextRunByTask,
    required this.section,
    required this.togglingTasks,
    required this.onToggleEnabled,
    required this.onOpenTask,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.canQuickScheduleTask,
    required this.quickScheduleLocked,
    required this.dragEnabled,
    required this.activeDragPayload,
  });

  final HomeDashboardController controller;
  final String sourceScriptName;
  final Map<String, String> nextRunByTask;
  final _CatalogSectionData section;
  final Set<String> togglingTasks;
  final Future<void> Function(_CatalogTaskData task, bool enable)
  onToggleEnabled;
  final Future<void> Function(String taskName) onOpenTask;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final bool Function(String taskName) canQuickScheduleTask;
  final bool quickScheduleLocked;
  final bool dragEnabled;
  final ConfigDragPayload? activeDragPayload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDraggingGroup =
        activeDragPayload?.matchesTaskCatalogGroup(
          sourceScriptName,
          section.groupName,
        ) ??
        false;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: isDraggingGroup
                ? scheme.primaryContainer.withValues(alpha: 0.28)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _CatalogSectionTitle(
            controller: controller,
            sourceScriptName: sourceScriptName,
            section: section,
            dragEnabled: dragEnabled,
            activeDragPayload: activeDragPayload,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.tasks.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 390,
              mainAxisExtent: kHomeCatalogTaskCardExtent,
              crossAxisSpacing: kHomeTaskCardGap,
              mainAxisSpacing: kHomeTaskCardGap,
            ),
            itemBuilder: (context, index) {
              final task = section.tasks[index];
              return _CatalogTaskRow(
                controller: controller,
                sourceScriptName: sourceScriptName,
                task: task,
                timeText: nextRunByTask[task.name] ?? '',
                loading: togglingTasks.contains(task.name),
                onToggleEnabled: (value) => onToggleEnabled(task, value),
                onOpenTask: onOpenTask,
                onQuickRun: onQuickRun,
                onQuickWait: onQuickWait,
                canQuickScheduleTask: canQuickScheduleTask,
                quickScheduleLocked: quickScheduleLocked,
                dragEnabled: dragEnabled,
                activeDragPayload: activeDragPayload,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _IconOnlyButton extends StatelessWidget {
  const _IconOnlyButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      iconSize: 18,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _CatalogSectionData {
  const _CatalogSectionData({
    required this.groupName,
    required this.tasks,
    required this.allTaskNames,
  });

  final String groupName;
  final List<_CatalogTaskData> tasks;
  final List<String> allTaskNames;
}

class _CatalogTaskData {
  _CatalogTaskData({
    required this.name,
    required this.groupName,
    required this.enabled,
  });

  final String name;
  final String groupName;
  bool enabled;
}

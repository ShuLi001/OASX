# OASX 资产快照实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 OASX 中实现与截图一致的静态资产快照面板，并让右侧窄栏和主工作区共享同一套展示组件。

**Architecture:** 新增资产快照静态数据与展示组件。组件负责标题、预览状态、货币 2×2 网格、资源双列网格和可滚动内容；右侧 sidebar 与主工作区资产页只负责传入紧凑/宽松显示模式。图标复制到 OASX 包内的 `assets/asset_icons` 并通过 Flutter assets 声明。

**Tech Stack:** Flutter 3.35+, Dart 3.9+, Material 3, GetX, `flutter_test`。

**Spec:** `docs/superpowers/specs/2026-10-31-asset-snapshot-design.md`

## Global Constraints

- 本阶段只展示静态预览数据，不接入 OAS 后端资产快照接口。
- 右侧窄栏必须可滚动；文本单行省略；极窄宽度允许单列，不能产生 RenderFlex overflow。
- 货币卡片目标高度 56–60px；资源卡片目标高度 48–52px；图标盒约 36–40px。
- 继续使用现有 Flutter、Material 3 和 OASX 主题，不改变其他工作区标签行为。
- Gemini 只提供了视觉建议，不参与任何代码或文件修改。

## Review Focus

- **静态资源路径**：所有使用的 PNG 必须在 Flutter asset bundle 中可加载；由任务 1 的资源测试与 `flutter test` 覆盖。
- **长名称与窄栏**：名称必须单行省略，卡片高度不能因文字变化；由任务 2 的窄宽度 widget 测试覆盖。
- **两列到单列断点**：在窄栏和更宽主面板中都要有稳定布局；由任务 2 的宽度测试覆盖。
- **真实入口复用**：sidebar 和 inline 资产页都必须使用共享组件；由任务 3 的静态检查和 widget 测试覆盖。
- **预览状态表达**：不能把静态数据伪装为后端刷新结果；由任务 2 的提示文案和刷新按钮行为测试覆盖。

### Task 1: 添加静态资产模型、数据和图片资源

**Files:**
- Create: `OASX/lib/modules/home/models/asset_snapshot_catalog.dart`
- Create: `OASX/assets/asset_icons/金币.png`
- Create: `OASX/assets/asset_icons/勾玉.png`
- Create: `OASX/assets/asset_icons/体力.png`
- Create: `OASX/assets/asset_icons/御札.png`
- Create: `OASX/assets/asset_icons/神秘的符咒.png`
- Create: `OASX/assets/asset_icons/大蛇的逆鳞.png`
- Create: `OASX/assets/asset_icons/逢魔之魂.png`
- Create: `OASX/assets/asset_icons/结界挑战券.png`
- Create: `OASX/assets/asset_icons/百鬼夜行门票.png`
- Create: `OASX/assets/asset_icons/樱饼.png`
- Create: `OASX/assets/asset_icons/花笺.png`
- Create: `OASX/assets/asset_snapshot_variables.json`
- Modify: `OASX/pubspec.yaml`
- Test: `OASX/test/asset_snapshot_catalog_test.dart`

**Interfaces:**
- Produces immutable `AssetSnapshotEntry` data with `name`, `variableName`, `iconAsset`, `quantity`, and `delta`.
- Produces `AssetSnapshotCatalog.currencies` and `AssetSnapshotCatalog.resources` static lists.

- [ ] **Step 1: Write the failing catalog test** asserting the four currency names, eight resource names, and that every referenced asset path exists on disk.
- [ ] **Step 2: Run `flutter test test/asset_snapshot_catalog_test.dart` and verify it fails because the catalog and/or asset declarations do not exist.**
- [ ] **Step 3: Copy the selected PNG files from `D:\AI_dot\Codex\OAS_UI\图标` into `OASX/assets/asset_icons`, implement the immutable catalog, declare `assets/asset_icons/` in `pubspec.yaml`, and write `assets/asset_snapshot_variables.json` as the Chinese-name-to-stable-variable mapping for later OAS integration.
- [ ] **Step 4: Run the focused catalog test and verify it passes.**

### Task 2: Build the shared asset snapshot presentation

**Files:**
- Create: `OASX/lib/modules/home/widgets/asset_snapshot_panel.dart`
- Test: `OASX/test/asset_snapshot_panel_test.dart`

**Interfaces:**
- Produces `AssetSnapshotPanel({Key? key, bool compact = false, VoidCallback? onRefresh})`.
- Uses `AssetSnapshotCatalog` and renders `资产快照`, `货币`, `物品库·资源`, the local preview notice, and a refresh button.

- [ ] **Step 1: Write failing widget tests** for title/sections/cards, preview notice and refresh callback; set surface sizes around 320px and 720px and assert no exception.
- [ ] **Step 2: Run `flutter test test/asset_snapshot_panel_test.dart` and verify it fails because the shared widget does not exist.**
- [ ] **Step 3: Implement fixed-height cards with 36–40px contained icons, single-line ellipsis names, subdued red/green delta text, two-column grids at normal widths, and a single-column fallback below the narrow breakpoint. Keep the entire body in a `SingleChildScrollView`.
- [ ] **Step 4: Run the focused widget tests and verify they pass at narrow and wide sizes.**
- [ ] **Step 5: Refactor only after green to keep card and delta rendering helpers focused and reusable within the widget file.**

### Task 3: Replace both existing placeholders with the shared widget

**Files:**
- Modify: `OASX/lib/modules/home/widgets/workbench_sidebar_panel.dart`
- Modify: `OASX/lib/modules/home/widgets/active_config_panel.dart`
- Modify: `OASX/test/asset_snapshot_panel_test.dart`

**Interfaces:**
- Sidebar passes `compact: true` and keeps the panel inside its existing `Expanded` area.
- Main workbench passes `compact: false` and keeps existing tab selection behavior unchanged.

- [ ] **Step 1: Extend the widget test to pump both shared presentation modes and assert both render the same section labels without overflow.**
- [ ] **Step 2: Run the test and verify the current placeholder integration fails the new assertions.**
- [ ] **Step 3: Replace `_AssetSnapshotPanel` and `_AssetSnapshotInlinePanel` usages with `AssetSnapshotPanel`, retaining the existing tab labels and controller wiring.
- [ ] **Step 4: Run the focused tests and verify both paths pass.**

### Task 4: Full verification

**Files:**
- Modify: any files required by formatter or analyzer output only.

- [ ] **Step 1: Run `dart format lib/modules/home/models/asset_snapshot_catalog.dart lib/modules/home/widgets/asset_snapshot_panel.dart test/asset_snapshot_catalog_test.dart test/asset_snapshot_panel_test.dart`.
- [ ] **Step 2: Run `flutter analyze` from `OASX` and resolve all new diagnostics.
- [ ] **Step 3: Run `flutter test` from `OASX` and record the full result.
- [ ] **Step 4: Review the diff and manually verify the asset paths, shared integration, and absence of unrelated changes.

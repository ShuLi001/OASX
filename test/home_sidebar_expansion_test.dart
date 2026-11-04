import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/widgets/home_workbench_body.dart';
import 'package:oasx/modules/home/widgets/workbench_sidebar_panel.dart';

class _Storage implements HomeDashboardStorage {
  @override
  dynamic read(String key) => null;
  @override
  void write(String key, dynamic value) {}
}

class _DetailsProbe extends StatefulWidget {
  const _DetailsProbe();
  @override
  State<_DetailsProbe> createState() => _DetailsProbeState();
}

class _DetailsProbeState extends State<_DetailsProbe> {
  int count = 0;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => count++),
    child: Text('details $count'),
  );
}

const _sidebarKey = ValueKey('test-sidebar');
const _collectionKey = ValueKey('test-collection');
const _detailsKey = ValueKey('test-details');
const _toggleKey = ValueKey('home-workbench-toggle-sidebar-expansion');
const _rightDivider = ValueKey('home-workbench-right-divider');
const _leftDivider = ValueKey('home-workbench-left-divider');

Future<HomeDashboardController> _mount(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final controller = HomeDashboardController(storage: _Storage());
  controller.workbenchCollectionWidth.value = 230;
  controller.workbenchSplitRatio.value = .57;
  controller.activeWorkbenchSidebarTab.value = HomeWorkbenchTab.guide;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HomeWorkbenchBody(
          controller: controller,
          collectionBuilder: (_) => const SizedBox.expand(key: _collectionKey),
          detailsBuilder: (_, restore) => SizedBox(
            key: _detailsKey,
            child: Column(
              children: [
                if (restore != null)
                  TextButton(
                    onPressed: restore,
                    child: const Text('restore split'),
                  ),
                const Expanded(child: _DetailsProbe()),
              ],
            ),
          ),
          sidebarBuilder: (expanded, toggle) => WorkbenchSidebarPanel(
            key: _sidebarKey,
            controller: controller,
            scriptName: 'test',
            expanded: expanded,
            onToggleExpansion: toggle,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets(
    'sidebar expansion restores dragged widths and keeps task state',
    (tester) async {
      final controller = await _mount(tester);
      await tester.tap(find.text('details 0'));
      await tester.pump();
      await tester.drag(find.byKey(_rightDivider), const Offset(-70, 0));
      await tester.pumpAndSettle();
      final originalSidebar = tester.getRect(find.byKey(_sidebarKey));
      final originalDetails = tester.getRect(find.byKey(_detailsKey));
      final originalCollection = tester.getRect(find.byKey(_collectionKey));
      final originalRatio = controller.workbenchSplitRatio.value;
      final originalElement = tester.element(find.byKey(_sidebarKey));

      await tester.tap(find.byKey(_toggleKey));
      await tester.pumpAndSettle();
      expect(find.byTooltip('收起并恢复布局'), findsOneWidget);
      expect(tester.element(find.byKey(_sidebarKey)), same(originalElement));
      expect(find.byKey(_detailsKey), findsNothing);
      expect(
        tester.getSize(find.byKey(_sidebarKey)).width,
        closeTo(1400 - 230 - 16, .01),
      );
      expect(
        controller.activeWorkbenchSidebarTab.value,
        HomeWorkbenchTab.guide,
      );
      expect(controller.workbenchSplitRatio.value, originalRatio);
      await tester.drag(find.byKey(_leftDivider), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(controller.workbenchCollectionWidth.value, greaterThan(230));
      await tester.tap(find.byKey(_toggleKey));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_sidebarKey)), originalSidebar);
      expect(tester.element(find.byKey(_sidebarKey)), same(originalElement));
      expect(tester.getRect(find.byKey(_detailsKey)), originalDetails);
      expect(tester.getRect(find.byKey(_collectionKey)), originalCollection);
      expect(find.text('details 1'), findsOneWidget);
      expect(find.byTooltip('展开右侧栏'), findsOneWidget);
      // A second cycle takes a fresh snapshot of a newly resized split.
      await tester.drag(find.byKey(_rightDivider), const Offset(45, 0));
      await tester.pumpAndSettle();
      final updated = tester.getRect(find.byKey(_sidebarKey));
      await tester.tap(find.byKey(_toggleKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_toggleKey));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_sidebarKey)), updated);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'expanded sidebar survives window resizing and restores when wide again',
    (tester) async {
      await _mount(tester);
      final before = tester.getRect(find.byKey(_sidebarKey));
      await tester.tap(find.byKey(_toggleKey));
      await tester.pumpAndSettle();
      for (final width in [800.0, 460.0, 1400.0]) {
        await tester.binding.setSurfaceSize(Size(width, 800));
        await tester.pumpAndSettle();
        expect(find.byTooltip('收起并恢复布局'), findsOneWidget);
        expect(
          tester.getRect(find.byKey(_sidebarKey)).right,
          lessThanOrEqualTo(width),
        );
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byKey(_toggleKey));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_sidebarKey)), before);
    },
  );

  testWidgets(
    'restoring in a narrow window uses the existing two pane layout',
    (tester) async {
      final controller = await _mount(tester);
      final ratio = controller.workbenchSplitRatio.value;
      await tester.tap(find.byKey(_toggleKey));
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(const Size(800, 800));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_toggleKey));
      await tester.pumpAndSettle();
      expect(find.byKey(_sidebarKey), findsNothing);
      expect(find.byKey(_detailsKey), findsOneWidget);
      expect(controller.workbenchSplitRatio.value, ratio);
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      await tester.pumpAndSettle();
      expect(find.byKey(_toggleKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('existing divider collapse and restore still work', (
    tester,
  ) async {
    await _mount(tester);
    await tester.drag(find.byKey(_rightDivider), const Offset(-800, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(_sidebarKey), findsNothing);
    expect(find.text('restore split'), findsOneWidget);
    await tester.tap(find.text('restore split'));
    await tester.pumpAndSettle();
    expect(find.byKey(_toggleKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

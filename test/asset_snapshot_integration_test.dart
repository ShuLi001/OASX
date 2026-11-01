import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('both asset entry points use the shared snapshot panel', () {
    final sidebar = File(
      'lib/modules/home/widgets/workbench_sidebar_panel.dart',
    ).readAsStringSync();
    final workbench = File(
      'lib/modules/home/widgets/active_config_panel.dart',
    ).readAsStringSync();

    expect(sidebar, contains('AssetSnapshotPanel'));
    expect(workbench, contains('AssetSnapshotPanel'));
    expect(sidebar, isNot(contains('_AssetSnapshotPanel')));
    expect(workbench, isNot(contains('_AssetSnapshotInlinePanel')));
  });
}

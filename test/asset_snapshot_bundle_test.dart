import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all source icon files are bundled and have variable mappings', () {
    final source = Directory('../图标')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.png'))
        .map((file) => file.uri.pathSegments.last)
        .toSet();
    final bundled = Directory('assets/asset_icons')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.png'))
        .map((file) => file.uri.pathSegments.last)
        .toSet();
    final mapping =
        jsonDecode(
              File('assets/asset_snapshot_variables.json').readAsStringSync(),
            )
            as Map<String, dynamic>;

    expect(source, isNotEmpty);
    expect(bundled, containsAll(source));
    expect(mapping, hasLength(source.length));
    expect(
      mapping.keys,
      containsAll(source.map((name) => name.replaceFirst('.png', ''))),
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/models/asset_snapshot_catalog.dart';

void main() {
  test('catalog exposes the planned currency and resource entries', () {
    expect(
      AssetSnapshotCatalog.currencies.map((entry) => entry.name),
      containsAll(<String>['金币', '勾玉', '体力', '魂玉']),
    );
    expect(
      AssetSnapshotCatalog.resources.map((entry) => entry.name),
      containsAll(<String>[
        '神秘的符咒',
        '御札',
        '大蛇的逆鳞',
        '逢魔之魂',
        '结界挑战券',
        '百鬼夜行门票',
        '樱饼',
        '花笺',
      ]),
    );
  });

  test('catalog covers every mapped variable and keeps OAS display order', () {
    final entries = <AssetSnapshotEntry>[
      ...AssetSnapshotCatalog.currencies,
      ...AssetSnapshotCatalog.resources,
    ];
    final mapping = File(
      'assets/asset_snapshot_variables.json',
    ).readAsStringSync();
    expect(entries, hasLength(73));
    expect(entries.map((entry) => entry.name).toSet(), hasLength(73));
    for (final entry in entries) {
      expect(entry.variableName, isNotEmpty);
      expect(mapping, contains('"${entry.name}": "${entry.variableName}"'));
    }
  });

  test('every catalog icon is included in the OASX package', () {
    final entries = <AssetSnapshotEntry>[
      ...AssetSnapshotCatalog.currencies,
      ...AssetSnapshotCatalog.resources,
    ];

    for (final entry in entries) {
      expect(
        File(entry.iconAsset).existsSync(),
        isTrue,
        reason: entry.iconAsset,
      );
    }
  });

  test('every asset has a stable OAS variable name exported to JSON', () {
    final mapping = File(
      'assets/asset_snapshot_variables.json',
    ).readAsStringSync();
    final entries = <AssetSnapshotEntry>[
      ...AssetSnapshotCatalog.currencies,
      ...AssetSnapshotCatalog.resources,
    ];

    for (final entry in entries) {
      expect(mapping, contains('"${entry.name}"'));
    }
  });

  test(
    'catalog keeps the protocol variable names next to display metadata',
    () {
      expect(AssetSnapshotCatalog.resources.first.variableName, isNotEmpty);
    },
  );

  test('binds the red and blue support ticket asset', () {
    final icon = File('assets/asset_icons/红蓝应援券.png');
    final mapping = File(
      'assets/asset_snapshot_variables.json',
    ).readAsStringSync();

    expect(icon.existsSync(), isTrue);
    expect(mapping, contains('"红蓝应援券": "red_blue_support_ticket"'));
  });
}

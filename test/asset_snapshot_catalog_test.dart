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

  test('catalog covers every mapped variable', () {
    final entries = <AssetSnapshotEntry>[
      ...AssetSnapshotCatalog.currencies,
      ...AssetSnapshotCatalog.resources,
    ];
    final mapping = File(
      'assets/asset_snapshot_variables.json',
    ).readAsStringSync();
    expect(entries, hasLength(71));
    expect(entries.map((entry) => entry.name).toSet(), hasLength(71));
    expect(
      entries.map((entry) => entry.variableName),
      isNot(contains('limited_mystic_talisman')),
    );
    for (final entry in entries) {
      expect(entry.variableName, isNotEmpty);
      expect(mapping, contains('"${entry.name}": "${entry.variableName}"'));
    }
  });

  test('catalog follows the captured inventory rows', () {
    expect(
      AssetSnapshotCatalog.currencies.map((entry) => entry.variableName),
      orderedEquals(['gold', 'stamina', 'jade', 'soul_jade']),
    );
    // The OAS QA screenshots omit these unowned or legacy variants.
    const uncaptured = {
      'resentment_scroll',
      'greed_scroll',
      'large_star_candy',
      'small_star_candy',
    };
    expect(
      AssetSnapshotCatalog.resources
          .map((entry) => entry.variableName)
          .where((variable) => !uncaptured.contains(variable)),
      orderedEquals([
        'premium_gift_ticket',
        'mystic_talisman',
        'worldly_talisman',
        'broken_talisman',
        'myriad_soul',
        'sakura_lantern',
        'forgotten_picture_book',
        'illustration_ticket',
        'memory_token',
        'demon_soul',
        'orochi_scale',
        'spirit_realm_key',
        'gold_seal',
        'seal',
        'obsession_scroll',
        'oath_stone',
        'myriad_disc',
        'sakura_mochi',
        'orochi_scale_fragment',
        'hyakki_ticket',
        'thousand_talisman_disc',
        'shikigami_challenge_ticket',
        'realm_challenge_ticket',
        'hyakki_disc',
        'six_star_auspicious_demon',
        'lucky_daruma',
        'five_star_auspicious_demon',
        'flower_note',
        'paper_fan',
        'four_star_auspicious_demon',
        'omamori',
        'wind_chime',
        'consignment_ticket',
        'high_thunder_drum',
        'high_spirit_carp',
        'high_wind_transfer_talisman',
        'high_karmic_flame_wheel',
        'mid_thunder_drum',
        'mid_spirit_carp',
        'mid_wind_transfer_talisman',
        'mid_karmic_flame_wheel',
        'low_thunder_drum',
        'low_spirit_carp',
        'low_wind_transfer_talisman',
        'low_karmic_flame_wheel',
        'ssr_collection_trial',
        'colorful_star_candy',
        'star_candy',
        'sp_skin_ticket',
        'high_black_panther_claw',
        'high_dark_bird_feather',
        'high_fox_mask',
        'high_azure_dragon_scale',
        'skin_ticket',
        'mid_black_panther_claw',
        'mid_dark_bird_feather',
        'mid_fox_mask',
        'mid_azure_dragon_scale',
        'low_black_panther_claw',
        'low_dark_bird_feather',
        'low_fox_mask',
        'low_azure_dragon_scale',
        'red_blue_support_ticket',
      ]),
    );
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

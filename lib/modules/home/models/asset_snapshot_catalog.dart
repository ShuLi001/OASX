/// Static metadata for the OAS asset snapshot protocol.
class AssetSnapshotEntry {
  const AssetSnapshotEntry({
    required this.name,
    required this.variableName,
    required this.iconAsset,
  });

  final String name;
  final String variableName;
  final String iconAsset;
}

class AssetSnapshotCatalog {
  const AssetSnapshotCatalog._();

  static const currencies = <AssetSnapshotEntry>[
    AssetSnapshotEntry(
      name: '金币',
      variableName: 'gold',
      iconAsset: 'assets/asset_icons/金币.png',
    ),
    AssetSnapshotEntry(
      name: '体力',
      variableName: 'stamina',
      iconAsset: 'assets/asset_icons/体力.png',
    ),
    AssetSnapshotEntry(
      name: '勾玉',
      variableName: 'jade',
      iconAsset: 'assets/asset_icons/勾玉.png',
    ),
    AssetSnapshotEntry(
      name: '魂玉',
      variableName: 'soul_jade',
      iconAsset: 'assets/asset_icons/魂玉.png',
    ),
  ];

  // Inventory screenshots define row-major order; absent variants stay nearby.
  static const resources = <AssetSnapshotEntry>[
    AssetSnapshotEntry(
      name: '典藏礼券',
      variableName: 'premium_gift_ticket',
      iconAsset: 'assets/asset_icons/典藏礼券.png',
    ),
    AssetSnapshotEntry(
      name: '神秘的符咒',
      variableName: 'mystic_talisman',
      iconAsset: 'assets/asset_icons/神秘的符咒.png',
    ),
    AssetSnapshotEntry(
      name: '现世符咒',
      variableName: 'worldly_talisman',
      iconAsset: 'assets/asset_icons/现世符咒.png',
    ),
    AssetSnapshotEntry(
      name: '破碎的符咒',
      variableName: 'broken_talisman',
      iconAsset: 'assets/asset_icons/破碎的符咒.png',
    ),
    AssetSnapshotEntry(
      name: '万象之魄',
      variableName: 'myriad_soul',
      iconAsset: 'assets/asset_icons/万象之魄.png',
    ),
    AssetSnapshotEntry(
      name: '樱灯饰',
      variableName: 'sakura_lantern',
      iconAsset: 'assets/asset_icons/樱灯饰.png',
    ),
    AssetSnapshotEntry(
      name: '被遗忘的绘本',
      variableName: 'forgotten_picture_book',
      iconAsset: 'assets/asset_icons/被遗忘的绘本.png',
    ),
    AssetSnapshotEntry(
      name: '插画券',
      variableName: 'illustration_ticket',
      iconAsset: 'assets/asset_icons/插画券.png',
    ),
    AssetSnapshotEntry(
      name: '契忆',
      variableName: 'memory_token',
      iconAsset: 'assets/asset_icons/契忆.png',
    ),
    AssetSnapshotEntry(
      name: '逢魔之魂',
      variableName: 'demon_soul',
      iconAsset: 'assets/asset_icons/逢魔之魂.png',
    ),
    AssetSnapshotEntry(
      name: '大蛇的逆鳞',
      variableName: 'orochi_scale',
      iconAsset: 'assets/asset_icons/大蛇的逆鳞.png',
    ),
    AssetSnapshotEntry(
      name: '御灵境之钥',
      variableName: 'spirit_realm_key',
      iconAsset: 'assets/asset_icons/御灵境之钥.png',
    ),
    AssetSnapshotEntry(
      name: '金御札',
      variableName: 'gold_seal',
      iconAsset: 'assets/asset_icons/金御札.png',
    ),
    AssetSnapshotEntry(
      name: '御札',
      variableName: 'seal',
      iconAsset: 'assets/asset_icons/御札.png',
    ),
    AssetSnapshotEntry(
      name: '痴念之卷',
      variableName: 'obsession_scroll',
      iconAsset: 'assets/asset_icons/痴念之卷.png',
    ),
    AssetSnapshotEntry(
      name: '嗔念之卷',
      variableName: 'resentment_scroll',
      iconAsset: 'assets/asset_icons/嗔念之卷.png',
    ),
    AssetSnapshotEntry(
      name: '贪念之卷',
      variableName: 'greed_scroll',
      iconAsset: 'assets/asset_icons/贪念之卷.png',
    ),
    AssetSnapshotEntry(
      name: '鸣契石',
      variableName: 'oath_stone',
      iconAsset: 'assets/asset_icons/鸣契石.png',
    ),
    AssetSnapshotEntry(
      name: '万象式盘',
      variableName: 'myriad_disc',
      iconAsset: 'assets/asset_icons/万象式盘.png',
    ),
    AssetSnapshotEntry(
      name: '樱饼',
      variableName: 'sakura_mochi',
      iconAsset: 'assets/asset_icons/樱饼.png',
    ),
    AssetSnapshotEntry(
      name: '八岐大蛇鳞片',
      variableName: 'orochi_scale_fragment',
      iconAsset: 'assets/asset_icons/八岐大蛇鳞片.png',
    ),
    AssetSnapshotEntry(
      name: '百鬼夜行门票',
      variableName: 'hyakki_ticket',
      iconAsset: 'assets/asset_icons/百鬼夜行门票.png',
    ),
    AssetSnapshotEntry(
      name: '千咒式盘',
      variableName: 'thousand_talisman_disc',
      iconAsset: 'assets/asset_icons/千咒式盘.png',
    ),
    AssetSnapshotEntry(
      name: '式神挑战券',
      variableName: 'shikigami_challenge_ticket',
      iconAsset: 'assets/asset_icons/式神挑战券.png',
    ),
    AssetSnapshotEntry(
      name: '结界挑战券',
      variableName: 'realm_challenge_ticket',
      iconAsset: 'assets/asset_icons/结界挑战券.png',
    ),
    AssetSnapshotEntry(
      name: '百物式盘',
      variableName: 'hyakki_disc',
      iconAsset: 'assets/asset_icons/百物式盘.png',
    ),
    AssetSnapshotEntry(
      name: '六星青吉鬼',
      variableName: 'six_star_auspicious_demon',
      iconAsset: 'assets/asset_icons/六星青吉鬼.png',
    ),
    AssetSnapshotEntry(
      name: '吉运达摩',
      variableName: 'lucky_daruma',
      iconAsset: 'assets/asset_icons/吉运达摩.png',
    ),
    AssetSnapshotEntry(
      name: '五星青吉鬼',
      variableName: 'five_star_auspicious_demon',
      iconAsset: 'assets/asset_icons/五星青吉鬼.png',
    ),
    AssetSnapshotEntry(
      name: '花笺',
      variableName: 'flower_note',
      iconAsset: 'assets/asset_icons/花笺.png',
    ),
    AssetSnapshotEntry(
      name: '纸扇',
      variableName: 'paper_fan',
      iconAsset: 'assets/asset_icons/纸扇.png',
    ),
    AssetSnapshotEntry(
      name: '四星青吉鬼',
      variableName: 'four_star_auspicious_demon',
      iconAsset: 'assets/asset_icons/四星青吉鬼.png',
    ),
    AssetSnapshotEntry(
      name: '御守',
      variableName: 'omamori',
      iconAsset: 'assets/asset_icons/御守.png',
    ),
    AssetSnapshotEntry(
      name: '风铃',
      variableName: 'wind_chime',
      iconAsset: 'assets/asset_icons/风铃.png',
    ),
    AssetSnapshotEntry(
      name: '寄售券',
      variableName: 'consignment_ticket',
      iconAsset: 'assets/asset_icons/寄售券.png',
    ),
    AssetSnapshotEntry(
      name: '天雷鼓_高级',
      variableName: 'high_thunder_drum',
      iconAsset: 'assets/asset_icons/天雷鼓_高级.png',
    ),
    AssetSnapshotEntry(
      name: '水灵鲤_高级',
      variableName: 'high_spirit_carp',
      iconAsset: 'assets/asset_icons/水灵鲤_高级.png',
    ),
    AssetSnapshotEntry(
      name: '风转符_高级',
      variableName: 'high_wind_transfer_talisman',
      iconAsset: 'assets/asset_icons/风转符_高级.png',
    ),
    AssetSnapshotEntry(
      name: '业火轮_高级',
      variableName: 'high_karmic_flame_wheel',
      iconAsset: 'assets/asset_icons/业火轮_高级.png',
    ),
    AssetSnapshotEntry(
      name: '天雷鼓_中级',
      variableName: 'mid_thunder_drum',
      iconAsset: 'assets/asset_icons/天雷鼓_中级.png',
    ),
    AssetSnapshotEntry(
      name: '水灵鲤_中级',
      variableName: 'mid_spirit_carp',
      iconAsset: 'assets/asset_icons/水灵鲤_中级.png',
    ),
    AssetSnapshotEntry(
      name: '风转符_中级',
      variableName: 'mid_wind_transfer_talisman',
      iconAsset: 'assets/asset_icons/风转符_中级.png',
    ),
    AssetSnapshotEntry(
      name: '业火轮_中级',
      variableName: 'mid_karmic_flame_wheel',
      iconAsset: 'assets/asset_icons/业火轮_中级.png',
    ),
    AssetSnapshotEntry(
      name: '天雷鼓_低级',
      variableName: 'low_thunder_drum',
      iconAsset: 'assets/asset_icons/天雷鼓_低级.png',
    ),
    AssetSnapshotEntry(
      name: '水灵鲤_低级',
      variableName: 'low_spirit_carp',
      iconAsset: 'assets/asset_icons/水灵鲤_低级.png',
    ),
    AssetSnapshotEntry(
      name: '风转符_低级',
      variableName: 'low_wind_transfer_talisman',
      iconAsset: 'assets/asset_icons/风转符_低级.png',
    ),
    AssetSnapshotEntry(
      name: '业火轮_低级',
      variableName: 'low_karmic_flame_wheel',
      iconAsset: 'assets/asset_icons/业火轮_低级.png',
    ),
    AssetSnapshotEntry(
      name: 'SSR全集赏_体验',
      variableName: 'ssr_collection_trial',
      iconAsset: 'assets/asset_icons/SSR全集赏_体验.png',
    ),
    AssetSnapshotEntry(
      name: '彩星糖',
      variableName: 'colorful_star_candy',
      iconAsset: 'assets/asset_icons/彩星糖.png',
    ),
    AssetSnapshotEntry(
      name: '大星糖',
      variableName: 'large_star_candy',
      iconAsset: 'assets/asset_icons/大星糖.png',
    ),
    AssetSnapshotEntry(
      name: '星星糖',
      variableName: 'star_candy',
      iconAsset: 'assets/asset_icons/星星糖.png',
    ),
    AssetSnapshotEntry(
      name: '小星糖',
      variableName: 'small_star_candy',
      iconAsset: 'assets/asset_icons/小星糖.png',
    ),
    AssetSnapshotEntry(
      name: 'SP皮肤券',
      variableName: 'sp_skin_ticket',
      iconAsset: 'assets/asset_icons/SP皮肤券.png',
    ),
    AssetSnapshotEntry(
      name: '高级黑豹爪',
      variableName: 'high_black_panther_claw',
      iconAsset: 'assets/asset_icons/高级黑豹爪.png',
    ),
    AssetSnapshotEntry(
      name: '高级冥雀羽',
      variableName: 'high_dark_bird_feather',
      iconAsset: 'assets/asset_icons/高级冥雀羽.png',
    ),
    AssetSnapshotEntry(
      name: '高级妖狐面',
      variableName: 'high_fox_mask',
      iconAsset: 'assets/asset_icons/高级妖狐面.png',
    ),
    AssetSnapshotEntry(
      name: '高级苍龙鳞',
      variableName: 'high_azure_dragon_scale',
      iconAsset: 'assets/asset_icons/高级苍龙鳞.png',
    ),
    AssetSnapshotEntry(
      name: '皮肤券',
      variableName: 'skin_ticket',
      iconAsset: 'assets/asset_icons/皮肤券.png',
    ),
    AssetSnapshotEntry(
      name: '中级黑豹爪',
      variableName: 'mid_black_panther_claw',
      iconAsset: 'assets/asset_icons/中级黑豹爪.png',
    ),
    AssetSnapshotEntry(
      name: '中级冥雀羽',
      variableName: 'mid_dark_bird_feather',
      iconAsset: 'assets/asset_icons/中级冥雀羽.png',
    ),
    AssetSnapshotEntry(
      name: '中级妖狐面',
      variableName: 'mid_fox_mask',
      iconAsset: 'assets/asset_icons/中级妖狐面.png',
    ),
    AssetSnapshotEntry(
      name: '中级苍龙鳞',
      variableName: 'mid_azure_dragon_scale',
      iconAsset: 'assets/asset_icons/中级苍龙鳞.png',
    ),
    AssetSnapshotEntry(
      name: '低级黑豹爪',
      variableName: 'low_black_panther_claw',
      iconAsset: 'assets/asset_icons/低级黑豹爪.png',
    ),
    AssetSnapshotEntry(
      name: '低级冥雀羽',
      variableName: 'low_dark_bird_feather',
      iconAsset: 'assets/asset_icons/低级冥雀羽.png',
    ),
    AssetSnapshotEntry(
      name: '低级妖狐面',
      variableName: 'low_fox_mask',
      iconAsset: 'assets/asset_icons/低级妖狐面.png',
    ),
    AssetSnapshotEntry(
      name: '低级苍龙鳞',
      variableName: 'low_azure_dragon_scale',
      iconAsset: 'assets/asset_icons/低级苍龙鳞.png',
    ),
    AssetSnapshotEntry(
      name: '红蓝应援券',
      variableName: 'red_blue_support_ticket',
      iconAsset: 'assets/asset_icons/红蓝应援券.png',
    ),
  ];
}

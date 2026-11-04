import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:oasx/translation/i18n.dart';

void main() {
  test('asset snapshot task and configuration keys translate in Chinese', () {
    final previousLocale = Get.locale;
    final previousTranslations = {
      for (final entry in Get.translations.entries)
        entry.key: Map<String, String>.from(entry.value),
    };
    addTearDown(() {
      Get.clearTranslations();
      Get.addTranslations(previousTranslations);
      Get.locale = previousLocale;
    });
    Get.clearTranslations();
    Get.addTranslations(Messages().keys);
    Get.locale = const Locale('zh', 'CN');

    const expected = {
      'AssetSnapshot': '资产快照',
      'asset_snapshot_config': '纳物库读取',
      'force_full_scan': '始终全量读取',
      'asset_force_full_scan_help':
          '关闭时首次读取综合，之后读取最近；开启时每次综合。未读取项会标记为沿用或未确认，不计作真实变化。',
      'full_scan_interval_hours': '综合校准间隔（小时）',
      'history_generation': '历史分组版本',
      'max_reset_swipes': '复位滑动上限',
      'max_scan_swipes': '向下扫描滑动上限',
      'match_threshold': '材料匹配阈值',
    };
    for (final entry in expected.entries) {
      expect(entry.key.tr, entry.value, reason: entry.key);
    }
  });
}

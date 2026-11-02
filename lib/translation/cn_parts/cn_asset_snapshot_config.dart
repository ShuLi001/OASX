// ignore_for_file: non_constant_identifier_names
part of i18n;

final Map<String, String> _cn_asset_snapshot_config = {
  'AssetSnapshot': '资产快照',
  'asset_snapshot_config': '纳物库读取',
  'force_full_scan': '始终全量读取',
  'full_scan_interval_hours': '综合校准间隔（小时）',
  'asset_full_scan_interval_help':
      '0表示仅首次综合；建议设为24，每日综合校准，其余采集读取最近。未确认的材料不会计作真实零值。',
  'history_generation': '历史分组版本',
  'asset_history_generation_help': '手动切换未配置名称的角色后递增此值，为新角色建立独立历史。',
  'asset_force_full_scan_help':
      '关闭时首次读取综合，之后读取最近；开启时每次综合。未读取项会标记为沿用或未确认，不计作真实变化。',
  'max_reset_swipes': '复位滑动上限',
  'max_scan_swipes': '向下扫描滑动上限',
  'match_threshold': '材料匹配阈值',
};

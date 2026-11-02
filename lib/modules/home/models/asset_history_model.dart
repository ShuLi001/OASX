class AssetHistoryModel {
  AssetHistoryModel.fromJson(Map<String, dynamic> json)
    : asset = json['asset']?.toString() ?? '',
      window = Map<String, dynamic>.from(json['window'] as Map? ?? {}),
      summary = Map<String, dynamic>.from(json['summary'] as Map? ?? {}),
      records = [
        for (final row in json['records'] as List? ?? [])
          Map<String, dynamic>.from(row as Map),
      ],
      daily = [
        for (final row in json['daily'] as List? ?? [])
          Map<String, dynamic>.from(row as Map),
      ];
  final String asset;
  final Map<String, dynamic> window, summary;
  final List<Map<String, dynamic>> daily, records;
  int? get netChange => (summary['netChange'] as num?)?.toInt();
}

String formatAssetQueryTime(Object? raw) {
  final text = raw?.toString() ?? '';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  final time = parsed.isUtc ? parsed.add(const Duration(hours: 8)) : parsed;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.month)}/${two(time.day)} ${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}

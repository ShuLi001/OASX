import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/utils/time_utils.dart';

void main() {
  final now = DateTime(2026, 10, 30, 9, 15);

  test('formats same day and next day with relative labels', () {
    expect(
      formatTaskNextRunSchedule(
        DateTime(2026, 10, 30, 18, 5).toIso8601String(),
        now: now,
      ),
      '今日 18:05',
    );
    expect(
      formatTaskNextRunSchedule(
        DateTime(2026, 10, 31, 7, 2).toIso8601String(),
        now: now,
      ),
      '明日 07:02',
    );
  });

  test('keeps a compact date for later schedules', () {
    expect(
      formatTaskNextRunSchedule(
        DateTime(2026, 11, 2, 1, 3).toIso8601String(),
        now: now,
      ),
      '11-02 01:03',
    );
  });

  test('handles disabled and incomplete schedule values', () {
    expect(
      formatTaskNextRunSchedule('2026-10-30T18:05:00', isEnabled: false),
      '未启用',
    );
    expect(formatTaskNextRunSchedule(''), '已启用');
    expect(formatTaskNextRunSchedule('not-a-date'), 'not-a-date');
  });
}

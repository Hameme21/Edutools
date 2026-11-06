import 'routine_date_range.dart';

String? expiredPlannerEnd(RoutineDateRange? range, DateTime now) {
  if (range == null || !range.isAfterEnd(now)) return null;
  return '${range.endDate.year.toString().padLeft(4, '0')}-${range.endDate.month.toString().padLeft(2, '0')}-${range.endDate.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> rolloverSectionDraft(
    Map? saved, String? expiredEnd, DateTime now) {
  final draft = <String, dynamic>{
    ...?saved?.map((key, value) => MapEntry(key.toString(), value))
  };
  if (expiredEnd == null || draft['clearedForEndDate'] == expiredEnd) {
    return draft;
  }
  final end = DateTime.parse(expiredEnd);
  final boundary =
      DateTime(end.year, end.month, end.day + 1).millisecondsSinceEpoch;
  final savedAt = (draft['savedAtMs'] as num?)?.toInt() ?? 0;
  if (savedAt < boundary) {
    draft['selected'] = <String>[];
    draft['primary'] = <String, String>{};
    draft['savedAtMs'] = now.millisecondsSinceEpoch;
  }
  draft['clearedForEndDate'] = expiredEnd;
  return draft;
}

/// Reads timetable substitutions, without treating the destination weekday as
/// the source (e.g. Saturday classes held on Thursday).
int? routineDayFromNotice(String title, String description) {
  const days = {
    'mon': 1, 'tue': 2, 'wed': 3, 'thu': 4,
    'fri': 5, 'sat': 6, 'sun': 7,
  };
  const day = r'(monday|mon|tuesday|tue|wednesday|wed|thursday|thu|friday|fri|saturday|sat|sunday|sun)';
  final patterns = [
    RegExp(r'\b' + day + r"(?:'s)?\s+(?:schedule|timetable|routine|class(?:es)?\b)", caseSensitive: false),
  ];
  for (final text in [title, description]) {
    final matches = <int>{};
    for (final pattern in patterns) {
      for (final match in pattern.allMatches(text)) {
        matches.add(days[match.group(1)!.toLowerCase().substring(0, 3)]!);
      }
    }
    if (matches.length == 1) return matches.single;
    if (matches.length > 1) return null;
  }
  return null;
}

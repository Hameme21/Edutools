import 'class_schedule.dart';

class SectionOffering {
  final String id,
      program,
      courseCode,
      title,
      section,
      facultyName,
      facultyCode,
      sectionNote;
  final List<ClassSchedule> meetings;
  SectionOffering(Map<String, dynamic> json)
      : id = json['id'],
        program = json['program'],
        courseCode = json['courseCode'],
        title = json['title'],
        section = json['section'],
        facultyName = json['facultyName'],
        facultyCode = json['facultyCode'],
        sectionNote = json['sectionNote'] ?? '',
        meetings = (json['meetings'] as List)
            .asMap()
            .entries
            .map((entry) => ClassSchedule.fromJson({
                  ...Map<String, dynamic>.from(entry.value),
                  'id': '${json['id']}-${entry.key}',
                  'subject': '${json['title']} · Section ${json['section']}',
                  'courseCode': json['courseCode'],
                  'instructor': json['facultyName'],
                }))
            .toList();
  String get courseKey =>
      courseCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  String get facultyLabel => facultyName == 'To be announced'
      ? 'TBA — To be announced'
      : '$facultyName ($facultyCode)';
}

int routineMinutes(String time) {
  final parts = time.split(':').map(int.parse).toList();
  return parts[0] * 60 + parts[1];
}

bool matchesSectionFaculty(SectionOffering section, String query) {
  final text = query.trim().toLowerCase();
  return section.section.toLowerCase().contains(text) ||
      section.facultyName.toLowerCase().contains(text) ||
      section.facultyCode.toLowerCase().contains(text);
}

List<ClassSchedule> unifiedSectionMeetings(
    Iterable<SectionOffering> active, Iterable<ClassSchedule> configured) {
  final replaced = active.map((s) => s.courseKey).toSet();
  return [
    ...configured.where((c) => !replaced.contains(
        c.courseCode.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase())),
    ...active.expand((s) => s.meetings)
  ];
}

bool classesOverlap(ClassSchedule a, ClassSchedule b) =>
    a.dayOfWeek == b.dayOfWeek &&
    routineMinutes(a.startTime) < routineMinutes(b.endTime) &&
    routineMinutes(b.startTime) < routineMinutes(a.endTime);

List<ClassSchedule> sectionClashes(SectionOffering candidate,
    Iterable<SectionOffering> active, Iterable<ClassSchedule> configured) {
  String key(String code) =>
      code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  final replaced = active.map((s) => s.courseKey).toSet()
    ..add(candidate.courseKey);
  final others = [
    ...active
        .where((s) => s.courseKey != candidate.courseKey)
        .expand((s) => s.meetings),
    ...configured.where((c) => !replaced.contains(key(c.courseCode))),
  ];
  return others
      .where((other) => candidate.meetings.any((m) => classesOverlap(m, other)))
      .toList();
}

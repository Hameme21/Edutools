import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:educal/models/class_schedule.dart';
import 'package:educal/models/section_offering.dart';
import 'package:educal/models/course_catalog.dart';
import 'package:educal/models/section_plan_lifecycle.dart';
import 'package:educal/models/routine_date_range.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:educal/state/calendar_state.dart';
import 'package:educal/screens/tools/section_planner_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data =
      jsonDecode(File('sample_data/fall_2026_sections.json').readAsStringSync())
          as Map;
  final sections = (data['offerings'] as List)
      .map((row) => SectionOffering(Map<String, dynamic>.from(row)))
      .toList();
  test('PDF day and AM/PM conversion agree with the verified lab row', () {
    expect(sections.length, 791);
    expect(sections[196].section, 'L');
    expect(sections[196].meetings.single.dayOfWeek, 3);
    expect(sections[196].meetings.single.endTime, '13:40');
    expect(sections[267].meetings.single.startTime, '14:00');
  });
  test(
      'backup of a course does not clash with its alternative; other active courses do',
      () {
    expect(sectionClashes(sections[0], [sections[0]], []), isEmpty);
    final other = ClassSchedule.fromJson(
        {...sections[0].meetings.first.toJson(), 'courseCode': 'CSE 1111'});
    expect(sectionClashes(sections[0], [], [other]), hasLength(1));
    expect(
        classesOverlap(
            other,
            ClassSchedule.fromJson({
              ...other.toJson(),
              'startTime': other.endTime,
              'endTime': '11:10'
            })),
        isFalse);
  });
  test('course planner title fills missing code and never invents a match', () {
    expect(courseCodeForTitle('Database Management Systems'), 'CSE 3521');
    expect(
        ClassSchedule.fromJson({'subject': 'Database Management Systems'})
            .courseCode,
        'CSE 3521');
    expect(courseCodeForTitle('Unknown subject'), isNull);
  });
  test('faculty search supports names and initials', () {
    expect(matchesSectionFaculty(sections[1], 'Shakila Aziz'), isTrue);
    expect(matchesSectionFaculty(sections[1], 'shaz'), isTrue);
    expect(matchesSectionFaculty(sections[0], 'shaz'), isFalse);
  });
  test('course plus section assigns faculty and preserves editable overrides', () {
    final cls=ClassSchedule.fromJson({'subject':'Financial and Managerial Accounting · Section B','courseCode':'ACT-2111'});
    final filled=fillSectionInstructor(cls,sections);
    expect(filled.section,'B');expect(filled.instructor,'Shakila Aziz');
    expect(ClassSchedule.fromJson(filled.toJson()).section,'B');
    expect(fillSectionInstructor(filled.copyWith(instructor:'Corrected instructor'),sections).instructor,'Corrected instructor');
    expect(assignedSection(sections,'ACT 2111','NOPE'),isNull);
    expect(assignedSection(sections,'UNKNOWN 1111','B'),isNull);
    expect(sections[1].meetings.first.instructor,'Shakila Aziz');
  });
  test(
      'semester end clears old draft once and retains preparation made afterward',
      () {
    final range = RoutineDateRange(
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 12, 31),
        sourceDescription: 'Test');
    expect(expiredPlannerEnd(range, DateTime(2026, 12, 31, 23, 59)), isNull);
    final end = expiredPlannerEnd(range, DateTime(2027, 1, 1, 1));
    final reset = rolloverSectionDraft({
      'selected': ['F26-1'],
      'primary': {'ACT2111': 'F26-1'}
    }, end, DateTime(2027, 1, 1, 1));
    expect(reset['selected'], isEmpty);
    final next = {
      ...reset,
      'selected': ['F26-2'],
      'primary': {'ACT2111': 'F26-2'}
    };
    expect(rolloverSectionDraft(next, end, DateTime(2027, 1, 2))['selected'],
        ['F26-2']);
    expect(
        rolloverSectionDraft({
          'selected': ['F26-3'],
          'primary': {},
          'savedAtMs': DateTime(2027, 1, 1, 0, 1).millisecondsSinceEpoch
        }, end, DateTime(2027, 1, 2))['selected'],
        ['F26-3']);
  });
  testWidgets(
      'multiple sections stay as backups and only active meetings enter the routine',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = CalendarState();
    addTearDown(state.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => FilledButton(
                    onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => SectionPlannerSheet(
                            state: state,
                            sectionsLoader: () async => sections)),
                    child: const Text('Open planner'))))));
    await tester.tap(find.text('Open planner'));
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'ACT 2111');
    await tester.pumpAndSettle();
    await tester
        .tap(find.text('ACT 2111 — Financial and Managerial Accounting').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'A');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add section').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add section').first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 700));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'B');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add backup').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add backup').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply 1 active sections to routine'));
    await tester.pumpAndSettle();
    expect(state.classes.length, 2);
    expect(state.classes.every((c) => c.courseCode == 'ACT 2111'), isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(
        (jsonDecode(prefs.getString('section_plan_fall2026_guest')!)['selected']
                as List)
            .length,
        2);
  });
}

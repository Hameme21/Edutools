import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/class_schedule.dart';
import '../models/section_offering.dart';

class UnifiedRoutineGrid extends StatelessWidget {
  final List<SectionOffering> active;
  final List<ClassSchedule> configured;
  final ValueChanged<SectionOffering> onRemove;
  const UnifiedRoutineGrid(
      {super.key,
      required this.active,
      required this.configured,
      required this.onRemove});
  String _hour(int h) => '${h % 12 == 0 ? 12 : h % 12} ${h < 12 ? 'AM' : 'PM'}';
  @override
  Widget build(BuildContext context) {
    final meetings = unifiedSectionMeetings(active, configured);
    final metadata = {
      for (final s in active)
        for (final m in s.meetings) m.id: s
    };
    final first = meetings.fold(
        8, (h, m) => math.min(h, routineMinutes(m.startTime) ~/ 60));
    final last = meetings.fold(
        17, (h, m) => math.max(h, (routineMinutes(m.endTime) / 60).ceil()));
    final conflicts = meetings
        .where((a) =>
            meetings.any((b) => !identical(a, b) && classesOverlap(a, b)))
        .toSet();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(
          conflicts.isEmpty
              ? 'No clashes in the unified routine.'
              : '${conflicts.length} clashing meetings. Red cards show the conflicts.',
          style: TextStyle(
              color: conflicts.isEmpty
                  ? Colors.teal
                  : Theme.of(context).colorScheme.error,
              fontSize: 12)),
      const SizedBox(height: 8),
      const Text(
          'Swipe horizontally to see all hours. Cards use exact meeting times.',
          style: TextStyle(fontSize: 12)),
      const SizedBox(height: 8),
      ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: ColoredBox(
              color: const Color(0xFF202020),
              child: LayoutBuilder(builder: (context, constraints) {
                final width = math.max(1120.0, constraints.maxWidth),
                    trackWidth = width - 80,
                    hourWidth = trackWidth / (last - first);
                Widget dayCell(String text) => SizedBox(
                    width: 80,
                    child: Center(
                        child: Text(text,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))));
                return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                        width: width,
                        child: Column(children: [
                          SizedBox(
                              height: 44,
                              child: ColoredBox(
                                  color: const Color(0xFFFF873F),
                                  child: Row(children: [
                                    dayCell('Day'),
                                    for (var h = first; h < last; h++)
                                      SizedBox(
                                          width: hourWidth,
                                          child: Center(
                                              child: Text(
                                                  '${_hour(h)} – ${_hour(h + 1)}',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold)))),
                                  ]))),
                          for (final weekday in [6, 7, 1, 2, 3, 4, 5])
                            _dayRow(weekday, meetings, metadata, conflicts,
                                first, last, trackWidth, dayCell),
                        ])));
              }))),
    ]);
  }

  Widget _dayRow(
      int day,
      List<ClassSchedule> meetings,
      Map<String, SectionOffering> metadata,
      Set<ClassSchedule> conflicts,
      int first,
      int last,
      double trackWidth,
      Widget Function(String) dayCell) {
    const names = ['', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final daily = meetings.where((m) => m.dayOfWeek == day).toList()
      ..sort((a, b) =>
          routineMinutes(a.startTime).compareTo(routineMinutes(b.startTime)));
    final laneEnds = <int>[];
    final lanes = <String, int>{};
    for (final m in daily) {
      var lane =
          laneEnds.indexWhere((end) => end <= routineMinutes(m.startTime));
      if (lane < 0) {
        lane = laneEnds.length;
        laneEnds.add(0);
      }
      laneEnds[lane] = routineMinutes(m.endTime);
      lanes[m.id] = lane;
    }
    final height = daily.isEmpty ? 64.0 : laneEnds.length * 100.0 + 16;
    final scale = trackWidth / ((last - first) * 60);
    return SizedBox(
        height: height,
        child: Row(children: [
          Container(
              width: 80,
              height: height,
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF444444)))),
              child: Container(
                  decoration: BoxDecoration(
                      color: daily.isEmpty
                          ? const Color(0xFF272727)
                          : const Color(0xFF0077B6),
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(names[day],
                            style: TextStyle(
                                color:
                                    daily.isEmpty ? Colors.grey : Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text(
                            daily.isEmpty
                                ? 'No class'
                                : '${daily.length} ${daily.length == 1 ? 'class' : 'classes'}',
                            style: TextStyle(
                                color:
                                    daily.isEmpty ? Colors.grey : Colors.white,
                                fontSize: 10)),
                      ]))),
          SizedBox(
              width: trackWidth,
              height: height,
              child: Stack(children: [
                for (var h = 0; h <= last - first; h++)
                  Positioned(
                      left: h * trackWidth / (last - first),
                      top: 0,
                      bottom: 0,
                      child:
                          Container(width: 1, color: const Color(0xFF3D3D3D))),
                if (daily.isEmpty)
                  const Positioned(
                      left: 14,
                      top: 20,
                      child: Text('No classes scheduled',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic))),
                for (final m in daily)
                  Positioned(
                      left: (routineMinutes(m.startTime) - first * 60) * scale,
                      top: 8 + lanes[m.id]! * 100,
                      width: math.max(
                          1,
                          (routineMinutes(m.endTime) -
                                      routineMinutes(m.startTime)) *
                                  scale -
                              4),
                      height: 88,
                      child: _meetingCard(
                          m, metadata[m.id], conflicts.contains(m))),
              ])),
        ]));
  }

  Widget _meetingCard(
          ClassSchedule m, SectionOffering? section, bool conflict) =>
      Tooltip(
        message:
            '${m.courseCode}\n${section?.facultyLabel ?? m.instructor}\n${m.dayName} ${m.timeRangeFormatted}\n${m.room}',
        child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 23, 8),
            decoration: BoxDecoration(
                color: conflict
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF0077A4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        conflict ? Colors.redAccent : Colors.lightBlueAccent)),
            child: Stack(clipBehavior: Clip.none, children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m.courseCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    Text(
                        section == null
                            ? m.instructor
                            : '${section.facultyName} · SEC ${section.section}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10)),
                    Text('${m.timeRangeFormatted} · ${m.room}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10)),
                    Text(
                        conflict
                            ? 'CLASH'
                            : section == null
                                ? 'Configured class'
                                : '★ Active section',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10)),
                  ]),
              if (section != null)
                Positioned(
                    top: -5,
                    right: -20,
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip:
                                'Remove ${section.courseCode} section ${section.section}',
                            onPressed: () => onRemove(section),
                            icon: const Icon(Icons.close,
                                size: 16, color: Colors.white)))),
            ])),
      );
}

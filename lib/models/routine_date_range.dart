import 'package:intl/intl.dart';

class RoutineDateRange {
  final DateTime startDate;
  final DateTime endDate;
  final String title;
  final String sourceDescription;
  final bool isAutoFigured;
  final bool isCurrentDatePastSuspension;
  final DateTime? classesSuspendedDate;
  final DateTime? finalExamDate;
  final DateTime? nextSemesterBeginDate;

  RoutineDateRange({
    required this.startDate,
    required this.endDate,
    this.title = 'Active Trimester Routine',
    required this.sourceDescription,
    this.isAutoFigured = true,
    this.isCurrentDatePastSuspension = false,
    this.classesSuspendedDate,
    this.finalExamDate,
    this.nextSemesterBeginDate,
  });

  String get formattedStartDate => DateFormat('MMM d, yyyy').format(startDate);
  String get formattedEndDate => DateFormat('MMM d, yyyy').format(endDate);
  String get dateRangeFormatted => '$formattedStartDate - $formattedEndDate';

  bool containsDate(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return (clean.isAtSameMomentAs(s) || clean.isAfter(s)) &&
        (clean.isAtSameMomentAs(e) || clean.isBefore(e));
  }

  bool isBeforeStart(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    return clean.isBefore(s);
  }

  bool isAfterEnd(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return clean.isAfter(e);
  }

  RoutineDateRange copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? title,
    String? sourceDescription,
    bool? isAutoFigured,
    bool? isCurrentDatePastSuspension,
    DateTime? classesSuspendedDate,
    DateTime? finalExamDate,
    DateTime? nextSemesterBeginDate,
  }) {
    return RoutineDateRange(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      title: title ?? this.title,
      sourceDescription: sourceDescription ?? this.sourceDescription,
      isAutoFigured: isAutoFigured ?? this.isAutoFigured,
      isCurrentDatePastSuspension:
          isCurrentDatePastSuspension ?? this.isCurrentDatePastSuspension,
      classesSuspendedDate: classesSuspendedDate ?? this.classesSuspendedDate,
      finalExamDate: finalExamDate ?? this.finalExamDate,
      nextSemesterBeginDate:
          nextSemesterBeginDate ?? this.nextSemesterBeginDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
        'title': title,
        'sourceDescription': sourceDescription,
        'isAutoFigured': isAutoFigured,
        'isCurrentDatePastSuspension': isCurrentDatePastSuspension,
        'classesSuspendedDate': classesSuspendedDate != null
            ? DateFormat('yyyy-MM-dd').format(classesSuspendedDate!)
            : null,
        'finalExamDate': finalExamDate != null
            ? DateFormat('yyyy-MM-dd').format(finalExamDate!)
            : null,
        'nextSemesterBeginDate': nextSemesterBeginDate != null
            ? DateFormat('yyyy-MM-dd').format(nextSemesterBeginDate!)
            : null,
      };

  factory RoutineDateRange.fromJson(Map<String, dynamic> json) {
    return RoutineDateRange(
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 90)),
      title: json['title']?.toString() ?? 'Active Trimester Routine',
      sourceDescription: json['sourceDescription']?.toString() ?? 'Auto-figured',
      isAutoFigured: json['isAutoFigured'] == true,
      isCurrentDatePastSuspension: json['isCurrentDatePastSuspension'] == true,
      classesSuspendedDate: json['classesSuspendedDate'] != null
          ? DateTime.tryParse(json['classesSuspendedDate'].toString())
          : null,
      finalExamDate: json['finalExamDate'] != null
          ? DateTime.tryParse(json['finalExamDate'].toString())
          : null,
      nextSemesterBeginDate: json['nextSemesterBeginDate'] != null
          ? DateTime.tryParse(json['nextSemesterBeginDate'].toString())
          : null,
    );
  }
}

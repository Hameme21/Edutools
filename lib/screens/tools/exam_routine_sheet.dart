import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class _ExamEntry {
  final int day;
  final int time;
  final List<String> codes;
  final String name;
  final List<String> keywords;

  const _ExamEntry({
    required this.day,
    required this.time,
    required this.codes,
    required this.name,
    this.keywords = const [],
  });

  bool matches(String query) {
    final q = query.toLowerCase();
    if (codes.any((c) => c.toLowerCase().contains(q))) return true;
    if (name.toLowerCase().contains(q)) return true;
    if (keywords.any((k) => k.toLowerCase().contains(q))) return true;
    return false;
  }
}

const _timeLabels = ['09:30–11:00 AM', '11:30–01:00 PM', '02:30–04:00 PM'];

const _allExams = <_ExamEntry>[
  // Day 1
  _ExamEntry(day: 1, time: 1, codes: ['ENG 1011', 'ENG 101'], name: 'English I', keywords: ['eng 1', 'english', 'intensive english']),
  _ExamEntry(day: 1, time: 1, codes: ['CSE 4509', 'CSI 309'], name: 'Operating Systems', keywords: ['os', 'operating']),
  _ExamEntry(day: 1, time: 1, codes: ['GED 1005'], name: 'AI Literacy and Prompt Engineering', keywords: ['ai literacy', 'prompt engineering', 'ai prompt']),
  _ExamEntry(day: 1, time: 1, codes: ['DS 4491'], name: 'Data Science Elective (DS 4491)', keywords: ['ds', 'data science']),
  _ExamEntry(day: 1, time: 2, codes: ['ENG 1013', 'ENG 103'], name: 'English II', keywords: ['eng 2', 'english']),
  _ExamEntry(day: 1, time: 2, codes: ['CSE 4945'], name: 'UI: Concepts and Design', keywords: ['ui', 'ux', 'design', 'user interface']),
  _ExamEntry(day: 1, time: 2, codes: ['DS 4217'], name: 'DS 4217', keywords: ['ds', 'data science']),
  _ExamEntry(day: 1, time: 2, codes: ['DS 3885'], name: 'DS Elective (DS 3885)', keywords: ['ds', 'data science']),
  _ExamEntry(day: 1, time: 3, codes: ['MATH 2183', 'MATH 183', 'MATH 2107'], name: 'Calculus and Linear Algebra', keywords: ['linear', 'algebra', 'calculus', 'math']),
  _ExamEntry(day: 1, time: 3, codes: ['CSE 3313', 'CSE 313'], name: 'Computer Architecture', keywords: ['ca', 'archi', 'architecture']),
  _ExamEntry(day: 1, time: 3, codes: ['SOC 2101', 'SOC 101', 'SOC 2102'], name: 'Society, Technology and Engineering Ethics', keywords: ['soc', 'ethics', 'society']),
  _ExamEntry(day: 1, time: 3, codes: ['CSE 4889', 'CSE 489', 'DS 4889'], name: 'Machine Learning', keywords: ['ml', 'machine learning']),
  _ExamEntry(day: 1, time: 3, codes: ['CSE 4813'], name: 'Deep Learning', keywords: ['dl', 'deep learning', 'neural networks']),
  _ExamEntry(day: 1, time: 3, codes: ['CSE 4125'], name: 'Ethical Hacking and Network Defense', keywords: ['hacking', 'ethical hacking', 'network defense', 'security']),
  _ExamEntry(day: 1, time: 3, codes: ['DS 4211'], name: 'DS 4211', keywords: ['ds', 'data science']),
  // Day 2
  _ExamEntry(day: 2, time: 1, codes: ['CSE 4621', 'CSI 421'], name: 'Computer Graphics', keywords: ['cg', 'graphics']),
  _ExamEntry(day: 2, time: 1, codes: ['CSE 3521', 'CSI 221'], name: 'Database Management Systems', keywords: ['dbms', 'database', 'sql']),
  _ExamEntry(day: 2, time: 2, codes: ['CSE 4325', 'CSE 425'], name: 'Microprocessors and Microcontrollers', keywords: ['micro', 'mpi', 'microprocessors']),
  _ExamEntry(day: 2, time: 2, codes: ['MATH 1151', 'MATH 151'], name: 'Fundamental Calculus', keywords: ['calc 1', 'calculus', 'math']),
  _ExamEntry(day: 2, time: 3, codes: ['ACT 2111', 'ACT 111'], name: 'Financial and Managerial Accounting', keywords: ['act', 'accounting', 'financial']),
  _ExamEntry(day: 2, time: 3, codes: ['MATH 2205', 'STAT 205'], name: 'Probability and Statistics', keywords: ['stat', 'prob', 'statistics', 'probability']),
  // Day 3
  _ExamEntry(day: 3, time: 1, codes: ['CSE 3811', 'CSI 341'], name: 'Artificial Intelligence', keywords: ['ai', 'artificial intelligence']),
  _ExamEntry(day: 3, time: 1, codes: ['CSE 4451', 'CSE 451'], name: 'Human Computer Interaction', keywords: ['hci', 'interaction']),
  _ExamEntry(day: 3, time: 1, codes: ['DS 4123'], name: 'DS 4123', keywords: ['ds', 'data science']),
  _ExamEntry(day: 3, time: 2, codes: ['CSE 2213', 'CSI 219'], name: 'Discrete Mathematics', keywords: ['dm', 'discrete', 'discrete math']),
  _ExamEntry(day: 3, time: 2, codes: ['PMG 4101', 'CSE 469'], name: 'Project Management', keywords: ['pmg', 'project']),
  _ExamEntry(day: 3, time: 2, codes: ['TEC 2499'], name: 'Technology Entrepreneurship', keywords: ['tec', 'entrepreneurship', 'startup']),
  _ExamEntry(day: 3, time: 3, codes: ['CSE 1325', 'CSE 225'], name: 'Digital Logic Design', keywords: ['dld', 'logic', 'digital logic']),
  _ExamEntry(day: 3, time: 3, codes: ['BIO 3105', 'BIO 3107'], name: 'Biology for Engineers', keywords: ['bio', 'biology']),
  _ExamEntry(day: 3, time: 3, codes: ['CSE 4777'], name: 'Network Security', keywords: ['netsec', 'network security', 'security']),
  // Day 4
  _ExamEntry(day: 4, time: 1, codes: ['CSE 4611', 'CSI 411'], name: 'Compiler Design', keywords: ['compiler', 'cd']),
  _ExamEntry(day: 4, time: 1, codes: ['CSE 4883', 'CSI 483'], name: 'Digital Image Processing', keywords: ['dip', 'image']),
  _ExamEntry(day: 4, time: 1, codes: ['CSE 4327'], name: 'VLSI Design', keywords: ['vlsi', 'chip', 'hardware']),
  _ExamEntry(day: 4, time: 1, codes: ['CSE 4811', 'DS 4213'], name: 'Natural Language Processing', keywords: ['nlp', 'natural language']),
  _ExamEntry(day: 4, time: 2, codes: ['CSE 1111', 'CSI 121'], name: 'Structured Programming Language', keywords: ['spl', 'c programming']),
  _ExamEntry(day: 4, time: 2, codes: ['CSE 2215', 'CSI 217'], name: 'Data Structure and Algorithms I', keywords: ['dsa 1', 'dsa', 'data structures']),
  _ExamEntry(day: 4, time: 2, codes: ['CSE 4435'], name: 'Software Architecture', keywords: ['sa', 'architecture', 'software architecture']),
  _ExamEntry(day: 4, time: 2, codes: ['DS 1501'], name: 'Programming for Data Science', keywords: ['pds', 'programming']),
  _ExamEntry(day: 4, time: 2, codes: ['DS 2251'], name: 'Data Structures & Algorithms II (DS)', keywords: ['dsa ds']),
  _ExamEntry(day: 4, time: 3, codes: ['CSE 3711', 'CSE 323'], name: 'Computer Networks', keywords: ['network', 'net', 'cn']),
  _ExamEntry(day: 4, time: 3, codes: ['CSE 4893', 'CSE 493'], name: 'Introduction to Bioinformatics', keywords: ['bioinformatics', 'bio']),
  _ExamEntry(day: 4, time: 3, codes: ['DS 4523'], name: 'DS Elective (DS 4523)', keywords: ['ds', 'data science']),
  _ExamEntry(day: 4, time: 3, codes: ['DS 3101'], name: 'Data Science Core (DS 3101)', keywords: ['ds', 'data science']),
  // Day 5
  _ExamEntry(day: 5, time: 1, codes: ['MATH 2201', 'MATH 201', 'MATH 1153'], name: 'Coordinate Geometry and Vector Analysis', keywords: ['math 2', 'vector', 'geometry', 'coordinate']),
  _ExamEntry(day: 5, time: 1, codes: ['CSE 3411', 'CSI 311'], name: 'System Analysis and Design', keywords: ['sad', 'system analysis']),
  _ExamEntry(day: 5, time: 1, codes: ['EEE 4261'], name: 'Green Computing', keywords: ['green', 'green computing', 'energy']),
  _ExamEntry(day: 5, time: 1, codes: ['CSE 4511'], name: 'CSE 4511 (DS)', keywords: ['ds', 'data science']),
  _ExamEntry(day: 5, time: 2, codes: ['CSE 2217', 'CSI 227'], name: 'Data Structure and Algorithms II', keywords: ['dsa 2', 'algo', 'algorithms']),
  _ExamEntry(day: 5, time: 2, codes: ['DS 1101'], name: 'Fundamentals of Data Science', keywords: ['fds', 'data science']),
  _ExamEntry(day: 5, time: 3, codes: ['CSE 3421', 'CSI 321'], name: 'Software Engineering', keywords: ['se', 'software']),
  _ExamEntry(day: 5, time: 3, codes: ['CSE 4587'], name: 'Cloud Computing', keywords: ['cloud', 'cloud computing', 'aws']),
  _ExamEntry(day: 5, time: 3, codes: ['CSE 4817', 'DS 4817'], name: 'Big Data Analytics', keywords: ['big data', 'bda', 'analytics', 'hadoop', 'spark']),
  _ExamEntry(day: 5, time: 3, codes: ['DS 3120'], name: 'DS 3120', keywords: ['ds', 'data science']),
  // Day 6
  _ExamEntry(day: 6, time: 1, codes: ['BDS 1201'], name: 'History of the Emergence of Bangladesh', keywords: ['bds', 'history', 'bangladesh']),
  _ExamEntry(day: 6, time: 1, codes: ['ECO 4101', 'ECO 213'], name: 'Economics', keywords: ['eco', 'economics']),
  _ExamEntry(day: 6, time: 1, codes: ['DS 3521'], name: 'Database Systems (DS)', keywords: ['database', 'dbms']),
  _ExamEntry(day: 6, time: 2, codes: ['CSE 1115', 'CSI 211'], name: 'Object Oriented Programming', keywords: ['oop', 'java', 'object oriented']),
  _ExamEntry(day: 6, time: 2, codes: ['DS 1115'], name: 'DS 1115', keywords: ['ds', 'data science']),
  _ExamEntry(day: 6, time: 3, codes: ['EEE 2113', 'CSE 113'], name: 'Electrical Circuits', keywords: ['circuit', 'electrical', 'ec']),
  _ExamEntry(day: 6, time: 3, codes: ['EEE 2123', 'CSE 123'], name: 'Electronics', keywords: ['electronics']),
  _ExamEntry(day: 6, time: 3, codes: ['CSE 4531'], name: 'Computer Security', keywords: ['security', 'cyber', 'cybersecurity']),
  _ExamEntry(day: 6, time: 3, codes: ['CSE 4181', 'CSE 481'], name: 'Mobile Application Development', keywords: ['mad', 'android', 'mobile app']),
  _ExamEntry(day: 6, time: 3, codes: ['CSE 4133'], name: 'Business Intelligence', keywords: ['bi', 'business intelligence', 'analytics']),
  // Day 7
  _ExamEntry(day: 7, time: 1, codes: ['CSE 4891', 'CSE 491', 'DS 4891'], name: 'Data Mining', keywords: ['mining', 'dm', 'data mining']),
  _ExamEntry(day: 7, time: 1, codes: ['CSE 4165', 'CSE 465'], name: 'Web Programming', keywords: ['web', 'internet']),
  _ExamEntry(day: 7, time: 1, codes: ['DS 4115'], name: 'DS 4115', keywords: ['ds', 'data science']),
  _ExamEntry(day: 7, time: 2, codes: ['CSE 2233', 'CSI 233'], name: 'Theory of Computation', keywords: ['toc', 'theory', 'automata']),
  _ExamEntry(day: 7, time: 2, codes: ['CSE 4399'], name: 'Embedded Machine Learning', keywords: ['embedded ml', 'eml', 'special topics']),
  _ExamEntry(day: 7, time: 2, codes: ['DS 4229'], name: 'DS 4229', keywords: ['ds', 'data science']),
  _ExamEntry(day: 7, time: 3, codes: ['PHY 2105', 'PHY 105'], name: 'Physics', keywords: ['phy', 'physics']),
  _ExamEntry(day: 7, time: 3, codes: ['CSE 4495', 'CSE 495'], name: 'Software Testing and Quality Assurance', keywords: ['sqa', 'testing', 'qa']),
  _ExamEntry(day: 7, time: 3, codes: ['DS 3881'], name: 'DS Elective (DS 3881)', keywords: ['ds', 'data science']),
];

class ExamRoutineSheet extends StatefulWidget {
  const ExamRoutineSheet({super.key});

  @override
  State<ExamRoutineSheet> createState() => _ExamRoutineSheetState();
}

class _ExamRoutineSheetState extends State<ExamRoutineSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<_ExamEntry> _matchedExams() {
    if (_query.isEmpty) return [];
    return _allExams.where((e) => e.matches(_query)).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matched = _matchedExams();
    final matchedKeys = <String>{};
    for (final m in matched) {
      matchedKeys.add('${m.day}-${m.time}');
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(
            margin: const EdgeInsets.only(top: 10), width: 36, height: 4,
            decoration: BoxDecoration(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0x1AF59E0B), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.event_note_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Exam Routine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                Text('Final Exam Schedule • Day × Time Slot', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
              ])),
              IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context), visualDensity: VisualDensity.compact),
            ]),
          ),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search course code or name...',
                hintStyle: TextStyle(color: isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AppTheme.primaryLight.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('${matched.length} course${matched.length == 1 ? '' : 's'} found', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildTable(isDark, matched),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(bool isDark, List<_ExamEntry> matched) {
    const cellW = 150.0;
    const headerW = 56.0;

    return Table(
      defaultColumnWidth: const FixedColumnWidth(cellW),
      columnWidths: const {0: FixedColumnWidth(headerW)},
      border: TableBorder.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 0.5),
      children: [
        TableRow(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          children: [
            _headerCell('', isDark),
            for (int t = 0; t < 3; t++)
              _headerCell('T${t + 1}\n${_timeLabels[t]}', isDark),
          ],
        ),
        for (int d = 1; d <= 7; d++)
          TableRow(children: [
            _headerCell('Day $d', isDark),
            for (int t = 1; t <= 3; t++)
              _examCell(d, t, isDark, matched),
          ]),
      ],
    );
  }

  Widget _headerCell(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
    );
  }

  Widget _examCell(int day, int time, bool isDark, List<_ExamEntry> matched) {
    final exams = _allExams.where((e) => e.day == day && e.time == time).toList();
    if (exams.isEmpty) {
      return const SizedBox(height: 40);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: exams.map((exam) {
          final isMatch = _query.isNotEmpty && matched.contains(exam);
          return Tooltip(
            message: exam.name,
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isMatch
                    ? AppTheme.primaryLight.withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(4),
                border: isMatch ? Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.5), width: 1) : null,
              ),
              child: Text(
                exam.codes.first,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isMatch ? FontWeight.w800 : FontWeight.w500,
                  color: isMatch
                      ? AppTheme.primaryLight
                      : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

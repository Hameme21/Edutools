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
  _ExamEntry(day: 1, time: 1, codes: ['ENG 1011', 'ENG 101'], name: 'English I', keywords: ['eng 1', 'english', 'eng1011', 'intensive english']),
  _ExamEntry(day: 1, time: 1, codes: ['CSE 4509', 'CSI 309'], name: 'Operating Systems', keywords: ['os', 'operating', 'systems', 'csi 309', 'cse4509']),
  _ExamEntry(day: 1, time: 1, codes: ['GED 1005'], name: 'AI Literacy and Prompt Engineering', keywords: ['ai literacy', 'prompt engineering', 'ged', 'ged1005', 'prompt', 'ai prompt']),
  _ExamEntry(day: 1, time: 1, codes: ['DS 4491'], name: 'Data Science Elective (DS 4491)', keywords: ['ds', 'data science']),
  _ExamEntry(day: 1, time: 2, codes: ['ENG 1013', 'ENG 103'], name: 'English II', keywords: ['eng 2', 'english', 'eng1013']),
  _ExamEntry(day: 1, time: 2, codes: ['CSE 4945'], name: 'UI: Concepts and Design', keywords: ['ui', 'ux', 'design', 'user interface', 'concepts', 'cse4945']),
  _ExamEntry(day: 1, time: 2, codes: ['DS 4217'], name: 'DS 4217', keywords: ['ds', 'data science']),
  _ExamEntry(day: 1, time: 2, codes: ['DS 3885'], name: 'DS Elective (DS 3885)', keywords: ['ds', 'data science']),
  _ExamEntry(day: 1, time: 3, codes: ['MATH 2183', 'MATH 183', 'MATH 2107'], name: 'Calculus and Linear Algebra', keywords: ['linear', 'algebra', 'calculus', 'math', 'math2183', 'math 183']),
  _ExamEntry(day: 1, time: 3, codes: ['CSE 3313', 'CSE 313'], name: 'Computer Architecture', keywords: ['ca', 'archi', 'architecture', 'cse3313', 'cse 313']),
  _ExamEntry(day: 1, time: 3, codes: ['SOC 2101', 'SOC 101', 'SOC 2102'], name: 'Society, Technology and Engineering Ethics', keywords: ['soc', 'ethics', 'society', 'soc2101', 'soc 101']),
  _ExamEntry(day: 1, time: 3, codes: ['CSE 4889', 'CSE 489', 'DS 4889'], name: 'Machine Learning', keywords: ['ml', 'machine learning', 'cse4889', 'cse 489']),
  _ExamEntry(day: 1, time: 3, codes: ['CSE 4813'], name: 'Deep Learning', keywords: ['dl', 'deep learning', 'neural networks', 'cse4813']),
  _ExamEntry(day: 1, time: 3, codes: ['CSE 4125'], name: 'Ethical Hacking and Network Defense', keywords: ['hacking', 'ethical hacking', 'network defense', 'security', 'defense', 'cse4125']),
  _ExamEntry(day: 1, time: 3, codes: ['DS 4211'], name: 'DS 4211', keywords: ['ds', 'data science']),
  // Day 2
  _ExamEntry(day: 2, time: 1, codes: ['CSE 4621', 'CSI 421'], name: 'Computer Graphics', keywords: ['cg', 'graphics', 'computer graphics', 'cse4621', 'csi 421']),
  _ExamEntry(day: 2, time: 1, codes: ['CSE 3521', 'CSI 221'], name: 'Database Management Systems', keywords: ['dbms', 'database', 'sql', 'cse3521', 'csi 221']),
  _ExamEntry(day: 2, time: 2, codes: ['CSE 4325', 'CSE 425'], name: 'Microprocessors and Microcontrollers', keywords: ['micro', 'mpi', 'microprocessors', 'microcontrollers', 'cse4325', 'cse 425']),
  _ExamEntry(day: 2, time: 2, codes: ['MATH 1151', 'MATH 151'], name: 'Fundamental Calculus', keywords: ['calc 1', 'calculus', 'math', 'fundamental calculus', 'math1151', 'math 151']),
  _ExamEntry(day: 2, time: 3, codes: ['ACT 2111', 'ACT 111'], name: 'Financial and Managerial Accounting', keywords: ['act', 'accounting', 'financial', 'act2111', 'act 111']),
  _ExamEntry(day: 2, time: 3, codes: ['MATH 2205', 'STAT 205'], name: 'Probability and Statistics', keywords: ['stat', 'prob', 'statistics', 'probability', 'math2205', 'stat 205']),
  // Day 3
  _ExamEntry(day: 3, time: 1, codes: ['CSE 3811', 'CSI 341'], name: 'Artificial Intelligence', keywords: ['ai', 'artificial intelligence', 'cse3811', 'csi 341']),
  _ExamEntry(day: 3, time: 1, codes: ['CSE 4451', 'CSE 451'], name: 'Human Computer Interaction', keywords: ['hci', 'interaction', 'human computer', 'cse4451', 'cse 451']),
  _ExamEntry(day: 3, time: 1, codes: ['DS 4123'], name: 'DS 4123', keywords: ['ds', 'data science']),
  _ExamEntry(day: 3, time: 2, codes: ['CSE 2213', 'CSI 219'], name: 'Discrete Mathematics', keywords: ['dm', 'discrete', 'discrete math', 'cse2213', 'csi 219']),
  _ExamEntry(day: 3, time: 2, codes: ['PMG 4101', 'CSE 469'], name: 'Project Management', keywords: ['pmg', 'project', 'project management', 'pmg4101', 'cse 469']),
  _ExamEntry(day: 3, time: 2, codes: ['TEC 2499'], name: 'Technology Entrepreneurship', keywords: ['tec', 'entrepreneurship', 'startup', 'tec2499']),
  _ExamEntry(day: 3, time: 3, codes: ['CSE 1325', 'CSE 225'], name: 'Digital Logic Design', keywords: ['dld', 'logic', 'digital logic', 'cse1325', 'cse 225']),
  _ExamEntry(day: 3, time: 3, codes: ['BIO 3105', 'BIO 3107'], name: 'Biology for Engineers', keywords: ['bio', 'biology', 'bio3105', 'bio 3107']),
  _ExamEntry(day: 3, time: 3, codes: ['CSE 4777'], name: 'Network Security', keywords: ['netsec', 'network security', 'security', 'cse4777']),
  // Day 4
  _ExamEntry(day: 4, time: 1, codes: ['CSE 4611', 'CSI 411'], name: 'Compiler Design', keywords: ['compiler', 'cd', 'compiler design', 'cse4611', 'csi 411']),
  _ExamEntry(day: 4, time: 1, codes: ['CSE 4883', 'CSI 483'], name: 'Digital Image Processing', keywords: ['dip', 'image', 'image processing', 'cse4883', 'csi 483']),
  _ExamEntry(day: 4, time: 1, codes: ['CSE 4327'], name: 'VLSI Design', keywords: ['vlsi', 'chip', 'hardware', 'cse4327']),
  _ExamEntry(day: 4, time: 1, codes: ['CSE 4811', 'DS 4213'], name: 'Natural Language Processing', keywords: ['nlp', 'natural language', 'cse4811', 'ds 4213']),
  _ExamEntry(day: 4, time: 2, codes: ['CSE 1111', 'CSI 121'], name: 'Structured Programming Language', keywords: ['spl', 'c programming', 'structured programming', 'cse1111', 'csi 121']),
  _ExamEntry(day: 4, time: 2, codes: ['CSE 2215', 'CSI 217'], name: 'Data Structure and Algorithms I', keywords: ['dsa 1', 'dsa', 'data structures', 'cse2215', 'csi 217']),
  _ExamEntry(day: 4, time: 2, codes: ['CSE 4435'], name: 'Software Architecture', keywords: ['sa', 'architecture', 'software architecture', 'cse4435']),
  _ExamEntry(day: 4, time: 2, codes: ['DS 1501'], name: 'Programming for Data Science', keywords: ['pds', 'programming', 'ds1501']),
  _ExamEntry(day: 4, time: 2, codes: ['DS 2251'], name: 'Data Structures & Algorithms II (DS)', keywords: ['dsa ds', 'ds2251']),
  _ExamEntry(day: 4, time: 3, codes: ['CSE 3711', 'CSE 323'], name: 'Computer Networks', keywords: ['network', 'net', 'cn', 'computer networks', 'cse3711', 'cse 323']),
  _ExamEntry(day: 4, time: 3, codes: ['CSE 4893', 'CSE 493'], name: 'Introduction to Bioinformatics', keywords: ['bioinformatics', 'bio', 'cse4893', 'cse 493']),
  _ExamEntry(day: 4, time: 3, codes: ['DS 4523'], name: 'DS Elective (DS 4523)', keywords: ['ds', 'data science']),
  _ExamEntry(day: 4, time: 3, codes: ['DS 3101'], name: 'Data Science Core (DS 3101)', keywords: ['ds', 'data science']),
  // Day 5
  _ExamEntry(day: 5, time: 1, codes: ['MATH 2201', 'MATH 201', 'MATH 1153'], name: 'Coordinate Geometry and Vector Analysis', keywords: ['math 2', 'vector', 'geometry', 'coordinate', 'math2201', 'math 201']),
  _ExamEntry(day: 5, time: 1, codes: ['CSE 3411', 'CSI 311'], name: 'System Analysis and Design', keywords: ['sad', 'system analysis', 'design', 'cse3411', 'csi 311']),
  _ExamEntry(day: 5, time: 1, codes: ['EEE 4261'], name: 'Green Computing', keywords: ['green', 'green computing', 'energy', 'eee4261']),
  _ExamEntry(day: 5, time: 1, codes: ['CSE 4511'], name: 'CSE 4511 (DS)', keywords: ['ds', 'data science']),
  _ExamEntry(day: 5, time: 2, codes: ['CSE 2217', 'CSI 227'], name: 'Data Structure and Algorithms II', keywords: ['dsa 2', 'algo', 'algorithms', 'cse2217', 'csi 227']),
  _ExamEntry(day: 5, time: 2, codes: ['DS 1101'], name: 'Fundamentals of Data Science', keywords: ['fds', 'data science', 'ds1101']),
  _ExamEntry(day: 5, time: 3, codes: ['CSE 3421', 'CSI 321'], name: 'Software Engineering', keywords: ['se', 'software', 'software engineering', 'cse3421', 'csi 321']),
  _ExamEntry(day: 5, time: 3, codes: ['CSE 4587'], name: 'Cloud Computing', keywords: ['cloud', 'cloud computing', 'aws', 'cse4587', 'cse 487']),
  _ExamEntry(day: 5, time: 3, codes: ['CSE 4817', 'DS 4817'], name: 'Big Data Analytics', keywords: ['big data', 'bda', 'analytics', 'hadoop', 'spark', 'cse4817']),
  _ExamEntry(day: 5, time: 3, codes: ['DS 3120'], name: 'DS 3120', keywords: ['ds', 'data science']),
  // Day 6
  _ExamEntry(day: 6, time: 1, codes: ['BDS 1201'], name: 'History of the Emergence of Bangladesh', keywords: ['bds', 'history', 'bangladesh', 'emergence', 'bds1201']),
  _ExamEntry(day: 6, time: 1, codes: ['ECO 4101', 'ECO 213'], name: 'Economics', keywords: ['eco', 'economics', 'economy', 'eco4101', 'eco 213']),
  _ExamEntry(day: 6, time: 1, codes: ['DS 3521'], name: 'Database Systems (DS)', keywords: ['database', 'dbms', 'ds3521']),
  _ExamEntry(day: 6, time: 2, codes: ['CSE 1115', 'CSI 211'], name: 'Object Oriented Programming', keywords: ['oop', 'java', 'object oriented', 'cse1115', 'csi 211']),
  _ExamEntry(day: 6, time: 2, codes: ['DS 1115'], name: 'DS 1115', keywords: ['ds', 'data science']),
  _ExamEntry(day: 6, time: 3, codes: ['EEE 2113', 'CSE 113'], name: 'Electrical Circuits', keywords: ['circuit', 'electrical', 'ec', 'circuits', 'eee2113', 'cse 113']),
  _ExamEntry(day: 6, time: 3, codes: ['EEE 2123', 'CSE 123'], name: 'Electronics', keywords: ['electronics', 'eee2123', 'cse 123']),
  _ExamEntry(day: 6, time: 3, codes: ['CSE 4531'], name: 'Computer Security', keywords: ['security', 'cyber', 'cybersecurity', 'cse4531']),
  _ExamEntry(day: 6, time: 3, codes: ['CSE 4181', 'CSE 481'], name: 'Mobile Application Development', keywords: ['mad', 'android', 'mobile app', 'app dev', 'cse4181', 'cse 481']),
  _ExamEntry(day: 6, time: 3, codes: ['CSE 4133'], name: 'Business Intelligence', keywords: ['bi', 'business intelligence', 'analytics', 'cse4133']),
  // Day 7
  _ExamEntry(day: 7, time: 1, codes: ['CSE 4891', 'CSE 491', 'DS 4891'], name: 'Data Mining', keywords: ['mining', 'dm', 'data mining', 'cse4891', 'cse 491']),
  _ExamEntry(day: 7, time: 1, codes: ['CSE 4165', 'CSE 465'], name: 'Web Programming', keywords: ['web', 'internet', 'web programming', 'cse4165', 'cse 465']),
  _ExamEntry(day: 7, time: 1, codes: ['DS 4115'], name: 'DS 4115', keywords: ['ds', 'data science']),
  _ExamEntry(day: 7, time: 2, codes: ['CSE 2233', 'CSI 233'], name: 'Theory of Computation', keywords: ['toc', 'theory', 'automata', 'computation', 'cse2233', 'csi 233']),
  _ExamEntry(day: 7, time: 2, codes: ['CSE 4399'], name: 'Embedded Machine Learning', keywords: ['embedded ml', 'eml', 'embedded machine learning', 'special topics', 'cse4399']),
  _ExamEntry(day: 7, time: 2, codes: ['DS 4229'], name: 'DS 4229', keywords: ['ds', 'data science']),
  _ExamEntry(day: 7, time: 3, codes: ['PHY 2105', 'PHY 105'], name: 'Physics', keywords: ['phy', 'physics', 'phy2105', 'phy 105']),
  _ExamEntry(day: 7, time: 3, codes: ['CSE 4495', 'CSE 495'], name: 'Software Testing and Quality Assurance', keywords: ['sqa', 'testing', 'qa', 'software testing', 'cse4495', 'cse 495']),
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
                hintText: 'Search course code, name or keyword...',
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

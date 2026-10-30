import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

const Map<String, double> _gradePoints = {
  'A': 4.00,
  'A-': 3.67,
  'B+': 3.33,
  'B': 3.00,
  'B-': 2.67,
  'C+': 2.33,
  'C': 2.00,
  'C-': 1.67,
  'D+': 1.33,
  'D': 1.00,
  'F': 0.00,
};

class _CatalogCourse {
  final String code;
  final String name;
  final double credits;
  final List<String> keywords;

  const _CatalogCourse(this.code, this.name, this.credits, [this.keywords = const []]);

  bool matches(String q) {
    final lq = q.toLowerCase();
    if (code.toLowerCase().contains(lq)) return true;
    if (name.toLowerCase().contains(lq)) return true;
    for (final k in keywords) {
      if (k.toLowerCase().contains(lq)) return true;
    }
    return false;
  }

  String get display => '$code — $name';
}

const _semesterCourses = <int, List<_CatalogCourse>>{
  1: [
    _CatalogCourse('ENG 1011', 'English I', 3, ['eng 1', 'english', 'intensive']),
    _CatalogCourse('BDS 1201', 'History of the Emergence of Bangladesh', 2, ['bds', 'history', 'bangladesh']),
    _CatalogCourse('CSE 1110', 'Introduction to Computer Systems', 1, ['intro', 'ics', 'computer systems']),
    _CatalogCourse('MATH 1151', 'Fundamental Calculus', 3, ['calc 1', 'calculus', 'math']),
  ],
  2: [
    _CatalogCourse('ENG 1013', 'English II', 3, ['eng 2', 'english']),
    _CatalogCourse('CSE 1111', 'Structured Programming Language', 3, ['spl', 'c programming']),
    _CatalogCourse('CSE 1112', 'SPL Lab', 1, ['spl lab']),
    _CatalogCourse('CSE 2213', 'Discrete Mathematics', 3, ['dm', 'discrete']),
  ],
  3: [
    _CatalogCourse('MATH 2183', 'Calculus and Linear Algebra', 3, ['linear algebra', 'calc']),
    _CatalogCourse('PHY 2105', 'Physics', 3, ['phy', 'physics']),
    _CatalogCourse('PHY 2106', 'Physics Lab', 1, ['phy lab']),
    _CatalogCourse('CSE 2215', 'Data Structure and Algorithms I', 3, ['dsa 1', 'dsa', 'data structures']),
    _CatalogCourse('CSE 2216', 'DSA I Lab', 1, ['dsa lab']),
  ],
  4: [
    _CatalogCourse('MATH 2201', 'Coordinate Geometry & Vector Analysis', 3, ['vector', 'geometry', 'math 2']),
    _CatalogCourse('CSE 1325', 'Digital Logic Design', 3, ['dld', 'digital logic']),
    _CatalogCourse('CSE 1326', 'DLD Lab', 1, ['dld lab']),
    _CatalogCourse('CSE 1115', 'Object Oriented Programming', 3, ['oop', 'java']),
    _CatalogCourse('CSE 1116', 'OOP Lab', 1, ['oop lab']),
  ],
  5: [
    _CatalogCourse('MATH 2205', 'Probability and Statistics', 3, ['stat', 'prob', 'statistics']),
    _CatalogCourse('SOC 2101', 'Society, Technology & Engineering Ethics', 3, ['soc', 'ethics']),
    _CatalogCourse('CSE 2217', 'Data Structure and Algorithms II', 3, ['dsa 2', 'algo']),
    _CatalogCourse('CSE 2218', 'DSA II Lab', 1, ['dsa 2 lab']),
    _CatalogCourse('EEE 2113', 'Electrical Circuits', 3, ['circuit', 'electrical']),
  ],
  6: [
    _CatalogCourse('CSE 3521', 'Database Management Systems', 3, ['dbms', 'database', 'sql']),
    _CatalogCourse('CSE 3522', 'DBMS Lab', 1, ['dbms lab']),
    _CatalogCourse('EEE 2123', 'Electronics', 3, ['electronics']),
    _CatalogCourse('EEE 2124', 'Electronics Lab', 1, ['electronics lab']),
    _CatalogCourse('CSE 4165', 'Web Programming', 3, ['web', 'internet']),
  ],
  7: [
    _CatalogCourse('CSE 3313', 'Computer Architecture', 3, ['ca', 'archi']),
    _CatalogCourse('CSE 2118', 'Advanced OOP Lab', 1, ['aoop lab']),
    _CatalogCourse('BIO 3105', 'Biology for Engineers', 3, ['bio', 'biology']),
    _CatalogCourse('CSE 3411', 'System Analysis and Design', 3, ['sad', 'system analysis']),
    _CatalogCourse('CSE 3412', 'SAD Lab', 1, ['sad lab']),
  ],
  8: [
    _CatalogCourse('CSE 4325', 'Microprocessors & Microcontrollers', 3, ['micro', 'mpi']),
    _CatalogCourse('CSE 4326', 'Microprocessors Lab', 1, ['micro lab']),
    _CatalogCourse('CSE 3421', 'Software Engineering', 3, ['se', 'software']),
    _CatalogCourse('CSE 3422', 'SE Lab', 1, ['se lab']),
    _CatalogCourse('CSE 3811', 'Artificial Intelligence', 3, ['ai']),
    _CatalogCourse('CSE 3812', 'AI Lab', 1, ['ai lab']),
  ],
  9: [
    _CatalogCourse('CSE 2233', 'Theory of Computation', 3, ['toc', 'automata']),
    _CatalogCourse('GED OPT1', 'General Education Optional-I', 3, ['ged']),
    _CatalogCourse('PMG 4101', 'Project Management', 3, ['pmg', 'project']),
    _CatalogCourse('CSE 3711', 'Computer Networks', 3, ['network', 'cn']),
    _CatalogCourse('CSE 3712', 'Computer Networks Lab', 1, ['cn lab']),
  ],
  10: [
    _CatalogCourse('GED OPT2', 'General Education Optional-II', 3, ['ged']),
    _CatalogCourse('CSE 4000A', 'Final Year Design Project - I', 2, ['fyp', 'project']),
    _CatalogCourse('ELECTIVE I', 'Major Elective I', 3, ['elective']),
    _CatalogCourse('CSE 4509', 'Operating Systems', 3, ['os', 'operating']),
    _CatalogCourse('CSE 4510', 'OS Lab', 1, ['os lab']),
  ],
  11: [
    _CatalogCourse('GED OPT3', 'General Education Optional-III', 3, ['ged']),
    _CatalogCourse('ELECTIVE II', 'Major Elective II', 3, ['elective']),
    _CatalogCourse('ELECTIVE III', 'Major Elective III', 3, ['elective']),
    _CatalogCourse('CSE 4000B', 'Final Year Design Project - II', 2, ['fyp', 'project']),
    _CatalogCourse('CSE 4531', 'Computer Security', 3, ['security', 'cyber']),
  ],
  12: [
    _CatalogCourse('CSE 4000C', 'Final Year Design Project - III', 2, ['fyp', 'project']),
    _CatalogCourse('EEE 4261', 'Green Computing', 3, ['green']),
    _CatalogCourse('ELECTIVE IV', 'Major Elective IV', 3, ['elective']),
    _CatalogCourse('ELECTIVE V', 'Major Elective V', 3, ['elective']),
  ],
};

const _allCatalog = <_CatalogCourse>[
  // Core
  _CatalogCourse('ENG 1011', 'English I', 3, ['eng 1', 'english']),
  _CatalogCourse('BDS 1201', 'History of the Emergence of Bangladesh', 2, ['bds', 'history']),
  _CatalogCourse('CSE 1110', 'Introduction to Computer Systems', 1, ['ics']),
  _CatalogCourse('MATH 1151', 'Fundamental Calculus', 3, ['calc 1']),
  _CatalogCourse('ENG 1013', 'English II', 3, ['eng 2']),
  _CatalogCourse('CSE 1111', 'Structured Programming Language', 3, ['spl', 'c programming']),
  _CatalogCourse('CSE 1112', 'SPL Lab', 1, ['spl lab']),
  _CatalogCourse('CSE 2213', 'Discrete Mathematics', 3, ['dm', 'discrete']),
  _CatalogCourse('MATH 2183', 'Calculus and Linear Algebra', 3, ['linear algebra']),
  _CatalogCourse('PHY 2105', 'Physics', 3, ['phy']),
  _CatalogCourse('PHY 2106', 'Physics Lab', 1, ['phy lab']),
  _CatalogCourse('CSE 2215', 'Data Structure and Algorithms I', 3, ['dsa 1', 'dsa']),
  _CatalogCourse('CSE 2216', 'DSA I Lab', 1, ['dsa lab']),
  _CatalogCourse('MATH 2201', 'Coordinate Geometry & Vector Analysis', 3, ['vector', 'geometry']),
  _CatalogCourse('CSE 1325', 'Digital Logic Design', 3, ['dld']),
  _CatalogCourse('CSE 1326', 'DLD Lab', 1, ['dld lab']),
  _CatalogCourse('CSE 1115', 'Object Oriented Programming', 3, ['oop', 'java']),
  _CatalogCourse('CSE 1116', 'OOP Lab', 1, ['oop lab']),
  _CatalogCourse('MATH 2205', 'Probability and Statistics', 3, ['stat', 'prob']),
  _CatalogCourse('SOC 2101', 'Society, Technology & Engineering Ethics', 3, ['soc', 'ethics']),
  _CatalogCourse('CSE 2217', 'Data Structure and Algorithms II', 3, ['dsa 2']),
  _CatalogCourse('CSE 2218', 'DSA II Lab', 1, ['dsa 2 lab']),
  _CatalogCourse('EEE 2113', 'Electrical Circuits', 3, ['circuit']),
  _CatalogCourse('CSE 3521', 'Database Management Systems', 3, ['dbms', 'sql']),
  _CatalogCourse('CSE 3522', 'DBMS Lab', 1, ['dbms lab']),
  _CatalogCourse('EEE 2123', 'Electronics', 3, ['electronics']),
  _CatalogCourse('EEE 2124', 'Electronics Lab', 1, ['electronics lab']),
  _CatalogCourse('CSE 4165', 'Web Programming', 3, ['web']),
  _CatalogCourse('CSE 3313', 'Computer Architecture', 3, ['ca', 'archi']),
  _CatalogCourse('CSE 2118', 'Advanced OOP Lab', 1, ['aoop']),
  _CatalogCourse('BIO 3105', 'Biology for Engineers', 3, ['bio']),
  _CatalogCourse('CSE 3411', 'System Analysis and Design', 3, ['sad']),
  _CatalogCourse('CSE 3412', 'SAD Lab', 1, ['sad lab']),
  _CatalogCourse('CSE 4325', 'Microprocessors & Microcontrollers', 3, ['micro']),
  _CatalogCourse('CSE 4326', 'Microprocessors Lab', 1, ['micro lab']),
  _CatalogCourse('CSE 3421', 'Software Engineering', 3, ['se']),
  _CatalogCourse('CSE 3422', 'SE Lab', 1, ['se lab']),
  _CatalogCourse('CSE 3811', 'Artificial Intelligence', 3, ['ai']),
  _CatalogCourse('CSE 3812', 'AI Lab', 1, ['ai lab']),
  _CatalogCourse('CSE 2233', 'Theory of Computation', 3, ['toc', 'automata']),
  _CatalogCourse('PMG 4101', 'Project Management', 3, ['pmg']),
  _CatalogCourse('CSE 3711', 'Computer Networks', 3, ['network', 'cn']),
  _CatalogCourse('CSE 3712', 'Computer Networks Lab', 1, ['cn lab']),
  _CatalogCourse('CSE 4000A', 'Final Year Design Project - I', 2, ['fyp']),
  _CatalogCourse('CSE 4509', 'Operating Systems', 3, ['os']),
  _CatalogCourse('CSE 4510', 'OS Lab', 1, ['os lab']),
  _CatalogCourse('CSE 4000B', 'Final Year Design Project - II', 2, ['fyp']),
  _CatalogCourse('CSE 4531', 'Computer Security', 3, ['security']),
  _CatalogCourse('CSE 4000C', 'Final Year Design Project - III', 2, ['fyp']),
  _CatalogCourse('EEE 4261', 'Green Computing', 3, ['green']),
  // GED
  _CatalogCourse('GED 1005', 'AI Literacy and Prompt Engineering', 3, ['ai literacy', 'prompt']),
  _CatalogCourse('ECO 4101', 'Economics', 3, ['eco', 'economics']),
  _CatalogCourse('ACT 2111', 'Financial & Managerial Accounting', 3, ['act', 'accounting']),
  _CatalogCourse('TEC 2499', 'Technology Entrepreneurship', 3, ['tec', 'entrepreneurship']),
  // Electives
  _CatalogCourse('CSE 4125', 'Ethical Hacking & Network Defense', 3, ['hacking', 'defense']),
  _CatalogCourse('CSE 4777', 'Network Security', 3, ['netsec']),
  _CatalogCourse('CSE 4587', 'Cloud Computing', 3, ['cloud', 'aws']),
  _CatalogCourse('CSE 4611', 'Compiler Design', 3, ['compiler']),
  _CatalogCourse('CSE 4621', 'Computer Graphics', 3, ['cg', 'graphics']),
  _CatalogCourse('CSE 4451', 'Human Computer Interaction', 3, ['hci']),
  _CatalogCourse('CSE 4435', 'Software Architecture', 3, ['sa']),
  _CatalogCourse('CSE 4181', 'Mobile Application Development', 3, ['mad', 'mobile app']),
  _CatalogCourse('CSE 4945', 'UI: Concepts and Design', 3, ['ui', 'ux']),
  _CatalogCourse('CSE 4495', 'Software Testing & QA', 3, ['sqa', 'testing']),
  _CatalogCourse('CSE 4327', 'VLSI Design', 3, ['vlsi']),
  _CatalogCourse('CSE 4399', 'Embedded Machine Learning', 3, ['embedded ml']),
  _CatalogCourse('CSE 4889', 'Machine Learning', 3, ['ml']),
  _CatalogCourse('CSE 4891', 'Data Mining', 3, ['mining']),
  _CatalogCourse('CSE 4817', 'Big Data Analytics', 3, ['big data', 'bda']),
  _CatalogCourse('CSE 4883', 'Digital Image Processing', 3, ['dip', 'image']),
  _CatalogCourse('CSE 4811', 'Natural Language Processing', 3, ['nlp']),
  _CatalogCourse('CSE 4813', 'Deep Learning', 3, ['dl', 'deep']),
  _CatalogCourse('CSE 4893', 'Introduction to Bioinformatics', 3, ['bioinformatics']),
  _CatalogCourse('CSE 4133', 'Business Intelligence', 3, ['bi']),
];

class _CourseEntry {
  _CatalogCourse? catalog;
  int credits;
  String? grade;
  bool isRetake = false;
  String? oldGrade;

  _CourseEntry({this.catalog, int? credits}) : credits = credits ?? catalog?.credits.toInt() ?? 3;
}

class CgpaCalculatorSheet extends StatefulWidget {
  const CgpaCalculatorSheet({super.key});

  @override
  State<CgpaCalculatorSheet> createState() => _CgpaCalculatorSheetState();
}

class _CgpaCalculatorSheetState extends State<CgpaCalculatorSheet> {
  final TextEditingController _prevCgpaCtrl = TextEditingController();
  final TextEditingController _prevCreditsCtrl = TextEditingController();
  final TextEditingController _targetCgpaCtrl = TextEditingController();
  final TextEditingController _remainingCreditsCtrl = TextEditingController(text: '30');

  int? _selectedSemester;
  final List<_CourseEntry> _courses = [];
  bool _prevExpanded = false;
  bool _targetExpanded = false;
  bool _calculated = false;

  double _trimesterGpa = 0;
  double _cumulativeCgpa = 0;
  double _totalCredits = 0;
  double _totalPoints = 0;

  @override
  void dispose() {
    _prevCgpaCtrl.dispose();
    _prevCreditsCtrl.dispose();
    _targetCgpaCtrl.dispose();
    _remainingCreditsCtrl.dispose();
    super.dispose();
  }

  void _loadSemester(int? semester) {
    setState(() {
      _selectedSemester = semester;
      _courses.clear();
      _calculated = false;
      if (semester != null && _semesterCourses.containsKey(semester)) {
        for (final c in _semesterCourses[semester]!) {
          _courses.add(_CourseEntry(catalog: c));
        }
      }
    });
  }

  void _addCourse() {
    setState(() {
      _courses.add(_CourseEntry());
      _calculated = false;
    });
  }

  void _removeCourse(int index) {
    if (_courses.length <= 1) return;
    setState(() {
      _courses.removeAt(index);
      _calculated = false;
    });
  }

  void _setCourse(int index, _CatalogCourse course) {
    setState(() {
      _courses[index].catalog = course;
      _courses[index].credits = course.credits.toInt();
      _calculated = false;
    });
  }

  void _calculate() {
    final prevCgpa = double.tryParse(_prevCgpaCtrl.text) ?? 0;
    final prevCredits = double.tryParse(_prevCreditsCtrl.text) ?? 0;

    double prevPoints = prevCgpa * prevCredits;
    double cumPoints = prevPoints;
    double cumCredits = prevCredits;
    double trimPoints = 0;
    double trimCredits = 0;

    for (final c in _courses) {
      if (c.grade == null) continue;
      final gp = _gradePoints[c.grade] ?? 0;
      final cr = c.credits.toDouble();

      if (c.isRetake && c.oldGrade != null) {
        final oldGp = _gradePoints[c.oldGrade] ?? 0;
        if (oldGp == 0) {
          trimPoints += gp * cr;
          trimCredits += cr;
          cumPoints += gp * cr;
          cumCredits += cr;
        } else {
          trimPoints += gp * cr;
          trimCredits += cr;
          cumPoints += (gp - oldGp) * cr;
        }
      } else {
        trimPoints += gp * cr;
        trimCredits += cr;
        cumPoints += gp * cr;
        cumCredits += cr;
      }
    }

    setState(() {
      _trimesterGpa = trimCredits > 0 ? trimPoints / trimCredits : 0;
      _cumulativeCgpa = cumCredits > 0 ? cumPoints / cumCredits : 0;
      _totalCredits = cumCredits;
      _totalPoints = cumPoints;
      _calculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                decoration: BoxDecoration(color: const Color(0x1A8B5CF6), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.calculate_rounded, color: AppTheme.examColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CGPA Calculator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                Text('UIU 4.00 Scale • Semester-based with Retake', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
              ])),
              IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context), visualDensity: VisualDensity.compact),
            ]),
          ),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset + 16),
              children: [
                _buildSectionHeader(isDark: isDark, icon: Icons.history_rounded, title: 'Previous Results', subtitle: 'Your CGPA before this trimester', expanded: _prevExpanded, onTap: () => setState(() => _prevExpanded = !_prevExpanded)),
                if (_prevExpanded) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _buildTextField(controller: _prevCgpaCtrl, hint: 'Previous CGPA', isDark: isDark)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(controller: _prevCreditsCtrl, hint: 'Credits Completed', isDark: isDark)),
                  ]),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
                _buildLabel('SELECT TRIMESTER', isDark),
                const SizedBox(height: 6),
                _buildSemesterSelector(isDark),
                const SizedBox(height: 12),
                _buildLabel('COURSES', isDark),
                const SizedBox(height: 8),
                for (int i = 0; i < _courses.length; i++)
                  _buildCourseRow(i, isDark),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addCourse,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Course', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _calculate,
                      icon: const Icon(Icons.functions_rounded, size: 16),
                      label: const Text('Calculate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                ]),
                if (_calculated) ...[
                  const SizedBox(height: 16),
                  _buildResultsCard(isDark),
                  const SizedBox(height: 12),
                  _buildSectionHeader(isDark: isDark, icon: Icons.track_changes_rounded, title: 'Target CGPA Planner', subtitle: 'Plan your path to a higher CGPA', expanded: _targetExpanded, onTap: () => setState(() => _targetExpanded = !_targetExpanded)),
                  if (_targetExpanded) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _buildTextField(controller: _targetCgpaCtrl, hint: 'Target CGPA', isDark: isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField(controller: _remainingCreditsCtrl, hint: 'Remaining Credits', isDark: isDark)),
                    ]),
                    const SizedBox(height: 10),
                    _buildTargetResult(isDark),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterSelector(bool isDark) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(12, (i) {
        final n = i + 1;
        final selected = n == _selectedSemester;
        return GestureDetector(
          onTap: () => _loadSemester(selected ? null : n),
          child: Container(
            width: 42, height: 36,
            decoration: BoxDecoration(
              color: selected ? AppTheme.examColor : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? AppTheme.examColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
            child: Center(child: Text('T$n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF64748B))))),
          ),
        );
      }),
    );
  }

  Widget _buildCourseRow(int index, bool isDark) {
    final entry = _courses[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(children: [
        Row(children: [
          Text('${index + 1}.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
          const SizedBox(width: 8),
          Expanded(child: _CourseSearchField(
            catalog: entry.catalog,
            isDark: isDark,
            onSelected: (c) => _setCourse(index, c),
          )),
          if (_courses.length > 1)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
              onPressed: () => _removeCourse(index),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _DropdownBox<int>(
            value: entry.credits,
            items: const [1, 2, 3, 4],
            labelBuilder: (v) => '$v cr',
            isDark: isDark,
            width: 60,
            onChanged: (v) => setState(() { entry.credits = v!; _calculated = false; }),
          ),
          const SizedBox(width: 6),
          Expanded(child: _DropdownBox<String>(
            value: entry.grade,
            hint: 'Grade',
            items: _gradePoints.keys.toList(),
            labelBuilder: (v) => '$v (${_gradePoints[v]!.toStringAsFixed(2)})',
            isDark: isDark,
            onChanged: (v) => setState(() { entry.grade = v; _calculated = false; }),
          )),
          const SizedBox(width: 6),
          SizedBox(height: 32, child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 20, height: 20, child: Checkbox(
              value: entry.isRetake,
              onChanged: (v) => setState(() { entry.isRetake = v ?? false; if (!entry.isRetake) entry.oldGrade = null; _calculated = false; }),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )),
            const SizedBox(width: 4),
            Text('Retake', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
          ])),
        ]),
        if (entry.isRetake) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.replay_rounded, size: 14, color: AppTheme.holidayColor.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text('Old Grade:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
            const SizedBox(width: 8),
            Expanded(child: _DropdownBox<String>(
              value: entry.oldGrade,
              hint: 'Select old grade',
              items: _gradePoints.keys.toList(),
              labelBuilder: (v) => '$v (${_gradePoints[v]!.toStringAsFixed(2)})',
              isDark: isDark,
              onChanged: (v) => setState(() { entry.oldGrade = v; _calculated = false; }),
            )),
          ]),
        ],
      ]),
    );
  }

  Widget _buildResultsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x1A8B5CF6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x338B5CF6)),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: _resultColumn('TRIMESTER GPA', _trimesterGpa.toStringAsFixed(2), isDark)),
          Container(width: 1, height: 48, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          Expanded(child: _resultColumn('CUMULATIVE CGPA', _cumulativeCgpa.toStringAsFixed(2), isDark, highlight: true)),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text('Total Credits: ${_totalCredits.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
        ),
      ]),
    );
  }

  Widget _resultColumn(String label, String value, bool isDark, {bool highlight = false}) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: highlight ? 32 : 26, fontWeight: FontWeight.w900, color: AppTheme.examColor)),
    ]);
  }

  Widget _buildTargetResult(bool isDark) {
    final targetCgpa = double.tryParse(_targetCgpaCtrl.text);
    final remaining = double.tryParse(_remainingCreditsCtrl.text);
    if (targetCgpa == null || remaining == null || remaining <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        child: Text('Enter your target CGPA and remaining credits above.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
      );
    }
    final requiredGpa = (targetCgpa * (_totalCredits + remaining) - _totalPoints) / remaining;
    Color msgColor;
    String msg;
    if (requiredGpa <= 0) {
      msgColor = AppTheme.accentColor;
      msg = 'You have already surpassed your target CGPA of ${targetCgpa.toStringAsFixed(2)}!';
    } else if (requiredGpa > 4.0) {
      msgColor = AppTheme.holidayColor;
      msg = 'Target CGPA ${targetCgpa.toStringAsFixed(2)} is not achievable with $remaining credits. You would need a ${requiredGpa.toStringAsFixed(2)} GPA which exceeds 4.00.';
    } else {
      msgColor = AppTheme.primaryLight;
      msg = 'You need a ${requiredGpa.toStringAsFixed(2)} GPA over ${remaining.toStringAsFixed(0)} credits to reach ${targetCgpa.toStringAsFixed(2)} CGPA.';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: msgColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: msgColor.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(requiredGpa <= 0 ? Icons.emoji_events_rounded : (requiredGpa > 4.0 ? Icons.warning_amber_rounded : Icons.info_outline_rounded), size: 18, color: msgColor),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: msgColor, height: 1.35))),
      ]),
    );
  }

  Widget _buildSectionHeader({required bool isDark, required IconData icon, required String title, required String subtitle, required bool expanded, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        child: Row(children: [
          Icon(icon, size: 18, color: AppTheme.examColor),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text(subtitle, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
          ])),
          Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 20, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
        ]),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: isDark ? Colors.white54 : const Color(0xFF64748B)));
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required bool isDark}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      ),
    );
  }
}

class _CourseSearchField extends StatefulWidget {
  final _CatalogCourse? catalog;
  final bool isDark;
  final ValueChanged<_CatalogCourse> onSelected;

  const _CourseSearchField({required this.catalog, required this.isDark, required this.onSelected});

  @override
  State<_CourseSearchField> createState() => _CourseSearchFieldState();
}

class _CourseSearchFieldState extends State<_CourseSearchField> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  List<_CatalogCourse> _suggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.catalog != null) _ctrl.text = widget.catalog!.display;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _CourseSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catalog != oldWidget.catalog && widget.catalog != null) {
      _ctrl.text = widget.catalog!.display;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
      _updateSuggestions(_ctrl.text);
    } else {
      _removeOverlay();
      if (widget.catalog != null) _ctrl.text = widget.catalog!.display;
    }
  }

  void _updateSuggestions(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      _suggestions = _allCatalog.take(10).toList();
    } else {
      _suggestions = _allCatalog.where((c) => c.matches(q)).take(8).toList();
    }
    _showOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    if (_suggestions.isEmpty || !_focusNode.hasFocus) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final width = renderBox.size.width;

    _overlay = OverlayEntry(builder: (ctx) {
      final isDark = widget.isDark;
      return Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (_, i) {
                  final s = _suggestions[i];
                  return InkWell(
                    onTap: () {
                      widget.onSelected(s);
                      _ctrl.text = s.display;
                      _focusNode.unfocus();
                      _removeOverlay();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.examColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(s.code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.examColor)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.name, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF334155)), overflow: TextOverflow.ellipsis)),
                        Text('${s.credits.toInt()} cr', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : const Color(0xFF94A3B8))),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _ctrl,
        focusNode: _focusNode,
        onChanged: _updateSuggestions,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Search course code or name...',
          hintStyle: TextStyle(color: widget.isDark ? Colors.white30 : const Color(0xFFCBD5E1), fontSize: 11),
          prefixIcon: const Icon(Icons.search_rounded, size: 16),
          prefixIconConstraints: const BoxConstraints(minWidth: 32),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
          filled: true,
          fillColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        ),
      ),
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  final T? value;
  final String? hint;
  final List<T> items;
  final String Function(T) labelBuilder;
  final bool isDark;
  final double? width;
  final ValueChanged<T?> onChanged;

  const _DropdownBox({required this.value, this.hint, required this.items, required this.labelBuilder, required this.isDark, this.width, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null ? Text(hint!, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : const Color(0xFFCBD5E1))) : null,
          isExpanded: true,
          isDense: true,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(labelBuilder(item), style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

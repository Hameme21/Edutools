import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class _Course {
  final String code;
  final String name;
  final double credits;
  final bool isLab;

  const _Course(this.code, this.name, this.credits, {this.isLab = false});
}

const _curriculum = <int, List<_Course>>{
  1: [
    _Course('ENG 1011', 'Intensive English', 3),
    _Course('MATH 1151', 'Fundamental Calculus', 3),
    _Course('CSE 1111', 'Structured Programming Language', 3),
    _Course('CSE 1112', 'Structured Programming Language Lab', 1, isLab: true),
  ],
  2: [
    _Course('ENG 1013', 'English II', 3),
    _Course('MATH 2201', 'Co-ordinate Geometry & Vector Analysis', 3),
    _Course('CSE 1115', 'Object Oriented Programming', 3),
    _Course('CSE 1116', 'Object Oriented Programming Lab', 1, isLab: true),
    _Course('CSE 1325', 'Digital Logic Design', 3),
    _Course('CSE 1326', 'Digital Logic Design Lab', 1, isLab: true),
  ],
  3: [
    _Course('MATH 2183', 'Calculus and Linear Algebra', 3),
    _Course('CSE 2213', 'Discrete Mathematics', 3),
    _Course('CSE 2215', 'Data Structure and Algorithms I', 3),
    _Course('CSE 2216', 'Data Structure and Algorithms I Lab', 1, isLab: true),
    _Course('EEE 2113', 'Electrical Circuits', 3),
    _Course('EEE 2114', 'Electrical Circuits Lab', 1, isLab: true),
  ],
  4: [
    _Course('MATH 2205', 'Probability and Statistics', 3),
    _Course('CSE 2217', 'Data Structure and Algorithms II', 3),
    _Course('CSE 2218', 'Data Structure and Algorithms II Lab', 1, isLab: true),
    _Course('EEE 2123', 'Electronics', 3),
    _Course('EEE 2124', 'Electronics Lab', 1, isLab: true),
    _Course('BDS 1201', 'History of the Emergence of Bangladesh', 3),
  ],
  5: [
    _Course('CSE 3313', 'Computer Architecture', 3),
    _Course('CSE 2233', 'Theory of Computation', 3),
    _Course('CSE 3521', 'Database Management Systems', 3),
    _Course('CSE 3522', 'Database Management Systems Lab', 1, isLab: true),
    _Course('SOC 2101', 'Society, Technology and Engineering Ethics', 3),
  ],
  6: [
    _Course('CSE 3711', 'Computer Networks', 3),
    _Course('CSE 3712', 'Computer Networks Lab', 1, isLab: true),
    _Course('CSE 3421', 'Software Engineering', 3),
    _Course('CSE 3422', 'Software Engineering Lab', 1, isLab: true),
    _Course('CSE 3411', 'System Analysis and Design', 3),
    _Course('PHY 2105', 'Physics', 3),
    _Course('PHY 2106', 'Physics Lab', 1, isLab: true),
  ],
  7: [
    _Course('CSE 4509', 'Operating Systems', 3),
    _Course('CSE 4510', 'Operating Systems Lab', 1, isLab: true),
    _Course('CSE 3811', 'Artificial Intelligence', 3),
    _Course('CSE 3812', 'Artificial Intelligence Lab', 1, isLab: true),
    _Course('ACT 2111', 'Financial and Managerial Accounting', 3),
  ],
  8: [
    _Course('CSE 4889', 'Machine Learning', 3),
    _Course('CSE 4890', 'Machine Learning Lab', 1, isLab: true),
    _Course('CSE 4611', 'Compiler Design', 3),
    _Course('ECO 4101', 'Economics', 3),
    _Course('PMG 4101', 'Project Management', 3),
  ],
  9: [
    _Course('CSE 4899', 'Senior Project I', 2),
    _Course('ELECTIVE 1', 'CSE Elective I', 3),
    _Course('ELECTIVE 2', 'CSE Elective II', 3),
    _Course('GED 1', 'General Education I', 3),
  ],
  10: [
    _Course('CSE 4900', 'Senior Project II', 2),
    _Course('ELECTIVE 3', 'CSE Elective III', 3),
    _Course('ELECTIVE 4', 'CSE Elective IV', 3),
    _Course('GED 2', 'General Education II', 3),
  ],
  11: [
    _Course('ELECTIVE 5', 'CSE Elective V', 3),
    _Course('ELECTIVE 6', 'CSE Elective VI', 3),
    _Course('GED 3', 'General Education III', 3),
  ],
  12: [
    _Course('BIO 3105', 'Biology for Engineers', 3),
  ],
};

const _gedOptions = <String, List<_Course>>{
  'GED 1001 – World Civilization': [_Course('GED 1001', 'World Civilization', 3)],
  'GED 1003 – Bangla Language and Literature': [_Course('GED 1003', 'Bangla Language and Literature', 3)],
  'GED 1005 – AI Literacy and Prompt Engineering': [_Course('GED 1005', 'AI Literacy and Prompt Engineering', 3)],
  'TEC 2499 – Technology Entrepreneurship': [_Course('TEC 2499', 'Technology Entrepreneurship', 3)],
};

const _electiveTracks = <String, List<_Course>>{
  'Software Engineering': [
    _Course('CSE 4435', 'Software Architecture', 3),
    _Course('CSE 4451', 'Human Computer Interaction', 3),
    _Course('CSE 4165', 'Web Programming', 3),
    _Course('CSE 4945', 'UI: Concepts and Design', 3),
    _Course('CSE 4495', 'Software Testing and QA', 3),
    _Course('CSE 4181', 'Mobile Application Development', 3),
  ],
  'Cyber Security': [
    _Course('CSE 4531', 'Computer Security', 3),
    _Course('CSE 4777', 'Network Security', 3),
    _Course('CSE 4125', 'Ethical Hacking & Network Defense', 3),
  ],
  'AI & Data Science': [
    _Course('CSE 4813', 'Deep Learning', 3),
    _Course('CSE 4811', 'Natural Language Processing', 3),
    _Course('CSE 4891', 'Data Mining', 3),
    _Course('CSE 4817', 'Big Data Analytics', 3),
    _Course('CSE 4883', 'Digital Image Processing', 3),
    _Course('CSE 4893', 'Intro to Bioinformatics', 3),
    _Course('CSE 4133', 'Business Intelligence', 3),
  ],
  'Systems & Hardware': [
    _Course('CSE 4325', 'Microprocessors & Microcontrollers', 3),
    _Course('CSE 4327', 'VLSI Design', 3),
    _Course('CSE 4621', 'Computer Graphics', 3),
    _Course('EEE 4261', 'Green Computing', 3),
    _Course('CSE 4399', 'Embedded Machine Learning', 3),
  ],
  'Cloud & Infrastructure': [
    _Course('CSE 4587', 'Cloud Computing', 3),
  ],
};

class CoursePlannerSheet extends StatefulWidget {
  const CoursePlannerSheet({super.key});

  @override
  State<CoursePlannerSheet> createState() => _CoursePlannerSheetState();
}

class _CoursePlannerSheetState extends State<CoursePlannerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _expandedTrack;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  double _trimesterCredits(int tri) {
    return _curriculum[tri]?.fold<double>(0, (s, c) => s + c.credits) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                child: const Icon(Icons.school_rounded, color: Color(0xFF8B5CF6), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Course Planner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                Text('UIU BSc in CSE Curriculum', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
              ])),
              IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context), visualDensity: VisualDensity.compact),
            ]),
          ),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white38 : const Color(0xFF64748B),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Curriculum'),
                Tab(text: 'GED Options'),
                Tab(text: 'Electives'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildCurriculum(isDark),
                _buildGED(isDark),
                _buildElectives(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculum(bool isDark) {
    double totalCredits = 0;
    for (final courses in _curriculum.values) {
      for (final c in courses) {
        totalCredits += c.credits;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primaryLight.withValues(alpha: 0.1), AppTheme.primaryLight.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight, size: 18),
            const SizedBox(width: 8),
            Text('12 Trimesters • ${totalCredits.toInt()} Credits (Core)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
          ]),
        ),
        const SizedBox(height: 12),
        for (int tri = 1; tri <= 12; tri++) ...[
          _trimesterCard(tri, isDark),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _trimesterCard(int tri, bool isDark) {
    final courses = _curriculum[tri] ?? [];
    final credits = _trimesterCredits(tri);
    final yearLabel = 'Year ${((tri - 1) ~/ 3) + 1}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(6)),
                child: Text('T$tri', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Text(yearLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : const Color(0xFF64748B))),
              const Spacer(),
              Text('${credits.toInt()} cr', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryLight)),
            ]),
          ),
          for (final c in courses)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: c.isLab ? const Color(0xFF22C55E) : AppTheme.primaryLight.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Text(c.code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                ),
                Expanded(child: Text(c.name, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
                Text('${c.credits.toInt()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white38 : const Color(0xFF94A3B8))),
              ]),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildGED(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFFF59E0B).withValues(alpha: 0.1), const Color(0xFFF59E0B).withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFFF59E0B), size: 18),
            SizedBox(width: 8),
            Text('Pick 3 GED courses across trimesters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
          ]),
        ),
        const SizedBox(height: 12),
        for (final entry in _gedOptions.entries) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: const Color(0x1AF59E0B), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(entry.value.first.code.split(' ').last, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.value.first.code, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                Text(entry.value.first.name, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF64748B))),
              ])),
              Text('${entry.value.first.credits.toInt()} cr', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
            ]),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildElectives(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.1), const Color(0xFF8B5CF6).withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Icon(Icons.alt_route_rounded, color: Color(0xFF8B5CF6), size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Pick 6 electives (18 cr) from any track', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)))),
          ]),
        ),
        const SizedBox(height: 12),
        for (final entry in _electiveTracks.entries) ...[
          _trackCard(entry.key, entry.value, isDark),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _trackCard(String track, List<_Course> courses, bool isDark) {
    final isExpanded = _expandedTrack == track;
    final trackColors = {
      'Software Engineering': const Color(0xFF3B82F6),
      'Cyber Security': const Color(0xFFEF4444),
      'AI & Data Science': const Color(0xFF8B5CF6),
      'Systems & Hardware': const Color(0xFFF59E0B),
      'Cloud & Infrastructure': const Color(0xFF22C55E),
    };
    final color = trackColors[track] ?? AppTheme.primaryLight;

    return GestureDetector(
      onTap: () => setState(() => _expandedTrack = isExpanded ? null : track),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isExpanded ? color.withValues(alpha: 0.5) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(
                    track == 'Software Engineering' ? Icons.code_rounded
                        : track == 'Cyber Security' ? Icons.shield_rounded
                        : track == 'AI & Data Science' ? Icons.psychology_rounded
                        : track == 'Systems & Hardware' ? Icons.memory_rounded
                        : Icons.cloud_rounded,
                    color: color, size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(track, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  Text('${courses.length} courses', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF64748B))),
                ])),
                Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: isDark ? Colors.white38 : const Color(0xFF94A3B8), size: 20),
              ]),
            ),
            if (isExpanded) ...[
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              for (final c in courses)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: Row(children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: color.withValues(alpha: 0.5), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    SizedBox(width: 90, child: Text(c.code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
                    Expanded(child: Text(c.name, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF64748B)), overflow: TextOverflow.ellipsis)),
                    Text('${c.credits.toInt()} cr', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                  ]),
                ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

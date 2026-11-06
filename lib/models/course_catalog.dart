class PlannerCourse {
  final String code;
  final String name;
  final double credits;
  final bool isLab;

  const PlannerCourse(this.code, this.name, this.credits, {this.isLab = false});
}

const plannerCurriculum = <int, List<PlannerCourse>>{
  1: [
    PlannerCourse('ENG 1011', 'English I', 3),
    PlannerCourse('BDS 1201', 'History of the Emergence of Bangladesh', 2),
    PlannerCourse('CSE 1110', 'Introduction to Computer Systems', 1),
    PlannerCourse('MATH 1151', 'Fundamental Calculus', 3),
  ],
  2: [
    PlannerCourse('ENG 1013', 'English II', 3),
    PlannerCourse('CSE 1111', 'Structured Programming Language', 3),
    PlannerCourse('CSE 1112', 'Structured Programming Language Lab', 1,
        isLab: true),
    PlannerCourse('CSE 2213', 'Discrete Mathematics', 3),
  ],
  3: [
    PlannerCourse('MATH 2183', 'Calculus and Linear Algebra', 3),
    PlannerCourse('PHY 2105', 'Physics', 3),
    PlannerCourse('PHY 2106', 'Physics Lab', 1, isLab: true),
    PlannerCourse('CSE 2215', 'Data Structure and Algorithms I', 3),
    PlannerCourse('CSE 2216', 'Data Structure and Algorithms I Lab', 1,
        isLab: true),
  ],
  4: [
    PlannerCourse('MATH 2201', 'Coordinate Geometry and Vector Analysis', 3),
    PlannerCourse('CSE 1325', 'Digital Logic Design', 3),
    PlannerCourse('CSE 1326', 'Digital Logic Design Lab', 1, isLab: true),
    PlannerCourse('CSE 1115', 'Object Oriented Programming', 3),
    PlannerCourse('CSE 1116', 'Object Oriented Programming Lab', 1,
        isLab: true),
  ],
  5: [
    PlannerCourse('MATH 2205', 'Probability and Statistics', 3),
    PlannerCourse('SOC 2101', 'Society, Technology and Engineering Ethics', 3),
    PlannerCourse('CSE 2217', 'Data Structure and Algorithms II', 3),
    PlannerCourse('CSE 2218', 'Data Structure and Algorithms II Lab', 1,
        isLab: true),
    PlannerCourse('EEE 2113', 'Electrical Circuits', 3),
  ],
  6: [
    PlannerCourse('CSE 3521', 'Database Management Systems', 3),
    PlannerCourse('CSE 3522', 'Database Management Systems Lab', 1,
        isLab: true),
    PlannerCourse('EEE 2123', 'Electronics', 3),
    PlannerCourse('EEE 2124', 'Electronics Lab', 1, isLab: true),
    PlannerCourse('CSE 4165', 'Web Programming', 3),
  ],
  7: [
    PlannerCourse('CSE 3313', 'Computer Architecture', 3),
    PlannerCourse('CSE 2118', 'Advanced OOP Lab', 1, isLab: true),
    PlannerCourse('BIO 3105', 'Biology for Engineers', 3),
    PlannerCourse('CSE 3411', 'System Analysis and Design', 3),
    PlannerCourse('CSE 3412', 'System Analysis and Design Lab', 1, isLab: true),
  ],
  8: [
    PlannerCourse('CSE 4325', 'Microprocessors and Microcontrollers', 3),
    PlannerCourse('CSE 4326', 'Microprocessors and Microcontrollers Lab', 1,
        isLab: true),
    PlannerCourse('CSE 3421', 'Software Engineering', 3),
    PlannerCourse('CSE 3422', 'Software Engineering Lab', 1, isLab: true),
    PlannerCourse('CSE 3811', 'Artificial Intelligence', 3),
    PlannerCourse('CSE 3812', 'Artificial Intelligence Lab', 1, isLab: true),
  ],
  9: [
    PlannerCourse('CSE 2233', 'Theory of Computation', 3),
    PlannerCourse('GED OPT1', 'General Education Optional-I', 3),
    PlannerCourse('PMG 4101', 'Project Management', 3),
    PlannerCourse('CSE 3711', 'Computer Networks', 3),
    PlannerCourse('CSE 3712', 'Computer Networks Lab', 1, isLab: true),
  ],
  10: [
    PlannerCourse('GED OPT2', 'General Education Optional-II', 3),
    PlannerCourse('CSE 4000A', 'Final Year Design Project - I', 2),
    PlannerCourse('ELECTIVE I', 'Major Elective I', 3),
    PlannerCourse('CSE 4509', 'Operating Systems', 3),
    PlannerCourse('CSE 4510', 'Operating Systems Lab', 1, isLab: true),
  ],
  11: [
    PlannerCourse('GED OPT3', 'General Education Optional-III', 3),
    PlannerCourse('ELECTIVE II', 'Major Elective II', 3),
    PlannerCourse('ELECTIVE III', 'Major Elective III', 3),
    PlannerCourse('CSE 4000B', 'Final Year Design Project - II', 2),
    PlannerCourse('CSE 4531', 'Computer Security', 3),
  ],
  12: [
    PlannerCourse('CSE 4000C', 'Final Year Design Project - III', 2),
    PlannerCourse('EEE 4261', 'Green Computing', 3),
    PlannerCourse('ELECTIVE IV', 'Major Elective IV', 3),
    PlannerCourse('ELECTIVE V', 'Major Elective V', 3),
  ],
};

const plannerGedOptions = <String, List<PlannerCourse>>{
  'GED 1005 – AI Literacy and Prompt Engineering': [
    PlannerCourse('GED 1005', 'AI Literacy and Prompt Engineering', 3)
  ],
  'ECO 4101 – Economics': [PlannerCourse('ECO 4101', 'Economics', 3)],
  'ACT 2111 – Financial and Managerial Accounting': [
    PlannerCourse('ACT 2111', 'Financial and Managerial Accounting', 3)
  ],
  'TEC 2499 – Technology Entrepreneurship': [
    PlannerCourse('TEC 2499', 'Technology Entrepreneurship', 3)
  ],
};

const plannerElectiveTracks = <String, List<PlannerCourse>>{
  'Network & Cyber Security': [
    PlannerCourse('CSE 4125', 'Ethical Hacking and Network Defense', 3),
    PlannerCourse('CSE 4777', 'Network Security', 3),
  ],
  'Software Engineering': [
    PlannerCourse('CSE 4587', 'Cloud Computing', 3),
    PlannerCourse('CSE 4611', 'Compiler Design', 3),
    PlannerCourse('CSE 4621', 'Computer Graphics', 3),
    PlannerCourse('CSE 4451', 'Human Computer Interaction', 3),
    PlannerCourse('CSE 4435', 'Software Architecture', 3),
    PlannerCourse('CSE 4181', 'Mobile Application Development', 3),
    PlannerCourse('CSE 4945', 'UI: Concepts and Design', 3),
    PlannerCourse('CSE 4495', 'Software Testing and QA', 3),
  ],
  'Embedded System & Robotics': [
    PlannerCourse('CSE 4327', 'VLSI Design', 3),
    PlannerCourse('CSE 4399', 'Embedded Machine Learning', 3),
  ],
  'AI & Data Science': [
    PlannerCourse('CSE 4889', 'Machine Learning', 3),
    PlannerCourse('CSE 4891', 'Data Mining', 3),
    PlannerCourse('CSE 4817', 'Big Data Analytics', 3),
    PlannerCourse('CSE 4883', 'Digital Image Processing', 3),
    PlannerCourse('CSE 4811', 'Natural Language Processing', 3),
    PlannerCourse('CSE 4813', 'Deep Learning', 3),
    PlannerCourse('CSE 4893', 'Introduction to Bioinformatics', 3),
  ],
  'Business System Engineering': [
    PlannerCourse('CSE 4451', 'Human Computer Interaction', 3),
    PlannerCourse('CSE 4891', 'Data Mining', 3),
    PlannerCourse('CSE 4817', 'Big Data Analytics', 3),
    PlannerCourse('CSE 4945', 'UI: Concepts and Design', 3),
    PlannerCourse('CSE 4133', 'Business Intelligence', 3),
  ],
};

List<PlannerCourse> get plannerCourses => {
      for (final c in [
        ...plannerCurriculum.values.expand((v) => v),
        ...plannerGedOptions.values.expand((v) => v),
        ...plannerElectiveTracks.values.expand((v) => v)
      ])
        if (RegExp(r'^[A-Z]+ \d').hasMatch(c.code)) c.code: c
    }.values.toList();
String normalizeCourseTitle(String value) => value
    .toLowerCase()
    .replaceAll('&', 'and')
    .replaceAll('laboratory', 'lab')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');
String? courseCodeForTitle(String title) {
  final matches = plannerCourses
      .where((c) => normalizeCourseTitle(c.name) == normalizeCourseTitle(title))
      .toList();
  return matches.length == 1 ? matches.single.code : null;
}

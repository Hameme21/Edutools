class StudentProfile {
  final String email;
  final String studentId;
  final String fullName;
  final String department;
  final String semester;
  final bool isSynced;
  final DateTime lastSyncTime;

  StudentProfile({
    required this.email,
    required this.studentId,
    required this.fullName,
    String? department,
    this.semester = 'Spring 2026',
    this.isSynced = true,
    DateTime? lastSyncTime,
  })  : department = department ?? inferDepartmentFromEmail(email),
        lastSyncTime = lastSyncTime ?? DateTime.now();

  static String inferDepartmentFromEmail(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('bscse.') || lower.contains('@cse.')) {
      return 'Computer Science & Engineering';
    } else if (lower.contains('bseee.') || lower.contains('@eee.')) {
      return 'Electrical & Electronic Engineering';
    } else if (lower.contains('bba.') || lower.contains('@sobe.')) {
      return 'School of Business & Economics';
    } else if (lower.contains('bsce.') || lower.contains('@ce.')) {
      return 'Civil Engineering';
    } else if (lower.contains('mscse.')) {
      return 'MS in Computer Science & Engineering';
    }
    return 'United International University';
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'studentId': studentId,
        'fullName': fullName,
        'department': department,
        'semester': semester,
        'isSynced': isSynced,
        'lastSyncTime': lastSyncTime.toIso8601String(),
      };

  static String formatNameFromEmail(String email) {
    if (email.isEmpty) return 'Student';
    final handle = email.split('@').first;
    final parts = handle.split(RegExp(r'[\._\-]'));
    final formatted = parts
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ')
        .trim();
    return formatted.isNotEmpty ? formatted : 'Student';
  }

  String get avatarLetter {
    final name = displayName.trim();
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    if (email.trim().isNotEmpty) {
      return email.trim()[0].toUpperCase();
    }
    return 'S';
  }

  String get displayName {
    if (fullName.trim().isNotEmpty && fullName.trim() != 'Verified Student') {
      return fullName.trim();
    }
    return formatNameFromEmail(email);
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final email = json['email']?.toString() ?? '';
    return StudentProfile(
      email: email,
      studentId: json['studentId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      department: json['department']?.toString() ?? inferDepartmentFromEmail(email),
      semester: json['semester']?.toString() ?? 'Spring 2026',
      isSynced: json['isSynced'] == true,
      lastSyncTime: DateTime.tryParse(json['lastSyncTime']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  StudentProfile copyWith({
    String? email,
    String? studentId,
    String? fullName,
    String? department,
    String? semester,
    bool? isSynced,
    DateTime? lastSyncTime,
  }) {
    return StudentProfile(
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      isSynced: isSynced ?? this.isSynced,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

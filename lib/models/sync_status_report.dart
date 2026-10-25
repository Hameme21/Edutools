class SyncStatusReport {
  final bool success;
  final String email;
  final String syncHealth; // 'PERFECT', 'GOOD', 'DISCREPANCIES_DETECTED', 'DESYNC', 'NO_SCHEDULE'
  final double matchRatePercent;
  final int totalParsed;
  final int totalSynced;
  final int matchedCount;
  final int discrepancyCount;
  final List<dynamic> missingEvents;
  final List<dynamic> duplicateEvents;
  final List<dynamic> misalignedEvents;
  final String lastSyncTimestamp;
  final List<String> auditLogs;

  SyncStatusReport({
    required this.success,
    required this.email,
    required this.syncHealth,
    required this.matchRatePercent,
    required this.totalParsed,
    required this.totalSynced,
    required this.matchedCount,
    required this.discrepancyCount,
    required this.missingEvents,
    required this.duplicateEvents,
    required this.misalignedEvents,
    required this.lastSyncTimestamp,
    required this.auditLogs,
  });

  factory SyncStatusReport.fromJson(Map<String, dynamic> json) {
    return SyncStatusReport(
      success: json['success'] == true,
      email: json['email'] ?? 'student@university.edu',
      syncHealth: json['syncHealth'] ?? 'NO_SCHEDULE',
      matchRatePercent: (json['matchRatePercent'] as num?)?.toDouble() ?? 100.0,
      totalParsed: (json['totalParsed'] as num?)?.toInt() ?? 0,
      totalSynced: (json['totalSynced'] as num?)?.toInt() ?? 0,
      matchedCount: (json['matchedCount'] as num?)?.toInt() ?? 0,
      discrepancyCount: (json['discrepancyCount'] as num?)?.toInt() ?? 0,
      missingEvents: json['missingEvents'] as List<dynamic>? ?? [],
      duplicateEvents: json['duplicateEvents'] as List<dynamic>? ?? [],
      misalignedEvents: json['misalignedEvents'] as List<dynamic>? ?? [],
      lastSyncTimestamp: json['lastSyncTimestamp'] ?? DateTime.now().toIso8601String(),
      auditLogs: (json['auditLogs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  bool get isHealthy => syncHealth == 'PERFECT' || (syncHealth == 'GOOD' && matchRatePercent >= 90);
  bool get hasDiscrepancies => discrepancyCount > 0 || missingEvents.isNotEmpty || misalignedEvents.isNotEmpty;
}

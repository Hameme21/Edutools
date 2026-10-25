import 'package:flutter/material.dart';
import '../../models/sync_status_report.dart';
import '../../services/api_service.dart';

class SyncStatusWidget extends StatefulWidget {
  final String userEmail;
  final SyncStatusReport? initialReport;
  final VoidCallback? onReSync;

  const SyncStatusWidget({
    super.key,
    required this.userEmail,
    this.initialReport,
    this.onReSync,
  });

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final ApiService _apiService = ApiService();
  SyncStatusReport? _report;
  bool _isChecking = false;
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    _report = widget.initialReport;
    if (_report == null) {
      _fetchStatus();
    }
  }

  Future<void> _fetchStatus() async {
    setState(() => _isChecking = true);
    try {
      final report = await _apiService.getCalendarSyncStatus(widget.userEmail);
      if (mounted) {
        setState(() {
          _report = report;
          _isChecking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final report = _report ??
        SyncStatusReport(
          success: true,
          email: widget.userEmail,
          syncHealth: 'PERFECT',
          matchRatePercent: 100.0,
          totalParsed: 0,
          totalSynced: 0,
          matchedCount: 0,
          discrepancyCount: 0,
          missingEvents: [],
          duplicateEvents: [],
          misalignedEvents: [],
          lastSyncTimestamp: DateTime.now().toIso8601String(),
          auditLogs: [],
        );

    final isHealthy = report.isHealthy;
    final statusColor = isHealthy
        ? const Color(0xFF10B981) // Emerald
        : (report.syncHealth == 'DISCREPANCIES_DETECTED'
            ? const Color(0xFFF59E0B) // Amber
            : const Color(0xFFEF4444)); // Coral/Red

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status Badge & Match Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isHealthy ? Icons.check_circle_rounded : Icons.sync_problem_rounded,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calendar Sync Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'File Schedule vs Active Calendar DB',
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Match Rate Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${report.matchRatePercent.toStringAsFixed(0)}% Match',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Match Rate Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: report.matchRatePercent / 100.0,
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Quick Metrics Row (Parsed vs Synced vs Discrepancies)
          Row(
            children: [
              _buildMetricCard(
                label: 'Items Parsed',
                value: '${report.totalParsed}',
                color: const Color(0xFF2563EB),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                label: 'Items Synced',
                value: '${report.totalSynced}',
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                label: 'Discrepancies',
                value: '${report.discrepancyCount}',
                color: report.discrepancyCount > 0 ? const Color(0xFFEF4444) : Colors.grey,
                isDark: isDark,
              ),
            ],
          ),

          // Discrepancy Alerts
          if (report.hasDiscrepancies) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                      SizedBox(width: 6),
                      Text(
                        'Synchronization Discrepancy Flagged',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (report.missingEvents.isNotEmpty)
                    Text('• ${report.missingEvents.length} events from file are missing in calendar.', style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
                  if (report.duplicateEvents.isNotEmpty)
                    Text('• ${report.duplicateEvents.length} duplicate entries detected in database.', style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
                  if (report.misalignedEvents.isNotEmpty)
                    Text('• ${report.misalignedEvents.length} timing/room misalignments flagged.', style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Audit Logs Accordion & Actions
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _showLogs = !_showLogs),
                icon: Icon(_showLogs ? Icons.expand_less : Icons.expand_more, size: 16),
                label: Text(_showLogs ? 'Hide Audit Logs' : 'View Audit Logs', style: const TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              OutlinedButton.icon(
                onPressed: _isChecking ? null : _fetchStatus,
                icon: _isChecking
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Verify Sync', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),

          if (_showLogs && report.auditLogs.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.auditLogs.map((log) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• $log',
                      style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9, color: isDark ? Colors.white60 : Colors.grey[600], fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

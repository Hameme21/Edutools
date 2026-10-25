import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'format_guide_dialog.dart';

class FileImportCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color themeColor;
  final bool isClassRoutine;
  final int loadedCount;
  final Function(String) onImport;
  final VoidCallback onLoadSample;
  final VoidCallback onClear;

  const FileImportCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.themeColor,
    required this.isClassRoutine,
    required this.loadedCount,
    required this.onImport,
    required this.onLoadSample,
    required this.onClear,
  });

  @override
  State<FileImportCard> createState() => _FileImportCardState();
}

class _FileImportCardState extends State<FileImportCard> {
  final TextEditingController _textController = TextEditingController();
  bool _isExpanded = false;
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleImport() {
    setState(() => _errorMessage = null);
    final content = _textController.text.trim();
    if (content.isEmpty) {
      setState(() => _errorMessage = 'Please paste your JSON or CSV file content.');
      return;
    }

    try {
      widget.onImport(content);
      _textController.clear();
      setState(() => _isExpanded = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.title} imported successfully!'),
          backgroundColor: widget.themeColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() {
        _textController.text = data!.text!;
        _isExpanded = true;
      });
    }
  }

  void _openFormatGuide() {
    showDialog(
      context: context,
      builder: (ctx) => FormatGuideDialog(isClassRoutine: widget.isClassRoutine),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.themeColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: widget.themeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${widget.loadedCount} loaded',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _isExpanded = !_isExpanded);
                            },
                            icon: Icon(
                              _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.file_upload_outlined,
                              size: 16,
                            ),
                            label: Text(_isExpanded ? 'Hide Input' : 'Paste / Import File'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: widget.onLoadSample,
                            icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                            label: const Text('Load Sample'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openFormatGuide,
                            icon: const Icon(Icons.help_outline_rounded, size: 16),
                            label: const Text('Format Guide'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Collapsible Input & Validator Area
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Paste JSON or CSV file text:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.content_paste_rounded, size: 14),
                        label: const Text('Paste from Clipboard', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _textController,
                    maxLines: 6,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    decoration: InputDecoration(
                      hintText: widget.isClassRoutine
                          ? 'Paste JSON array [...] or CSV with header id,subject,courseCode,dayOfWeek,startTime,endTime,room,instructor,color'
                          : 'Paste JSON array [...] or CSV with header id,title,description,startDate,endDate,category,isHoliday,priority',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _textController.clear();
                          setState(() => _isExpanded = false);
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _handleImport,
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Import & Parse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.themeColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

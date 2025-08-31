import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExportOptionsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> annotations;
  final String documentTitle;
  final VoidCallback onClose;

  const ExportOptionsWidget({
    super.key,
    required this.annotations,
    required this.documentTitle,
    required this.onClose,
  });

  @override
  State<ExportOptionsWidget> createState() => _ExportOptionsWidgetState();
}

class _ExportOptionsWidgetState extends State<ExportOptionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isExporting = false;
  String _selectedFormat = 'JSON';

  final List<Map<String, dynamic>> _exportFormats = [
    {
      'format': 'JSON',
      'icon': 'code',
      'description': 'Structured data format',
      'extension': '.json',
      'color': AppTheme.accentColor,
    },
    {
      'format': 'TXT',
      'icon': 'text_fields',
      'description': 'Plain text format',
      'extension': '.txt',
      'color': AppTheme.successColor,
    },
    {
      'format': 'CSV',
      'icon': 'table_chart',
      'description': 'Spreadsheet format',
      'extension': '.csv',
      'color': AppTheme.warningColor,
    },
    {
      'format': 'PDF',
      'icon': 'picture_as_pdf',
      'description': 'PDF with annotations',
      'extension': '.pdf',
      'color': AppTheme.errorColor,
    },
  ];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: 70.h,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 0.5.h,
                  margin: EdgeInsets.symmetric(vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              _buildHeader(),

              // Export statistics
              _buildExportStats(),

              // Format selection
              Expanded(
                child: _buildFormatSelection(),
              ),

              // Export button
              _buildExportButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              gradient: AppTheme.gradientDecoration().gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomIconWidget(
              iconName: 'file_download',
              size: 6.w,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Annotations',
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Choose format and download',
                  style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onClose();
            },
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CustomIconWidget(
                iconName: 'close',
                size: 5.w,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportStats() {
    final highlightCount =
        widget.annotations.where((a) => a['type'] == 'highlight').length;
    final noteCount =
        widget.annotations.where((a) => a['type'] == 'note').length;
    final drawingCount =
        widget.annotations.where((a) => a['type'] == 'draw').length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'description',
                size: 5.w,
                color: AppTheme.accentColor,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  widget.documentTitle,
                  style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildStatItem(
                icon: 'format_color_fill',
                count: highlightCount,
                label: 'Highlights',
                color: AppTheme.warningColor,
              ),
              SizedBox(width: 4.w),
              _buildStatItem(
                icon: 'note_add',
                count: noteCount,
                label: 'Notes',
                color: AppTheme.accentColor,
              ),
              SizedBox(width: 4.w),
              _buildStatItem(
                icon: 'brush',
                count: drawingCount,
                label: 'Drawings',
                color: AppTheme.successColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          CustomIconWidget(
            iconName: icon,
            size: 5.w,
            color: color,
          ),
          SizedBox(height: 0.5.h),
          Text(
            count.toString(),
            style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Export Format',
            style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView.separated(
              itemCount: _exportFormats.length,
              separatorBuilder: (context, index) => SizedBox(height: 1.h),
              itemBuilder: (context, index) {
                final format = _exportFormats[index];
                final isSelected = _selectedFormat == format['format'];

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedFormat = format['format'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? format['color'].withValues(alpha: 0.1)
                          : AppTheme.primaryDark.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? format['color'].withValues(alpha: 0.5)
                            : AppTheme.textSecondary.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            color: format['color'].withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CustomIconWidget(
                            iconName: format['icon'],
                            size: 6.w,
                            color: format['color'],
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${format['format']} Format',
                                style: AppTheme.darkTheme.textTheme.labelMedium
                                    ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                format['description'],
                                style: AppTheme.darkTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          CustomIconWidget(
                            iconName: 'check_circle',
                            size: 6.w,
                            color: format['color'],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: _isExporting ? null : _exportAnnotations,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 6.h,
          decoration: _isExporting
              ? BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                )
              : AppTheme.gradientDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isExporting) ...[
                SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.textPrimary),
                  ),
                ),
                SizedBox(width: 3.w),
                Text(
                  'Exporting...',
                  style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                CustomIconWidget(
                  iconName: 'file_download',
                  size: 5.w,
                  color: AppTheme.textPrimary,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Export as $_selectedFormat',
                  style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportAnnotations() async {
    setState(() {
      _isExporting = true;
    });

    try {
      HapticFeedback.mediumImpact();

      String content = '';
      String filename = '';

      switch (_selectedFormat) {
        case 'JSON':
          content = _generateJsonExport();
          filename = '${widget.documentTitle}_annotations.json';
          break;
        case 'TXT':
          content = _generateTextExport();
          filename = '${widget.documentTitle}_annotations.txt';
          break;
        case 'CSV':
          content = _generateCsvExport();
          filename = '${widget.documentTitle}_annotations.csv';
          break;
        case 'PDF':
          content = _generatePdfExport();
          filename = '${widget.documentTitle}_annotations.pdf';
          break;
      }

      await _downloadFile(content, filename);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Annotations exported successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      widget.onClose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _downloadFile(String content, String filename) async {
    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
    }
  }

  String _generateJsonExport() {
    final exportData = {
      'document': widget.documentTitle,
      'exportDate': DateTime.now().toIso8601String(),
      'totalAnnotations': widget.annotations.length,
      'annotations': widget.annotations
          .map((annotation) => {
                'id': annotation['id'],
                'type': annotation['type'],
                'content': annotation['content'],
                'page': annotation['page'],
                'timestamp':
                    (annotation['timestamp'] as DateTime).toIso8601String(),
                'color': annotation['color']?.toString(),
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  String _generateTextExport() {
    final buffer = StringBuffer();
    buffer.writeln('Annotations for: ${widget.documentTitle}');
    buffer.writeln('Exported on: ${DateTime.now().toString()}');
    buffer.writeln('Total annotations: ${widget.annotations.length}');
    buffer.writeln('${'=' * 50}');
    buffer.writeln();

    for (final annotation in widget.annotations) {
      buffer.writeln('Type: ${annotation['type']}');
      buffer.writeln('Page: ${annotation['page']}');
      buffer.writeln('Date: ${annotation['timestamp']}');
      if (annotation['content'] != null && annotation['content'].isNotEmpty) {
        buffer.writeln('Content: ${annotation['content']}');
      }
      buffer.writeln('-' * 30);
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _generateCsvExport() {
    final buffer = StringBuffer();
    buffer.writeln('Type,Page,Content,Timestamp');

    for (final annotation in widget.annotations) {
      final content =
          (annotation['content'] as String? ?? '').replaceAll('"', '""');
      buffer.writeln(
          '"${annotation['type']}","${annotation['page']}","$content","${annotation['timestamp']}"');
    }

    return buffer.toString();
  }

  String _generatePdfExport() {
    // For PDF export, we'll generate a text-based representation
    // In a real implementation, you'd use a PDF generation library
    return _generateTextExport();
  }
}

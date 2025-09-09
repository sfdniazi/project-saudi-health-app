import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../core/app_theme.dart';
import '../providers/privacy_provider.dart';

/// ✅ Data Export Card - Interface for exporting user data per PDPL requirements
class DataExportCard extends StatefulWidget {
  const DataExportCard({super.key});

  @override
  State<DataExportCard> createState() => _DataExportCardState();
}

class _DataExportCardState extends State<DataExportCard> {
  bool _isExporting = false;
  String? _lastExportDate;

  @override
  void initState() {
    super.initState();
    _loadLastExportDate();
  }

  Future<void> _loadLastExportDate() async {
    // This would load the last export date from shared preferences or settings
    // For now, we'll just set it as a demo
    setState(() {
      _lastExportDate = null; // No previous exports
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrivacyProvider>(
      builder: (context, privacyProvider, _) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.download_outlined,
                        color: AppTheme.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Export Your Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                const Text(
                  'Download a copy of all your personal data in a portable format. This includes your profile, activity data, nutrition logs, and privacy settings.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Export status and information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      _buildInfoRow(Icons.format_list_bulleted, 'Format', 'JSON (machine-readable)'),
                      const SizedBox(height: 6),
                      
                      _buildInfoRow(Icons.security, 'Privacy', 'Sensitive data anonymized'),
                      const SizedBox(height: 6),
                      
                      _buildInfoRow(
                        Icons.access_time,
                        'Last Export',
                        _lastExportDate ?? 'Never',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Data categories to be included
                const Text(
                  'Data Categories Included:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCategoryChip('Profile Data'),
                    _buildCategoryChip('Health Metrics'),
                    _buildCategoryChip('Activity History'),
                    _buildCategoryChip('Nutrition Logs'),
                    _buildCategoryChip('Consent Records'),
                    _buildCategoryChip('Privacy Settings'),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Export options
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isExporting || privacyProvider.isExportingData
                            ? null
                            : _showExportPreview,
                        icon: const Icon(Icons.preview),
                        label: const Text('Preview Export'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isExporting || privacyProvider.isExportingData
                            ? null
                            : _exportData,
                        icon: _isExporting || privacyProvider.isExportingData
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          _isExporting || privacyProvider.isExportingData
                              ? 'Exporting...'
                              : 'Export Data',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (_isExporting || privacyProvider.isExportingData) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _showExportPreview() async {
    setState(() => _isExporting = true);
    
    try {
      final privacyProvider = context.read<PrivacyProvider>();
      final exportData = await privacyProvider.exportUserData();
      
      if (exportData != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => _ExportPreviewDialog(exportData: exportData),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate preview: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      final privacyProvider = context.read<PrivacyProvider>();
      final exportData = await privacyProvider.exportUserData();
      
      if (exportData != null) {
        final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
        
        // Copy to clipboard as a fallback
        await Clipboard.setData(ClipboardData(text: jsonString));
        
        setState(() {
          _lastExportDate = DateTime.now().toString().substring(0, 16);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data exported and copied to clipboard!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          
          // Show export success dialog
          showDialog(
            context: context,
            builder: (context) => _ExportSuccessDialog(
              dataSize: jsonString.length,
              exportDate: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

/// Export Preview Dialog
class _ExportPreviewDialog extends StatelessWidget {
  final Map<String, dynamic> exportData;

  const _ExportPreviewDialog({required this.exportData});

  @override
  Widget build(BuildContext context) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    final preview = jsonString.length > 2000 
        ? '${jsonString.substring(0, 2000)}...\n\n[Data truncated for preview]'
        : jsonString;
    
    return AlertDialog(
      title: const Text('Export Preview'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Text(
            preview,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: jsonString));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preview copied to clipboard'),
                backgroundColor: AppTheme.primaryGreen,
              ),
            );
          },
          child: const Text('Copy Full Data'),
        ),
      ],
    );
  }
}

/// Export Success Dialog
class _ExportSuccessDialog extends StatelessWidget {
  final int dataSize;
  final DateTime exportDate;

  const _ExportSuccessDialog({
    required this.dataSize,
    required this.exportDate,
  });

  @override
  Widget build(BuildContext context) {
    final sizeKB = (dataSize / 1024).toStringAsFixed(1);
    
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.primaryGreen),
          SizedBox(width: 8),
          Text('Export Complete'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your data has been successfully exported and copied to your clipboard.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Details:',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Size: ${sizeKB}KB', style: const TextStyle(fontSize: 12)),
                Text('Date: ${exportDate.toString().substring(0, 16)}', style: const TextStyle(fontSize: 12)),
                Text('Format: JSON', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          const Text(
            'You can now paste this data into a text file for safekeeping or import into other applications.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

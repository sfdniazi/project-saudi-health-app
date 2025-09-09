import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/audit_logger.dart';
import '../providers/privacy_provider.dart';

/// ✅ Audit Trail Card - Display data processing audit trail for transparency
class AuditTrailCard extends StatefulWidget {
  const AuditTrailCard({super.key});

  @override
  State<AuditTrailCard> createState() => _AuditTrailCardState();
}

class _AuditTrailCardState extends State<AuditTrailCard> {
  Map<String, dynamic>? _auditReport;
  bool _isLoading = false;
  LogCategory? _selectedCategory;
  final List<LogCategory> _categories = LogCategory.values;

  @override
  void initState() {
    super.initState();
    _loadAuditTrail();
  }

  Future<void> _loadAuditTrail() async {
    setState(() => _isLoading = true);
    
    try {
      final privacyProvider = context.read<PrivacyProvider>();
      final report = await privacyProvider.getAuditReport(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        category: _selectedCategory,
      );
      
      setState(() {
        _auditReport = report;
      });
    } catch (e) {
      debugPrint('Failed to load audit trail: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Icons.timeline,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Audit Trail',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadAuditTrail,
                  icon: const Icon(Icons.refresh),
                  color: AppTheme.primaryGreen,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'View a complete history of how your data has been processed, accessed, and modified. This audit trail ensures transparency and accountability.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Filter controls
            Row(
              children: [
                const Text(
                  'Filter by category:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<LogCategory?>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._categories.map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(_formatCategoryName(category)),
                      )).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _loadAuditTrail();
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading) ...[
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
                ),
              ),
            ] else if (_auditReport != null) ...[
              _buildAuditSummary(),
              const SizedBox(height: 16),
              _buildAuditEvents(),
            ] else ...[
              const Center(
                child: Text(
                  'No audit data available',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuditSummary() {
    if (_auditReport == null) return const SizedBox.shrink();
    
    final summary = _auditReport!['summary'] as Map<String, dynamic>?;
    if (summary == null) return const SizedBox.shrink();
    
    return Container(
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
            'Last 30 Days Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Events',
                  summary['totalEvents']?.toString() ?? '0',
                  Icons.event,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Categories',
                  (summary['categoryBreakdown'] as Map?)?.length?.toString() ?? '0',
                  Icons.category,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (summary['categoryBreakdown'] != null) ...[
            const Text(
              'By Category:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (summary['categoryBreakdown'] as Map<String, dynamic>)
                  .entries
                  .map((entry) => _buildCategoryChip(entry.key, entry.value))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '${_formatCategoryName(_parseCategoryFromString(category))}: $count',
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAuditEvents() {
    if (_auditReport == null) return const SizedBox.shrink();
    
    final events = _auditReport!['events'] as List<dynamic>?;
    if (events == null || events.isEmpty) {
      return const Text(
        'No events found for the selected period',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Events',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        
        SizedBox(
          height: 300, // Fixed height for scrollable list
          child: ListView.builder(
            itemCount: events.length > 20 ? 20 : events.length,
            itemBuilder: (context, index) {
              final event = events[index] as Map<String, dynamic>;
              return _buildEventItem(event);
            },
          ),
        ),
        
        if (events.length > 20) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                // Show full event list dialog
                _showFullEventsList(events);
              },
              child: Text('View all ${events.length} events'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final category = event['category'] as String? ?? 'unknown';
    final severity = event['severity'] as String? ?? 'info';
    final eventName = event['event'] as String? ?? 'Unknown Event';
    final timestamp = event['timestamp'];
    
    DateTime? eventTime;
    if (timestamp != null) {
      try {
        if (timestamp is String) {
          eventTime = DateTime.parse(timestamp);
        }
      } catch (e) {
        // Handle timestamp parsing errors
      }
    }
    
    final severityColor = _getSeverityColor(severity);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        eventName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCategoryName(_parseCategoryFromString(category)),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (eventTime != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(eventTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullEventsList(List<dynamic> events) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'All Audit Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index] as Map<String, dynamic>;
                    return _buildEventItem(event);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCategoryName(LogCategory category) {
    switch (category) {
      case LogCategory.dataAccess:
        return 'Data Access';
      case LogCategory.dataModification:
        return 'Data Modification';
      case LogCategory.authentication:
        return 'Authentication';
      case LogCategory.authorization:
        return 'Authorization';
      case LogCategory.consent:
        return 'Consent';
      case LogCategory.security:
        return 'Security';
      case LogCategory.compliance:
        return 'Compliance';
      case LogCategory.system:
        return 'System';
    }
  }

  LogCategory _parseCategoryFromString(String categoryString) {
    for (final category in LogCategory.values) {
      if (category.toString() == categoryString) {
        return category;
      }
    }
    return LogCategory.system;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'error':
        return Colors.orange;
      case 'warning':
        return Colors.amber;
      case 'info':
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'dataAccess':
        return Icons.visibility;
      case 'dataModification':
        return Icons.edit;
      case 'authentication':
        return Icons.login;
      case 'authorization':
        return Icons.security;
      case 'consent':
        return Icons.check_circle;
      case 'security':
        return Icons.shield;
      case 'compliance':
        return Icons.policy;
      case 'system':
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

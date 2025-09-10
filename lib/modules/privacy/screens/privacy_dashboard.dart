import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../../core/app_theme.dart';
import '../../../core/pdpl_data_controller.dart';
import '../providers/privacy_provider.dart';
import '../widgets/consent_management_card.dart';
import '../widgets/data_export_card.dart';
import '../widgets/privacy_settings_card.dart';
import '../widgets/audit_trail_card.dart';

/// ✅ Privacy Dashboard - Central hub for all privacy and PDPL compliance features
class PrivacyDashboard extends StatefulWidget {
  const PrivacyDashboard({super.key});

  @override
  State<PrivacyDashboard> createState() => _PrivacyDashboardState();
}

class _PrivacyDashboardState extends State<PrivacyDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializePrivacyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializePrivacyData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      await context.read<PrivacyProvider>().loadPrivacyData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load privacy data: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Privacy & Data Protection',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.assignment_turned_in), text: 'Consent'),
            Tab(icon: Icon(Icons.settings_applications), text: 'Settings'),
            Tab(icon: Icon(Icons.download), text: 'Data'),
            Tab(icon: Icon(Icons.history), text: 'Audit'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConsentTab(),
                _buildSettingsTab(),
                _buildDataTab(),
                _buildAuditTab(),
              ],
            ),
    );
  }

  Widget _buildConsentTab() {
    return Consumer<PrivacyProvider>(
      builder: (context, privacyProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Consent Management',
                'Control how your data is processed',
                Icons.verified_user,
              ),
              
              const SizedBox(height: 16),
              
              // Consent overview card
              Card(
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
                              Icons.shield_outlined,
                              color: AppTheme.primaryGreen,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Your Consent Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (privacyProvider.consentRecords.isNotEmpty) ...[
                        ...privacyProvider.consentRecords
                            .where((record) => !record.isWithdrawn)
                            .map((record) => _buildConsentStatusItem(record))
                            .toList(),
                      ] else ...[
                        const Text(
                          'No consent records found. Grant consent to start using personalized features.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Consent management cards for each data category
              const ConsentManagementCard(),
              
              const SizedBox(height: 20),
              
              _buildConsentHistory(privacyProvider.consentRecords),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Privacy Settings',
            'Configure your privacy preferences',
            Icons.settings_outlined,
          ),
          
          const SizedBox(height: 16),
          
          const PrivacySettingsCard(),
          
          const SizedBox(height: 20),
          
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Data Management',
            'Export or delete your personal data',
            Icons.cloud_download_outlined,
          ),
          
          const SizedBox(height: 16),
          
          const DataExportCard(),
          
          const SizedBox(height: 20),
          
          _buildDataDeletionCard(),
          
          const SizedBox(height: 20),
          
          _buildDataInsightsCard(),
        ],
      ),
    );
  }

  Widget _buildAuditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Audit Trail',
            'View your data processing history',
            Icons.history_outlined,
          ),
          
          const SizedBox(height: 16),
          
          const AuditTrailCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryGreen,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsentStatusItem(dynamic record) {
    final category = record.category.toString().split('.').last;
    final purpose = record.purpose.toString().split('.').last;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: record.granted 
            ? AppTheme.primaryGreen.withValues(alpha: 0.1)
            : AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: record.granted 
              ? AppTheme.primaryGreen.withValues(alpha: 0.3)
              : AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            record.granted ? Icons.check_circle : Icons.cancel,
            color: record.granted ? AppTheme.primaryGreen : AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCategoryName(category),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Purpose: ${_formatPurposeName(purpose)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            record.granted ? 'Granted' : 'Denied',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: record.granted ? AppTheme.primaryGreen : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentHistory(List<dynamic> consentRecords) {
    if (consentRecords.isEmpty) {
      return const SizedBox.shrink();
    }

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
            const Text(
              'Consent History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...consentRecords.take(5).map((record) => 
              _buildConsentHistoryItem(record)
            ).toList(),
            if (consentRecords.length > 5)
              TextButton(
                onPressed: () {
                  // Show full consent history
                },
                child: const Text('View Full History'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentHistoryItem(dynamic record) {
    final category = record.category.toString().split('.').last;
    final purpose = record.purpose.toString().split('.').last;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            record.isWithdrawn 
                ? Icons.remove_circle_outline
                : (record.granted ? Icons.check_circle_outline : Icons.cancel_outlined),
            size: 16,
            color: record.isWithdrawn 
                ? AppTheme.textSecondary
                : (record.granted ? AppTheme.primaryGreen : AppTheme.errorColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_formatCategoryName(category)} - ${_formatPurposeName(purpose)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            _formatDate(record.timestamp),
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildQuickActionButton(
              'Review All Consents',
              'Check and update your consent preferences',
              Icons.assignment_turned_in,
              () => _tabController.animateTo(0),
            ),
            
            const SizedBox(height: 12),
            
            _buildQuickActionButton(
              'Generate Compliance Report',
              'Download your privacy compliance summary',
              Icons.assessment,
              _generateComplianceReport,
            ),
            
            const SizedBox(height: 12),
            
            _buildQuickActionButton(
              'Contact Data Protection Officer',
              'Get help with privacy-related questions',
              Icons.support_agent,
              _contactDPO,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDeletionCard() {
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
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: AppTheme.errorColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Delete My Data',
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
              'Permanently delete all your personal data from our systems. This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will permanently delete your account and all associated data. You will not be able to recover this information.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _requestDataDeletion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Request Data Deletion'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataInsightsCard() {
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
                const Text(
                  'Data Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                _buildDataInsightItem(
                  'Account Created',
                  privacyProvider.accountCreationDate != null 
                      ? _formatDate(privacyProvider.accountCreationDate!)
                      : 'Unknown',
                  Icons.account_circle,
                ),
                
                const SizedBox(height: 12),
                
                _buildDataInsightItem(
                  'Data Categories',
                  '${privacyProvider.dataCategories.length} types',
                  Icons.category,
                ),
                
                const SizedBox(height: 12),
                
                _buildDataInsightItem(
                  'Consent Records',
                  '${privacyProvider.consentRecords.length} entries',
                  Icons.verified_user,
                ),
                
                const SizedBox(height: 12),
                
                _buildDataInsightItem(
                  'Last Privacy Update',
                  privacyProvider.lastPrivacyUpdate != null
                      ? _formatDate(privacyProvider.lastPrivacyUpdate!)
                      : 'Never updated',
                  Icons.update,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataInsightItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGreen),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatCategoryName(String category) {
    switch (category) {
      case 'personalInfo': return 'Personal Information';
      case 'healthMetrics': return 'Health Metrics';
      case 'activityData': return 'Activity Data';
      case 'nutritionData': return 'Nutrition Data';
      case 'locationData': return 'Location Data';
      case 'deviceData': return 'Device Data';
      default: return category;
    }
  }

  String _formatPurposeName(String purpose) {
    switch (purpose) {
      case 'essential': return 'Essential Functions';
      case 'analytics': return 'Analytics';
      case 'personalization': return 'Personalization';
      case 'marketing': return 'Marketing';
      case 'research': return 'Research';
      default: return purpose;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _generateComplianceReport() async {
    try {
      setState(() => _isLoading = true);
      
      final report = await PDPLDataController.generateComplianceReport();
      final jsonString = const JsonEncoder.withIndent('  ').convert(report);
      
      await Clipboard.setData(ClipboardData(text: jsonString));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compliance report copied to clipboard'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _contactDPO() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Data Protection Officer'),
        content: const Text(
          'For privacy-related questions or concerns, please contact our Data Protection Officer at:\n\ndpo@nabdalhayah.com\n\nWe will respond to your inquiry within 72 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestDataDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Data Deletion'),
        content: const Text(
          'Are you sure you want to permanently delete all your data? This action cannot be undone and you will lose access to your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete My Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await PDPLDataController.deleteAllUserData();
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/start',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete data: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}

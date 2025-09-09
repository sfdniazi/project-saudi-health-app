import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/pdpl_data_controller.dart';
import '../providers/privacy_provider.dart';

/// ✅ Consent Management Card - Interface for managing granular consent preferences
class ConsentManagementCard extends StatefulWidget {
  const ConsentManagementCard({super.key});

  @override
  State<ConsentManagementCard> createState() => _ConsentManagementCardState();
}

class _ConsentManagementCardState extends State<ConsentManagementCard> {
  final Map<String, Map<String, bool>> _consentMatrix = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConsentMatrix();
  }

  Future<void> _loadConsentMatrix() async {
    setState(() => _isLoading = true);
    
    final privacyProvider = context.read<PrivacyProvider>();
    final matrix = privacyProvider.getConsentMatrix();
    
    setState(() {
      _consentMatrix.clear();
      _consentMatrix.addAll(matrix);
      _isLoading = false;
    });
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
                    Icons.tune,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Consent Preferences',
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
            
            const Text(
              'Control how your data is used for different purposes. You can change these preferences at any time.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (_isLoading) ...[
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
                ),
              ),
            ] else ...[
              ...DataCategory.values.map((category) =>
                _buildCategorySection(category)
              ).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(DataCategory category) {
    final categoryName = _formatCategoryName(category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ExpansionTile(
        title: Text(
          categoryName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          _getCategoryDescription(category),
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: DataProcessingPurpose.values
                  .map((purpose) => _buildPurposeToggle(category, purpose))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeToggle(
    DataCategory category,
    DataProcessingPurpose purpose,
  ) {
    final purposeName = _formatPurposeName(purpose);
    final currentValue = _consentMatrix[category.toString()]?[purpose.toString()] ?? false;
    final isEssential = purpose == DataProcessingPurpose.essential;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purposeName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isEssential ? AppTheme.textSecondary : AppTheme.textPrimary,
                  ),
                ),
                Text(
                  _getPurposeDescription(purpose),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (isEssential) ...[
                  const Text(
                    'Required for app functionality',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryGreen,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isEssential ? true : currentValue,
            onChanged: isEssential ? null : (value) => _toggleConsent(category, purpose, value),
            activeColor: AppTheme.primaryGreen,
            inactiveThumbColor: AppTheme.textLight,
            inactiveTrackColor: AppTheme.borderColor,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleConsent(
    DataCategory category,
    DataProcessingPurpose purpose,
    bool granted,
  ) async {
    final privacyProvider = context.read<PrivacyProvider>();
    
    bool success;
    if (granted) {
      success = await privacyProvider.recordConsent(
        category: category,
        purpose: purpose,
        granted: true,
      );
    } else {
      success = await privacyProvider.withdrawConsent(
        category: category,
        purpose: purpose,
      );
    }
    
    if (success) {
      setState(() {
        _consentMatrix[category.toString()]?[purpose.toString()] = granted;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              granted 
                  ? 'Consent granted for ${_formatCategoryName(category)}'
                  : 'Consent withdrawn for ${_formatCategoryName(category)}',
            ),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(privacyProvider.lastError ?? 'Failed to update consent'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatCategoryName(DataCategory category) {
    switch (category) {
      case DataCategory.personalInfo:
        return 'Personal Information';
      case DataCategory.healthMetrics:
        return 'Health Metrics';
      case DataCategory.activityData:
        return 'Activity Data';
      case DataCategory.nutritionData:
        return 'Nutrition Data';
      case DataCategory.locationData:
        return 'Location Data';
      case DataCategory.deviceData:
        return 'Device Data';
    }
  }

  String _getCategoryDescription(DataCategory category) {
    switch (category) {
      case DataCategory.personalInfo:
        return 'Name, email, age, gender, and contact information';
      case DataCategory.healthMetrics:
        return 'Height, weight, BMI, and health goals';
      case DataCategory.activityData:
        return 'Steps, exercise, calories burned, and activity patterns';
      case DataCategory.nutritionData:
        return 'Food logs, dietary preferences, and nutrition tracking';
      case DataCategory.locationData:
        return 'GPS location for activity tracking and local recommendations';
      case DataCategory.deviceData:
        return 'Device information, app usage, and technical diagnostics';
    }
  }

  String _formatPurposeName(DataProcessingPurpose purpose) {
    switch (purpose) {
      case DataProcessingPurpose.essential:
        return 'Essential Functions';
      case DataProcessingPurpose.analytics:
        return 'Analytics & Insights';
      case DataProcessingPurpose.personalization:
        return 'Personalization';
      case DataProcessingPurpose.marketing:
        return 'Marketing Communications';
      case DataProcessingPurpose.research:
        return 'Research & Development';
    }
  }

  String _getPurposeDescription(DataProcessingPurpose purpose) {
    switch (purpose) {
      case DataProcessingPurpose.essential:
        return 'Core app functionality and security';
      case DataProcessingPurpose.analytics:
        return 'Understand app usage and improve performance';
      case DataProcessingPurpose.personalization:
        return 'Customize recommendations and user experience';
      case DataProcessingPurpose.marketing:
        return 'Send relevant offers and product updates';
      case DataProcessingPurpose.research:
        return 'Anonymized research to improve health outcomes';
    }
  }
}

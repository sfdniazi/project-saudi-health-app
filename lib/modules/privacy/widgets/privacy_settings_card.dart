import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../providers/privacy_provider.dart';

/// ✅ Privacy Settings Card - Configuration for privacy preferences
class PrivacySettingsCard extends StatelessWidget {
  const PrivacySettingsCard({super.key});

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
                        Icons.security,
                        color: AppTheme.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Privacy Preferences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                _buildSettingToggle(
                  context,
                  'Allow Analytics',
                  'Help improve the app with usage analytics',
                  Icons.analytics,
                  privacyProvider.getPrivacySetting<bool>('allowAnalytics', false),
                  (value) => _updateSetting(context, 'allowAnalytics', value),
                ),
                
                const SizedBox(height: 12),
                
                _buildSettingToggle(
                  context,
                  'Personalization',
                  'Enable personalized recommendations',
                  Icons.person,
                  privacyProvider.getPrivacySetting<bool>('allowPersonalization', true),
                  (value) => _updateSetting(context, 'allowPersonalization', value),
                ),
                
                const SizedBox(height: 12),
                
                _buildSettingToggle(
                  context,
                  'Marketing Communications',
                  'Receive promotional emails and notifications',
                  Icons.email,
                  privacyProvider.getPrivacySetting<bool>('allowMarketingCommunications', false),
                  (value) => _updateSetting(context, 'allowMarketingCommunications', value),
                ),
                
                const SizedBox(height: 12),
                
                _buildSettingToggle(
                  context,
                  'Share Anonymized Data',
                  'Contribute to research with anonymized data',
                  Icons.share,
                  privacyProvider.getPrivacySetting<bool>('shareAnonymizedData', false),
                  (value) => _updateSetting(context, 'shareAnonymizedData', value),
                ),
                
                const SizedBox(height: 20),
                
                const Divider(),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Data Retention',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                _buildRetentionSetting(context, privacyProvider),
                
                const SizedBox(height: 16),
                
                _buildAutoDeleteToggle(context, privacyProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingToggle(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    bool currentValue,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: currentValue,
          onChanged: onChanged,
          activeColor: AppTheme.primaryGreen,
          inactiveThumbColor: AppTheme.textLight,
          inactiveTrackColor: AppTheme.borderColor,
        ),
      ],
    );
  }

  Widget _buildRetentionSetting(BuildContext context, PrivacyProvider privacyProvider) {
    final currentPeriod = privacyProvider.getPrivacySetting<int>('dataRetentionPeriod', 1095);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Retention Period',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How long to keep your data after account deletion',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: currentPeriod,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 365, child: Text('1 year')),
            DropdownMenuItem(value: 1095, child: Text('3 years (default)')),
            DropdownMenuItem(value: 1825, child: Text('5 years')),
            DropdownMenuItem(value: 2555, child: Text('7 years')),
          ],
          onChanged: (value) {
            if (value != null) {
              _updateSetting(context, 'dataRetentionPeriod', value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildAutoDeleteToggle(BuildContext context, PrivacyProvider privacyProvider) {
    final autoDelete = privacyProvider.getPrivacySetting<bool>('autoDeleteInactive', true);
    final inactivityPeriod = privacyProvider.getPrivacySetting<int>('inactivityPeriod', 730);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_delete, size: 20, color: AppTheme.primaryGreen),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Auto-delete inactive data',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Switch(
              value: autoDelete,
              onChanged: (value) => _updateSetting(context, 'autoDeleteInactive', value),
              activeColor: AppTheme.primaryGreen,
            ),
          ],
        ),
        if (autoDelete) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inactivity period before deletion',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: inactivityPeriod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 365, child: Text('1 year')),
                    DropdownMenuItem(value: 730, child: Text('2 years (default)')),
                    DropdownMenuItem(value: 1095, child: Text('3 years')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updateSetting(context, 'inactivityPeriod', value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _updateSetting(BuildContext context, String key, dynamic value) async {
    final privacyProvider = context.read<PrivacyProvider>();
    final success = await privacyProvider.updatePrivacySettings({key: value});
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(privacyProvider.lastError ?? 'Failed to update setting'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

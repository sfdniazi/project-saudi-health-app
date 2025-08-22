import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// ✅ PDPL compliance manager for handling user consent
class ConsentManager {
  static const String _consentKey = 'user_consent_given';
  static const String _consentDateKey = 'user_consent_date';
  
  /// Check if user has given consent
  static Future<bool> hasUserConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  /// Set user consent
  static Future<void> setUserConsent(bool hasConsent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, hasConsent);
    
    if (hasConsent) {
      await prefs.setString(_consentDateKey, DateTime.now().toIso8601String());
    }
  }

  /// Get consent date
  static Future<DateTime?> getConsentDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_consentDateKey);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  /// Withdraw consent
  static Future<void> withdrawConsent() async {
    await setUserConsent(false);
  }

  /// Show consent popup dialog
  static Future<bool> showConsentDialog(BuildContext context) async {
    if (!context.mounted) return false;

    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const ConsentDialog();
      },
    );

    return result ?? false;
  }

  /// Show consent settings dialog
  static void showConsentSettings(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConsentSettingsDialog();
      },
    );
  }
}

/// ✅ PDPL Consent Dialog Widget
class ConsentDialog extends StatefulWidget {
  const ConsentDialog({super.key});

  @override
  State<ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<ConsentDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
    
    // Auto-scroll to bottom after a delay to ensure content is visible
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _checkScrollPosition() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 50) {
      setState(() {
        _hasScrolledToBottom = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.privacy_tip,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Privacy & Data Protection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Nabd Al-Hayah! We value your privacy and are committed to protecting your personal data.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildSectionTitle('Data We Collect'),
                    _buildBulletPoint('Personal information: Name, email, age, gender'),
                    _buildBulletPoint('Health data: Height, weight, dietary preferences'),
                    _buildBulletPoint('Usage data: App activity, nutrition logs'),
                    _buildBulletPoint('Device data: Device type, operating system'),
                    
                    const SizedBox(height: 16),
                    
                    _buildSectionTitle('How We Use Your Data'),
                    _buildBulletPoint('Provide personalized nutrition recommendations'),
                    _buildBulletPoint('Track your health and fitness progress'),
                    _buildBulletPoint('Improve app functionality and user experience'),
                    _buildBulletPoint('Send relevant notifications and updates'),
                    
                    const SizedBox(height: 16),
                    
                    _buildSectionTitle('Data Protection'),
                    _buildBulletPoint('Your data is encrypted and securely stored'),
                    _buildBulletPoint('We never sell your personal information'),
                    _buildBulletPoint('You can access, modify, or delete your data anytime'),
                    _buildBulletPoint('We comply with PDPL and international privacy laws'),
                    
                    const SizedBox(height: 16),
                    
                    _buildSectionTitle('Your Rights'),
                    _buildBulletPoint('Right to access your personal data'),
                    _buildBulletPoint('Right to correct or update information'),
                    _buildBulletPoint('Right to delete your data'),
                    _buildBulletPoint('Right to withdraw consent at any time'),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'By accepting, you agree to our data collection and processing practices outlined above. You can change your consent preferences anytime in the app settings.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ConsentManager.setUserConsent(false);
                      Navigator.of(context).pop(false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.textLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _hasScrolledToBottom ? () async {
                      await ConsentManager.setUserConsent(true);
                      Navigator.of(context).pop(true);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _hasScrolledToBottom 
                          ? 'Accept & Continue'
                          : 'Please read all terms',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Consent Settings Dialog
class ConsentSettingsDialog extends StatefulWidget {
  @override
  State<ConsentSettingsDialog> createState() => _ConsentSettingsDialogState();
}

class _ConsentSettingsDialogState extends State<ConsentSettingsDialog> {
  bool _hasConsent = false;
  DateTime? _consentDate;

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
  }

  Future<void> _loadConsentStatus() async {
    final hasConsent = await ConsentManager.hasUserConsent();
    final consentDate = await ConsentManager.getConsentDate();
    
    setState(() {
      _hasConsent = hasConsent;
      _consentDate = consentDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.privacy_tip, color: AppTheme.primaryGreen),
          SizedBox(width: 12),
          Text('Privacy Consent'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasConsent ? Icons.check_circle : Icons.cancel,
                color: _hasConsent ? AppTheme.primaryGreen : AppTheme.accentOrange,
              ),
              const SizedBox(width: 8),
              Text(
                _hasConsent ? 'Consent Given' : 'Consent Not Given',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _hasConsent ? AppTheme.primaryGreen : AppTheme.accentOrange,
                ),
              ),
            ],
          ),
          
          if (_consentDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Date: ${_consentDate!.day}/${_consentDate!.month}/${_consentDate!.year}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          const Text(
            'You can update your privacy consent preferences at any time.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        
        if (_hasConsent)
          OutlinedButton(
            onPressed: () async {
              await ConsentManager.withdrawConsent();
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Consent withdrawn. Your data usage preferences have been updated.'),
                  backgroundColor: AppTheme.accentOrange,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentOrange,
            ),
            child: const Text('Withdraw Consent'),
          )
        else
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final granted = await ConsentManager.showConsentDialog(context);
              
              if (granted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Consent granted. Thank you!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Give Consent'),
          ),
      ],
    );
  }
}

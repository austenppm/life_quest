import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/money_provider.dart';
import '../../providers/food_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _reminderTime = '09:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _dailyReminderEnabled = prefs.getBool('dailyReminderEnabled') ?? true;
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      _reminderTime = prefs.getString('reminderTime') ?? '09:00';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('dailyReminderEnabled', _dailyReminderEnabled);
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setString('reminderTime', _reminderTime);
  }

  void _updateNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    _saveSettings();
    if (value) {
      HapticFeedback.lightImpact();
    }
  }

  void _updateDailyReminder(bool value) {
    setState(() => _dailyReminderEnabled = value);
    _saveSettings();
    if (_vibrationEnabled) HapticFeedback.lightImpact();
  }

  void _updateSound(bool value) {
    setState(() => _soundEnabled = value);
    _saveSettings();
    if (_vibrationEnabled) HapticFeedback.lightImpact();
  }

  void _updateVibration(bool value) {
    setState(() => _vibrationEnabled = value);
    _saveSettings();
    if (value) HapticFeedback.mediumImpact();
  }

  Future<void> _selectReminderTime() async {
    final parts = _reminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        _reminderTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: 'Notifications'),
              _SettingsTile(
                icon: Icons.notifications,
                title: 'Push Notifications',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: _updateNotifications,
                ),
              ),
              _SettingsTile(
                icon: Icons.alarm,
                title: 'Daily Reminder',
                trailing: Switch(
                  value: _dailyReminderEnabled,
                  onChanged: _updateDailyReminder,
                ),
              ),
              _SettingsTile(
                icon: Icons.access_time,
                title: 'Reminder Time',
                subtitle: _reminderTime,
                onTap: _selectReminderTime,
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Sound & Haptics'),
              _SettingsTile(
                icon: Icons.volume_up,
                title: 'Sound Effects',
                trailing: Switch(
                  value: _soundEnabled,
                  onChanged: _updateSound,
                ),
              ),
              _SettingsTile(
                icon: Icons.vibration,
                title: 'Vibration',
                trailing: Switch(
                  value: _vibrationEnabled,
                  onChanged: _updateVibration,
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Preferences'),
              _CurrencyTile(),
              _NutritionGoalsTile(),
              const SizedBox(height: 24),
              _SectionTitle(title: 'AI Settings'),
              _AIApiKeysTile(),
              const SizedBox(height: 24),
              _SectionTitle(title: 'About'),
              _SettingsTile(
                icon: Icons.info,
                title: 'App Version',
                subtitle: '1.0.0',
              ),
              _SettingsTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                onTap: () => _showPrivacyPolicy(context),
              ),
              _SettingsTile(
                icon: Icons.description,
                title: 'Terms of Service',
                onTap: () => _showTermsOfService(context),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Account'),
              _SettingsTile(
                icon: Icons.logout,
                title: 'Sign Out',
                onTap: () => _confirmSignOut(context, ref),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Danger Zone'),
              _SettingsTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                titleColor: AppColors.error,
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Privacy Policy', style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: const Text(_privacyPolicyText, style: TextStyle(height: 1.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Terms of Service', style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: const Text(_termsOfServiceText, style: TextStyle(height: 1.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(firestoreServiceProvider).deleteUserData(
                  ref.read(authStateProvider).value!.uid,
                );
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AIApiKeysTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AIApiKeysTile> createState() => _AIApiKeysTileState();
}

class _AIApiKeysTileState extends ConsumerState<_AIApiKeysTile> {
  String? _geminiKey;
  String? _geminiModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _geminiKey = prefs.getString('gemini_api_key');
      _geminiModel = prefs.getString('gemini_model') ?? 'gemini-2.5-flash';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.smart_toy, color: AppColors.textSecondary),
        title: const Text('AI API Keys'),
        subtitle: Text(
          _isLoading
              ? 'Loading...'
              : _geminiKey != null && _geminiKey!.isNotEmpty
                  ? 'Gemini API configured'
                  : 'Not configured',
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () => _showApiKeySheet(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showApiKeySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ApiKeySheet(
        initialGeminiKey: _geminiKey,
        initialModel: _geminiModel,
        onSave: (geminiKey, model) async {
          final prefs = await SharedPreferences.getInstance();
          if (geminiKey != null && geminiKey.isNotEmpty) {
            await prefs.setString('gemini_api_key', geminiKey);
          } else {
            await prefs.remove('gemini_api_key');
          }
          if (model != null && model.isNotEmpty) {
            await prefs.setString('gemini_model', model);
          }
          // Reinitialize the AI service with the new key and model
          await ref.read(aiServiceProvider).reinitialize();
          setState(() {
            _geminiKey = geminiKey;
            _geminiModel = model;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ref.read(aiServiceProvider).isAvailable
                    ? 'AI service configured with $model!'
                    : 'Settings saved but AI service not available'),
                backgroundColor: ref.read(aiServiceProvider).isAvailable
                    ? AppColors.success
                    : Colors.orange,
              ),
            );
          }
        },
      ),
    );
  }
}

class _ApiKeySheet extends StatefulWidget {
  final String? initialGeminiKey;
  final String? initialModel;
  final Function(String?, String?) onSave;

  const _ApiKeySheet({
    this.initialGeminiKey,
    this.initialModel,
    required this.onSave,
  });

  @override
  State<_ApiKeySheet> createState() => _ApiKeySheetState();
}

class _ApiKeySheetState extends State<_ApiKeySheet> {
  late TextEditingController _geminiController;
  late TextEditingController _customModelController;
  bool _obscureGemini = true;
  String _selectedModel = 'gemini-2.5-flash';
  bool _useCustomModel = false;

  static const _availableModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.5-pro',
    'gemini-3.1-flash-lite-preview',
    'gemini-3-flash-preview',
    'gemini-3.1-pro-preview',
  ];

  @override
  void initState() {
    super.initState();
    _geminiController = TextEditingController(text: widget.initialGeminiKey ?? '');
    final initialModel = widget.initialModel ?? 'gemini-2.5-flash';
    if (_availableModels.contains(initialModel)) {
      _selectedModel = initialModel;
      _useCustomModel = false;
      _customModelController = TextEditingController();
    } else {
      _useCustomModel = true;
      _customModelController = TextEditingController(text: initialModel);
    }
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  String get _currentModel => _useCustomModel ? _customModelController.text.trim() : _selectedModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI Settings', style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure your Gemini API key and model for AI features.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _geminiController,
              obscureText: _obscureGemini,
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIza...',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(_obscureGemini ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureGemini = !_obscureGemini),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                const url = 'https://aistudio.google.com/app/apikey';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Get Gemini API Key'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gemini Model',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // Model selection
            if (!_useCustomModel)
              DropdownButtonFormField<String>(
                value: _selectedModel,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.model_training),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _availableModels.map((model) => DropdownMenuItem(
                  value: model,
                  child: Text(model, style: const TextStyle(fontSize: 14)),
                )).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedModel = value);
                },
              ),
            if (_useCustomModel)
              TextField(
                controller: _customModelController,
                decoration: const InputDecoration(
                  labelText: 'Custom Model Name',
                  hintText: 'e.g., gemini-2.5-flash',
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _useCustomModel,
                  onChanged: (value) => setState(() => _useCustomModel = value ?? false),
                ),
                GestureDetector(
                  onTap: () => setState(() => _useCustomModel = !_useCustomModel),
                  child: const Text('Use custom model name'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final apiKey = _geminiController.text.trim().isEmpty ? null : _geminiController.text.trim();
                  final model = _currentModel.isEmpty ? 'gemini-2.5-flash' : _currentModel;
                  widget.onSave(apiKey, model);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? AppColors.textSecondary),
        title: Text(
          title,
          style: TextStyle(color: titleColor),
        ),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
                : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _CurrencyTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.attach_money, color: AppColors.textSecondary),
        title: const Text('Currency'),
        subtitle: Text('${currency.symbol} ${currency.code}'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () => _showCurrencyPicker(context, ref),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Currency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: Currency.values.length,
                itemBuilder: (context, index) {
                  final currency = Currency.values[index];
                  final isSelected = currency == ref.read(currencyProvider);
                  return ListTile(
                    leading: Text(
                      currency.symbol,
                      style: const TextStyle(fontSize: 20),
                    ),
                    title: Text(currency.code),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      ref.read(currencyProvider.notifier).setCurrency(currency);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionGoalsTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(nutritionGoalsProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.restaurant, color: AppColors.textSecondary),
        title: const Text('Nutrition Goals'),
        subtitle: Text('${goals.calorieGoal} cal/day'),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () => _showNutritionGoalsSheet(context, ref),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showNutritionGoalsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _NutritionGoalsSheet(),
    );
  }
}

class _NutritionGoalsSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NutritionGoalsSheet> createState() => _NutritionGoalsSheetState();
}

class _NutritionGoalsSheetState extends ConsumerState<_NutritionGoalsSheet> {
  late TextEditingController _calorieController;
  late double _proteinPercent;
  late double _carbsPercent;
  late double _fatPercent;

  @override
  void initState() {
    super.initState();
    final goals = ref.read(nutritionGoalsProvider);
    _calorieController = TextEditingController(text: goals.calorieGoal.toString());
    _proteinPercent = goals.proteinPercent;
    _carbsPercent = goals.carbsPercent;
    _fatPercent = goals.fatPercent;
  }

  @override
  void dispose() {
    _calorieController.dispose();
    super.dispose();
  }

  // Calculate grams from current values
  int get _calories => int.tryParse(_calorieController.text) ?? 2000;
  double get _proteinGrams => (_calories * _proteinPercent / 100) / 4;
  double get _carbsGrams => (_calories * _carbsPercent / 100) / 4;
  double get _fatGrams => (_calories * _fatPercent / 100) / 9;

  void _adjustPercentages(String changed, double newValue) {
    setState(() {
      // Ensure total stays at 100%
      final oldTotal = _proteinPercent + _carbsPercent + _fatPercent;
      final diff = newValue - (changed == 'protein' ? _proteinPercent : changed == 'carbs' ? _carbsPercent : _fatPercent);

      if (changed == 'protein') {
        _proteinPercent = newValue;
        // Distribute the difference between carbs and fat proportionally
        final remaining = _carbsPercent + _fatPercent;
        if (remaining > 0) {
          _carbsPercent = (_carbsPercent - diff * _carbsPercent / remaining).clamp(5.0, 90.0);
          _fatPercent = (100 - _proteinPercent - _carbsPercent).clamp(5.0, 90.0);
        }
      } else if (changed == 'carbs') {
        _carbsPercent = newValue;
        final remaining = _proteinPercent + _fatPercent;
        if (remaining > 0) {
          _proteinPercent = (_proteinPercent - diff * _proteinPercent / remaining).clamp(5.0, 90.0);
          _fatPercent = (100 - _proteinPercent - _carbsPercent).clamp(5.0, 90.0);
        }
      } else {
        _fatPercent = newValue;
        final remaining = _proteinPercent + _carbsPercent;
        if (remaining > 0) {
          _proteinPercent = (_proteinPercent - diff * _proteinPercent / remaining).clamp(5.0, 90.0);
          _carbsPercent = (100 - _proteinPercent - _fatPercent).clamp(5.0, 90.0);
        }
      }

      // Normalize to 100%
      final total = _proteinPercent + _carbsPercent + _fatPercent;
      if (total != 100) {
        final factor = 100 / total;
        _proteinPercent *= factor;
        _carbsPercent *= factor;
        _fatPercent *= factor;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nutrition Goals',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Calorie input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_fire_department, color: Color(0xFFFF6B6B), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Daily Calories', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        TextField(
                          controller: _calorieController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            suffixText: 'kcal',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Macro Distribution', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            // Protein slider
            _MacroSlider(
              label: 'Protein',
              percent: _proteinPercent,
              grams: _proteinGrams,
              color: const Color(0xFFFF6B6B),
              icon: Icons.egg,
              onChanged: (v) => _adjustPercentages('protein', v),
            ),
            const SizedBox(height: 16),
            // Carbs slider
            _MacroSlider(
              label: 'Carbohydrates',
              percent: _carbsPercent,
              grams: _carbsGrams,
              color: const Color(0xFF4ECDC4),
              icon: Icons.bakery_dining,
              onChanged: (v) => _adjustPercentages('carbs', v),
            ),
            const SizedBox(height: 16),
            // Fat slider
            _MacroSlider(
              label: 'Fat',
              percent: _fatPercent,
              grams: _fatGrams,
              color: const Color(0xFFFFD93D),
              icon: Icons.water_drop,
              onChanged: (v) => _adjustPercentages('fat', v),
            ),
            const SizedBox(height: 16),
            // Visual breakdown
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Flexible(
                    flex: _proteinPercent.round(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B6B),
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: _carbsPercent.round(),
                    child: Container(color: const Color(0xFF4ECDC4)),
                  ),
                  Flexible(
                    flex: _fatPercent.round(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD93D),
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveGoals,
                child: const Text('Save Goals'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveGoals() {
    final notifier = ref.read(nutritionGoalsProvider.notifier);

    final calories = int.tryParse(_calorieController.text);
    if (calories != null && calories > 0) {
      notifier.setCalorieGoal(calories);
    }

    notifier.setMacroPercentages(
      proteinPercent: _proteinPercent,
      carbsPercent: _carbsPercent,
      fatPercent: _fatPercent,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nutrition goals updated!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _MacroSlider extends StatelessWidget {
  final String label;
  final double percent;
  final double grams;
  final Color color;
  final IconData icon;
  final ValueChanged<double> onChanged;

  const _MacroSlider({
    required this.label,
    required this.percent,
    required this.grams,
    required this.color,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                '${percent.round()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                '(${grams.round()}g)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: percent.clamp(5.0, 90.0),
              min: 5,
              max: 90,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final IconData icon;
  final Color color;

  const _GoalField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    suffixText: suffix,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const String _privacyPolicyText = '''
PRIVACY POLICY

Last updated: March 2026

Life Quest ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.

INFORMATION WE COLLECT

Personal Information:
- Email address (for account creation and authentication)
- Display name (chosen by you)
- Profile information you provide

Usage Data:
- Tasks, quests, and goals you create
- Workout, study, and work logs
- Food and nutrition entries
- Weight tracking data
- Financial transaction records (stored locally and in your account)

HOW WE USE YOUR INFORMATION

We use your information to:
- Provide and maintain the Life Quest service
- Track your progress and calculate XP/stats
- Sync your data across devices
- Improve our AI features (food analysis, task suggestions)
- Send notifications (if enabled)

DATA STORAGE AND SECURITY

- Your data is stored securely using Firebase/Google Cloud services
- We use industry-standard encryption for data transmission
- Your financial data is only visible to you
- AI features may send data to Google's Gemini API for processing

THIRD-PARTY SERVICES

We use the following third-party services:
- Firebase (authentication, database, analytics)
- Google Gemini AI (optional, for AI features)
- Google Calendar API (optional, for calendar sync)

YOUR RIGHTS

You can:
- Access and export your data
- Update or correct your information
- Delete your account and all associated data
- Disable notifications and optional features

CHILDREN'S PRIVACY

Life Quest is not intended for children under 13. We do not knowingly collect data from children under 13.

CHANGES TO THIS POLICY

We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last updated" date.

CONTACT US

If you have questions about this Privacy Policy, please contact us through the app's feedback feature.
''';

const String _termsOfServiceText = '''
TERMS OF SERVICE

Last updated: March 2026

Welcome to Life Quest! By using our application, you agree to these Terms of Service.

ACCEPTANCE OF TERMS

By accessing or using Life Quest, you agree to be bound by these Terms. If you disagree with any part, you may not use the application.

DESCRIPTION OF SERVICE

Life Quest is a gamification app that helps you:
- Track daily tasks and habits
- Set and achieve goals through quests
- Monitor fitness, nutrition, and wellness
- Manage personal finances
- Earn XP and level up your character stats

USER ACCOUNTS

You are responsible for:
- Maintaining the security of your account
- All activities that occur under your account
- Providing accurate information
- Keeping your password confidential

ACCEPTABLE USE

You agree NOT to:
- Use the service for illegal purposes
- Attempt to hack or disrupt the service
- Share your account with others
- Upload malicious content
- Misuse AI features

INTELLECTUAL PROPERTY

- The Life Quest app, design, and content are owned by us
- Your personal data remains yours
- You grant us license to use your data to provide the service

AI FEATURES

- AI features are provided "as is" without guarantees
- Food calorie estimates are approximations
- AI suggestions are not professional advice
- You are responsible for verifying AI-generated information

HEALTH AND FITNESS DISCLAIMER

Life Quest is not a substitute for professional medical advice. Always consult healthcare providers before starting exercise programs or making dietary changes.

FINANCIAL DISCLAIMER

Financial tracking features are for personal organization only. We do not provide financial advice. Consult professionals for financial decisions.

TERMINATION

We may terminate or suspend your account for violations of these Terms. You may delete your account at any time through Settings.

LIMITATION OF LIABILITY

Life Quest is provided "as is" without warranties. We are not liable for:
- Data loss or service interruptions
- Decisions made based on app data
- Third-party service issues
- Inaccuracies in AI features

CHANGES TO TERMS

We may modify these Terms at any time. Continued use after changes constitutes acceptance.

GOVERNING LAW

These Terms are governed by applicable laws. Any disputes will be resolved through appropriate legal channels.

CONTACT

For questions about these Terms, please contact us through the app.

By using Life Quest, you acknowledge that you have read, understood, and agree to these Terms of Service.
''';

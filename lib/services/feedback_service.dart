import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Types of feedback/reports
enum FeedbackType {
  bug('Bug Report', Icons.bug_report, 'Something isn\'t working'),
  feature('Feature Request', Icons.lightbulb, 'Suggest a new feature'),
  improvement('Improvement', Icons.trending_up, 'Make something better'),
  question('Question', Icons.help, 'Ask about the app'),
  other('Other', Icons.more_horiz, 'Something else');

  final String displayName;
  final IconData icon;
  final String description;
  const FeedbackType(this.displayName, this.icon, this.description);
}

/// Service for handling user feedback and bug reports
class FeedbackService {
  // Replace with your email address
  static const String _supportEmail = 'support@lifequest.app';

  /// Send feedback via email
  static Future<bool> sendFeedback({
    required FeedbackType type,
    required String message,
    String? userEmail,
    List<String>? attachmentPaths,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final appInfo = await _getAppInfo();

      final subject = '[Life Quest ${type.displayName}] ${_getSubjectPreview(message)}';

      final body = '''
${type.displayName}
${'=' * 40}

$message

${'=' * 40}
Device & App Information (auto-generated)
${'=' * 40}
$deviceInfo
$appInfo
${'=' * 40}

${userEmail != null ? 'User Email: $userEmail' : 'No email provided'}
''';

      final uri = Uri(
        scheme: 'mailto',
        path: _supportEmail,
        query: _encodeQueryParameters({
          'subject': subject,
          'body': body,
        }),
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        // Fallback: copy to clipboard
        await Clipboard.setData(ClipboardData(text: body));
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get a preview of the message for the subject line
  static String _getSubjectPreview(String message) {
    final preview = message.split('\n').first;
    if (preview.length > 50) {
      return '${preview.substring(0, 47)}...';
    }
    return preview;
  }

  /// Encode query parameters for mailto URI
  static String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  /// Get device information
  static Future<String> _getDeviceInfo() async {
    final buffer = StringBuffer();

    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('OS Version: ${Platform.operatingSystemVersion}');
    buffer.writeln('Dart Version: ${Platform.version}');

    if (Platform.isAndroid || Platform.isIOS) {
      buffer.writeln('Locale: ${Platform.localeName}');
    }

    return buffer.toString();
  }

  /// Get app information
  static Future<String> _getAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '''
App Name: ${packageInfo.appName}
Version: ${packageInfo.version}
Build: ${packageInfo.buildNumber}
Package: ${packageInfo.packageName}
''';
    } catch (e) {
      return 'App Info: Unable to retrieve';
    }
  }

  /// Quick bug report with minimal input
  static Future<bool> quickBugReport({
    required String screenName,
    required String description,
    String? errorMessage,
  }) async {
    final message = '''
Screen: $screenName

Description:
$description

${errorMessage != null ? 'Error Message:\n$errorMessage' : ''}
''';

    return sendFeedback(
      type: FeedbackType.bug,
      message: message,
    );
  }
}

/// A dialog widget for collecting user feedback
class FeedbackDialog extends StatefulWidget {
  final FeedbackType? initialType;
  final String? screenContext;

  const FeedbackDialog({
    super.key,
    this.initialType,
    this.screenContext,
  });

  static Future<void> show(BuildContext context, {
    FeedbackType? initialType,
    String? screenContext,
  }) {
    return showDialog(
      context: context,
      builder: (context) => FeedbackDialog(
        initialType: initialType,
        screenContext: screenContext,
      ),
    );
  }

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  late FeedbackType _selectedType;
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? FeedbackType.bug;

    if (widget.screenContext != null) {
      _messageController.text = 'Screen: ${widget.screenContext}\n\n';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Feedback'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback type selection
            const Text(
              'What would you like to report?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FeedbackType.values.map((type) {
                final isSelected = type == _selectedType;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type.icon, size: 16),
                      const SizedBox(width: 4),
                      Text(type.displayName),
                    ],
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Message input
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Describe the issue',
                hintText: _getHintForType(_selectedType),
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Optional email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Your email (optional)',
                hintText: 'For follow-up if needed',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Info note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Device info will be automatically included to help us diagnose the issue.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send'),
        ),
      ],
    );
  }

  String _getHintForType(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'What happened? What did you expect to happen?';
      case FeedbackType.feature:
        return 'What feature would you like to see?';
      case FeedbackType.improvement:
        return 'What could be improved and how?';
      case FeedbackType.question:
        return 'What would you like to know?';
      case FeedbackType.other:
        return 'Tell us what\'s on your mind';
    }
  }

  Future<void> _submitFeedback() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await FeedbackService.sendFeedback(
      type: _selectedType,
      message: _messageController.text,
      userEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening email app...'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback copied to clipboard. Please email it to support.'),
          ),
        );
      }
    }
  }
}

/// A floating action button for quick bug reports
class ReportBugButton extends StatelessWidget {
  final String screenName;

  const ReportBugButton({
    super.key,
    required this.screenName,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'report_bug',
      onPressed: () => FeedbackDialog.show(
        context,
        initialType: FeedbackType.bug,
        screenContext: screenName,
      ),
      tooltip: 'Report a Bug',
      child: const Icon(Icons.bug_report),
    );
  }
}

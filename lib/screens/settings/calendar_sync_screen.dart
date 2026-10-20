import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../services/google_calendar_service.dart';
import '../../services/ai_service.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';

class CalendarSyncScreen extends ConsumerStatefulWidget {
  const CalendarSyncScreen({super.key});

  @override
  ConsumerState<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends ConsumerState<CalendarSyncScreen> {
  bool _isConnecting = false;
  bool _isSyncing = false;
  bool _autoImport = true;
  bool _autoAnalyze = true;
  List<CalendarEvent> _previewEvents = [];

  @override
  Widget build(BuildContext context) {
    final calendarService = ref.watch(googleCalendarServiceProvider);
    final isConnected = calendarService.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Calendar Sync'),
        actions: [
          if (isConnected)
            IconButton(
              onPressed: _syncNow,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Sync Now',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            _ConnectionCard(
              isConnected: isConnected,
              isConnecting: _isConnecting,
              onConnect: _connectCalendar,
              onDisconnect: _disconnectCalendar,
            ),
            const SizedBox(height: 24),

            // Settings Section
            if (isConnected) ...[
              Text(
                'Sync Settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // Auto Import Toggle
              _SettingTile(
                icon: Icons.download,
                title: 'Auto Import Events',
                subtitle: 'Automatically create tasks from calendar events',
                value: _autoImport,
                onChanged: (v) => setState(() => _autoImport = v),
              ),

              // Auto Analyze Toggle
              _SettingTile(
                icon: Icons.auto_awesome,
                title: 'AI Stat Detection',
                subtitle: 'Use Gemini AI to detect which stats calendar events affect',
                value: _autoAnalyze,
                onChanged: (v) => setState(() => _autoAnalyze = v),
              ),

              const SizedBox(height: 24),

              // Today's Events Preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Events",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: _loadTodayEvents,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_previewEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.event_available, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'No events today',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadTodayEvents,
                        child: const Text('Load Events'),
                      ),
                    ],
                  ),
                )
              else
                ..._previewEvents.map((event) => _EventPreviewCard(
                  event: event,
                  onImport: () => _importEvent(event),
                )),

              const SizedBox(height: 24),

              // Import All Button
              if (_previewEvents.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _importAllEvents,
                    icon: const Icon(Icons.download),
                    label: Text('Import All (${_previewEvents.length} events)'),
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Connect your Google Calendar\n'
                    '2. Calendar events are analyzed by Gemini AI\n'
                    '3. AI detects which stats each event will improve\n'
                    '4. Events become tasks with appropriate XP rewards\n'
                    '5. Complete tasks to level up your character!',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectCalendar() async {
    setState(() => _isConnecting = true);
    
    try {
      final service = ref.read(googleCalendarServiceProvider);
      final success = await service.authenticate();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully connected to Google Calendar!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadTodayEvents();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnectCalendar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Calendar?'),
        content: const Text('This will remove the calendar connection. You can reconnect anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(googleCalendarServiceProvider);
      await service.signOut();
      setState(() {
        _previewEvents = [];
      });
    }
  }

  Future<void> _loadTodayEvents() async {
    final service = ref.read(googleCalendarServiceProvider);
    if (!service.isAuthenticated) return;

    try {
      final events = await service.getTodayEvents();
      setState(() => _previewEvents = events);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    await _loadTodayEvents();
    
    if (_autoImport && _previewEvents.isNotEmpty) {
      await _importAllEvents();
    }
    
    setState(() => _isSyncing = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync complete!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _importEvent(CalendarEvent event) async {
    final aiService = ref.read(aiServiceProvider);
    final taskNotifier = ref.read(taskNotifierProvider.notifier);

    // Analyze with AI if enabled
    Map<String, int> statRewards = {'discipline': 10};
    int xpReward = 10;
    String? reasoning;

    if (_autoAnalyze) {
      final analysis = await aiService.analyzeTask(
        event.title,
        description: event.description,
      );
      statRewards = analysis.suggestedStats;
      xpReward = analysis.suggestedXP;
      reasoning = analysis.reasoning;
    }

    await taskNotifier.createTask(
      title: event.title,
      description: event.description,
      type: event.recurrence != null ? TaskType.daily : TaskType.oneTime,
      dueDate: event.start,
      statRewards: statRewards,
      stat: statRewards.keys.first,
      xpReward: xpReward,
      isFromCalendar: true,
      calendarEventId: event.id,
      aiReasoning: reasoning,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported: ${event.title}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _importAllEvents() async {
    for (final event in _previewEvents) {
      await _importEvent(event);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${_previewEvents.length} events as tasks!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _ConnectionCard extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _ConnectionCard({
    required this.isConnected,
    required this.isConnecting,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected
              ? [AppColors.success.withOpacity(0.2), AppColors.surface]
              : [AppColors.primary.withOpacity(0.2), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? AppColors.success.withOpacity(0.5) : AppColors.primary.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (isConnected ? AppColors.success : AppColors.primary).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConnected ? Icons.calendar_month : Icons.calendar_today,
                  color: isConnected ? AppColors.success : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Calendar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConnected ? AppColors.success : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected ? 'Connected' : 'Not connected',
                          style: TextStyle(
                            color: isConnected ? AppColors.success : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isConnected
                ? OutlinedButton.icon(
                    onPressed: onDisconnect,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: isConnecting ? null : onConnect,
                    icon: isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(isConnecting ? 'Connecting...' : 'Connect Calendar'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _EventPreviewCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onImport;

  const _EventPreviewCard({
    required this.event,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (event.start != null)
                  Text(
                    event.isAllDay
                        ? 'All day'
                        : '${event.start!.hour}:${event.start!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onImport,
            icon: const Icon(Icons.add_task, color: AppColors.success),
            tooltip: 'Import as task',
          ),
        ],
      ),
    );
  }
}

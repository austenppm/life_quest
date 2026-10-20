import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/health_provider.dart';
import '../../services/health_service.dart';

class HealthIntegrationScreen extends ConsumerWidget {
  const HealthIntegrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthIntegrationProvider);
    final isAvailable = ref.watch(healthAvailableProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Integration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Platform availability
          if (!isAvailable) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Health integration is only available on Android and iOS devices.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Connection status card
          _ConnectionStatusCard(
            isConnected: healthState.isConnected,
            isConnecting: healthState.isConnecting,
            connectionInfo: healthState.connectionInfo,
            onConnect: () {
              ref.read(healthIntegrationProvider.notifier).connect();
            },
            onDisconnect: () {
              ref.read(healthIntegrationProvider.notifier).disconnect();
            },
          ),
          const SizedBox(height: 16),

          // Error display
          if (healthState.error != null) ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        healthState.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(healthIntegrationProvider.notifier).clearError();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Sync section
          if (healthState.isConnected) ...[
            _SyncSection(
              isSyncing: healthState.isSyncing,
              lastSyncTime: healthState.lastSyncTime,
              onSync: () {
                ref.read(healthIntegrationProvider.notifier).syncAllData();
              },
            ),
            const SizedBox(height: 16),

            // Synced data summary
            _SyncedDataSummary(healthState: healthState),
            const SizedBox(height: 16),
          ],

          // Supported platforms info
          _SupportedPlatformsCard(),
          const SizedBox(height: 16),

          // How it works
          _HowItWorksCard(),
        ],
      ),
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final HealthConnectionInfo? connectionInfo;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _ConnectionStatusCard({
    required this.isConnected,
    required this.isConnecting,
    this.connectionInfo,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? Colors.green.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isConnected ? Icons.link : Icons.link_off,
                    color: isConnected ? Colors.green : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? 'Connected' : 'Not Connected',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (connectionInfo?.sourceName != null)
                        Text(
                          'Source: ${connectionInfo!.sourceName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      if (connectionInfo?.connectedAt != null)
                        Text(
                          'Connected: ${DateFormat.yMMMd().format(connectionInfo!.connectedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
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
                  ? OutlinedButton(
                      onPressed: onDisconnect,
                      child: const Text('Disconnect'),
                    )
                  : FilledButton(
                      onPressed: isConnecting ? null : onConnect,
                      child: isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect to Health'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncSection extends StatelessWidget {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final VoidCallback onSync;

  const _SyncSection({
    required this.isSyncing,
    this.lastSyncTime,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Sync Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (lastSyncTime != null)
                  Text(
                    'Last: ${DateFormat.Hm().format(lastSyncTime!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sync your sleep, steps, weight, and workout data from your connected health apps and wearables.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSyncing ? null : onSync,
                icon: isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncedDataSummary extends StatelessWidget {
  final HealthIntegrationState healthState;

  const _SyncedDataSummary({required this.healthState});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Synced Data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _DataRow(
              icon: Icons.bedtime,
              label: 'Sleep Sessions',
              value: '${healthState.sleepSessions.length} sessions',
            ),
            const Divider(),
            _DataRow(
              icon: Icons.directions_walk,
              label: 'Today\'s Steps',
              value: '${healthState.todaySteps} steps',
            ),
            const Divider(),
            _DataRow(
              icon: Icons.monitor_weight,
              label: 'Weight Records',
              value: '${healthState.weightData.length} records',
            ),
            const Divider(),
            _DataRow(
              icon: Icons.fitness_center,
              label: 'Workouts',
              value: '${healthState.workouts.length} workouts',
            ),
            const Divider(),
            _DataRow(
              icon: Icons.water_drop,
              label: 'Today\'s Water',
              value: '${(healthState.todayWaterMl / 1000).toStringAsFixed(1)} L',
            ),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _SupportedPlatformsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supported Platforms',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _PlatformItem(
              name: 'Google Fit',
              description: 'Android devices',
              icon: '🏃',
            ),
            _PlatformItem(
              name: 'Health Connect',
              description: 'Android 14+',
              icon: '❤️',
            ),
            _PlatformItem(
              name: 'Apple Health',
              description: 'iOS devices',
              icon: '🍎',
            ),
            _PlatformItem(
              name: 'Garmin Connect',
              description: 'Syncs via Google Fit',
              icon: '⌚',
            ),
            _PlatformItem(
              name: 'Samsung Health',
              description: 'Syncs via Health Connect',
              icon: '📱',
            ),
            _PlatformItem(
              name: 'Fitbit',
              description: 'Syncs via Google Fit',
              icon: '💪',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlatformItem extends StatelessWidget {
  final String name;
  final String description;
  final String icon;

  const _PlatformItem({
    required this.name,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How It Works',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _StepItem(
              number: '1',
              text: 'Connect your health platform (Google Fit or Apple Health)',
            ),
            _StepItem(
              number: '2',
              text: 'Grant permission to read health data',
            ),
            _StepItem(
              number: '3',
              text: 'Your Garmin/Fitbit data syncs automatically via Google Fit',
            ),
            _StepItem(
              number: '4',
              text: 'Tap "Sync Now" to import your health data',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure your Garmin Connect app is syncing to Google Fit in its settings.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;

  const _StepItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}

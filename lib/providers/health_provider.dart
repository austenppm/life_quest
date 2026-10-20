import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sleep_session.dart';
import '../services/health_service.dart';
import 'auth_provider.dart';

/// Provider for health connection status
final healthConnectionProvider = FutureProvider<HealthConnectionInfo?>((ref) async {
  return await HealthService.getConnectionInfo();
});

/// Provider for checking if health is available on device
final healthAvailableProvider = Provider<bool>((ref) {
  return HealthService.isAvailable;
});

/// State notifier for health integration
class HealthIntegrationNotifier extends StateNotifier<HealthIntegrationState> {
  final String? _userId;

  HealthIntegrationNotifier(this._userId) : super(const HealthIntegrationState());

  /// Connect to health platform
  Future<bool> connect() async {
    state = state.copyWith(isConnecting: true, error: null);

    try {
      final authorized = await HealthService.requestAuthorization();

      if (authorized) {
        final connectionInfo = await HealthService.getConnectionInfo();
        state = state.copyWith(
          isConnecting: false,
          isConnected: true,
          connectionInfo: connectionInfo,
        );
        return true;
      } else {
        state = state.copyWith(
          isConnecting: false,
          error: 'Authorization denied. Please grant health permissions.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        error: 'Failed to connect: $e',
      );
      return false;
    }
  }

  /// Disconnect from health platform
  Future<void> disconnect() async {
    await HealthService.disconnect();
    state = const HealthIntegrationState();
  }

  /// Sync sleep data from health platform
  Future<List<SleepSession>> syncSleepData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_userId == null) return [];

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 7));

      final sessions = await HealthService.fetchSleepData(
        startDate: start,
        endDate: end,
        userId: _userId,
      );

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        sleepSessions: sessions,
      );

      return sessions;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to sync sleep data: $e',
      );
      return [];
    }
  }

  /// Sync all health data
  Future<void> syncAllData() async {
    if (_userId == null) return;

    state = state.copyWith(isSyncing: true, error: null);

    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      // Sync sleep
      final sleepSessions = await HealthService.fetchSleepData(
        startDate: weekAgo,
        endDate: now,
        userId: _userId,
      );

      // Sync steps for today
      final todaySteps = await HealthService.fetchSteps(now);

      // Sync weight
      final weightData = await HealthService.fetchWeightData(
        startDate: weekAgo,
        endDate: now,
      );

      // Sync workouts
      final workouts = await HealthService.fetchWorkouts(
        startDate: weekAgo,
        endDate: now,
      );

      // Sync water intake for today
      final waterIntake = await HealthService.fetchWaterIntake(now);

      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        sleepSessions: sleepSessions,
        todaySteps: todaySteps,
        weightData: weightData,
        workouts: workouts,
        todayWaterMl: waterIntake,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to sync health data: $e',
      );
    }
  }

  /// Fetch today's steps
  Future<int> fetchTodaySteps() async {
    try {
      final steps = await HealthService.fetchSteps(DateTime.now());
      state = state.copyWith(todaySteps: steps);
      return steps;
    } catch (e) {
      return state.todaySteps;
    }
  }

  /// Check connection status
  Future<void> checkConnection() async {
    final isConnected = await HealthService.isConnected();
    if (isConnected) {
      final connectionInfo = await HealthService.getConnectionInfo();
      state = state.copyWith(
        isConnected: true,
        connectionInfo: connectionInfo,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// State for health integration
class HealthIntegrationState {
  final bool isConnecting;
  final bool isConnected;
  final bool isSyncing;
  final String? error;
  final HealthConnectionInfo? connectionInfo;
  final DateTime? lastSyncTime;
  final List<SleepSession> sleepSessions;
  final int todaySteps;
  final List<WeightDataPoint> weightData;
  final List<WorkoutDataPoint> workouts;
  final double todayWaterMl;

  const HealthIntegrationState({
    this.isConnecting = false,
    this.isConnected = false,
    this.isSyncing = false,
    this.error,
    this.connectionInfo,
    this.lastSyncTime,
    this.sleepSessions = const [],
    this.todaySteps = 0,
    this.weightData = const [],
    this.workouts = const [],
    this.todayWaterMl = 0,
  });

  HealthIntegrationState copyWith({
    bool? isConnecting,
    bool? isConnected,
    bool? isSyncing,
    String? error,
    HealthConnectionInfo? connectionInfo,
    DateTime? lastSyncTime,
    List<SleepSession>? sleepSessions,
    int? todaySteps,
    List<WeightDataPoint>? weightData,
    List<WorkoutDataPoint>? workouts,
    double? todayWaterMl,
  }) {
    return HealthIntegrationState(
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      connectionInfo: connectionInfo ?? this.connectionInfo,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      sleepSessions: sleepSessions ?? this.sleepSessions,
      todaySteps: todaySteps ?? this.todaySteps,
      weightData: weightData ?? this.weightData,
      workouts: workouts ?? this.workouts,
      todayWaterMl: todayWaterMl ?? this.todayWaterMl,
    );
  }
}

/// Provider for health integration
final healthIntegrationProvider =
    StateNotifierProvider<HealthIntegrationNotifier, HealthIntegrationState>((ref) {
  final user = ref.watch(currentUserProvider);
  return HealthIntegrationNotifier(user?.uid);
});

/// Provider for synced sleep sessions from health platform
final healthSleepSessionsProvider = Provider<List<SleepSession>>((ref) {
  return ref.watch(healthIntegrationProvider).sleepSessions;
});

/// Provider for today's steps from health platform
final healthTodayStepsProvider = Provider<int>((ref) {
  return ref.watch(healthIntegrationProvider).todaySteps;
});

/// Provider for weight data from health platform
final healthWeightDataProvider = Provider<List<WeightDataPoint>>((ref) {
  return ref.watch(healthIntegrationProvider).weightData;
});

/// Provider for workouts from health platform
final healthWorkoutsProvider = Provider<List<WorkoutDataPoint>>((ref) {
  return ref.watch(healthIntegrationProvider).workouts;
});

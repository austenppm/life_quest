import 'dart:io';

import 'package:health/health.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sleep_session.dart';

/// Service for integrating with Google Fit / Apple Health / Health Connect
/// Garmin data syncs to Google Fit, so it will be available through this integration
class HealthService {
  static final Health _health = Health();

  /// Health data types we want to read
  static final List<HealthDataType> _sleepTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_SESSION,
  ];

  static final List<HealthDataType> _activityTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.WATER,
  ];

  static List<HealthDataType> get allTypes => [..._sleepTypes, ..._activityTypes];

  /// Check if health data is available on this platform
  static bool get isAvailable => Platform.isAndroid || Platform.isIOS;

  /// Request authorization to access health data
  static Future<bool> requestAuthorization() async {
    if (!isAvailable) return false;

    try {
      // Configure the health plugin
      await _health.configure();

      // Get permissions for all types (read only)
      final permissions = allTypes.map((e) => HealthDataAccess.READ).toList();

      // Request authorization
      final authorized = await _health.requestAuthorization(
        allTypes,
        permissions: permissions,
      );

      if (authorized) {
        // Save that we've connected
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('health_connected', true);
        await prefs.setString('health_connected_at', DateTime.now().toIso8601String());
      }

      return authorized;
    } catch (e) {
      print('Health authorization error: $e');
      return false;
    }
  }

  /// Check if we have authorization
  static Future<bool> hasAuthorization() async {
    if (!isAvailable) return false;

    try {
      await _health.configure();

      // Check if we have permissions for at least sleep data
      final hasPermissions = await _health.hasPermissions(
        _sleepTypes,
        permissions: _sleepTypes.map((e) => HealthDataAccess.READ).toList(),
      );

      return hasPermissions ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Fetch sleep data for a date range
  static Future<List<SleepSession>> fetchSleepData({
    required DateTime startDate,
    required DateTime endDate,
    required String userId,
  }) async {
    if (!isAvailable) return [];

    try {
      await _health.configure();

      // Fetch all sleep-related health data points
      final healthData = await _health.getHealthDataFromTypes(
        types: _sleepTypes,
        startTime: startDate,
        endTime: endDate,
      );

      // Remove duplicates
      final uniqueData = _health.removeDuplicates(healthData);

      // Group sleep data into sessions
      return _processSleepData(uniqueData, userId);
    } catch (e) {
      print('Error fetching sleep data: $e');
      return [];
    }
  }

  /// Process raw health data into SleepSession objects
  static List<SleepSession> _processSleepData(
    List<HealthDataPoint> data,
    String userId,
  ) {
    if (data.isEmpty) return [];

    // Group data by date (sleep sessions typically span midnight)
    final sessionMap = <String, _SleepSessionBuilder>{};

    for (final point in data) {
      // Use the end date as the session identifier (wake up date)
      final sessionKey = '${point.dateFrom.year}-${point.dateFrom.month}-${point.dateFrom.day}';

      sessionMap.putIfAbsent(
        sessionKey,
        () => _SleepSessionBuilder(userId: userId),
      );

      final builder = sessionMap[sessionKey]!;

      // Update session times
      if (builder.bedTime == null || point.dateFrom.isBefore(builder.bedTime!)) {
        builder.bedTime = point.dateFrom;
      }
      if (builder.wakeTime == null || point.dateTo.isAfter(builder.wakeTime!)) {
        builder.wakeTime = point.dateTo;
      }

      // Add segment based on type
      final stage = _healthTypeToSleepStage(point.type);
      if (stage != null) {
        builder.segments.add(SleepSegment(
          startTime: point.dateFrom,
          endTime: point.dateTo,
          stage: stage,
        ));
      }
    }

    // Convert builders to SleepSession objects
    return sessionMap.values
        .where((b) => b.bedTime != null && b.wakeTime != null)
        .map((b) => b.build())
        .toList()
      ..sort((a, b) => b.bedTime.compareTo(a.bedTime));
  }

  static SleepStage? _healthTypeToSleepStage(HealthDataType type) {
    switch (type) {
      case HealthDataType.SLEEP_AWAKE:
        return SleepStage.awake;
      case HealthDataType.SLEEP_LIGHT:
        return SleepStage.light;
      case HealthDataType.SLEEP_DEEP:
        return SleepStage.deep;
      case HealthDataType.SLEEP_REM:
        return SleepStage.rem;
      case HealthDataType.SLEEP_ASLEEP:
      case HealthDataType.SLEEP_IN_BED:
      case HealthDataType.SLEEP_SESSION:
        return SleepStage.light; // Default to light if unspecified
      default:
        return null;
    }
  }

  /// Fetch step count for a date
  static Future<int> fetchSteps(DateTime date) async {
    if (!isAvailable) return 0;

    try {
      await _health.configure();

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final steps = await _health.getTotalStepsInInterval(startOfDay, endOfDay);
      return steps ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Fetch weight data
  static Future<List<WeightDataPoint>> fetchWeightData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!isAvailable) return [];

    try {
      await _health.configure();

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: startDate,
        endTime: endDate,
      );

      return healthData.map((point) {
        final value = point.value;
        double weight = 0;
        if (value is NumericHealthValue) {
          weight = value.numericValue.toDouble();
        }
        return WeightDataPoint(
          date: point.dateFrom,
          weightKg: weight,
          source: point.sourceName,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch heart rate data
  static Future<List<HeartRateDataPoint>> fetchHeartRateData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!isAvailable) return [];

    try {
      await _health.configure();

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startDate,
        endTime: endDate,
      );

      return healthData.map((point) {
        final value = point.value;
        int bpm = 0;
        if (value is NumericHealthValue) {
          bpm = value.numericValue.toInt();
        }
        return HeartRateDataPoint(
          date: point.dateFrom,
          bpm: bpm,
          source: point.sourceName,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch water intake
  static Future<double> fetchWaterIntake(DateTime date) async {
    if (!isAvailable) return 0;

    try {
      await _health.configure();

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: startOfDay,
        endTime: endOfDay,
      );

      double totalMl = 0;
      for (final point in healthData) {
        final value = point.value;
        if (value is NumericHealthValue) {
          totalMl += value.numericValue.toDouble();
        }
      }
      return totalMl;
    } catch (e) {
      return 0;
    }
  }

  /// Fetch workout/exercise data
  static Future<List<WorkoutDataPoint>> fetchWorkouts({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!isAvailable) return [];

    try {
      await _health.configure();

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: startDate,
        endTime: endDate,
      );

      return healthData.map((point) {
        final value = point.value;
        String workoutType = 'Unknown';
        int calories = 0;

        if (value is WorkoutHealthValue) {
          workoutType = value.workoutActivityType.name;
          calories = value.totalEnergyBurned?.toInt() ?? 0;
        }

        return WorkoutDataPoint(
          startTime: point.dateFrom,
          endTime: point.dateTo,
          workoutType: workoutType,
          caloriesBurned: calories,
          source: point.sourceName,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get the source name (e.g., "Garmin Connect", "Google Fit")
  static Future<String?> getDataSource() async {
    if (!isAvailable) return null;

    try {
      await _health.configure();

      // Fetch a small sample to see the source
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final data = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: weekAgo,
        endTime: now,
      );

      if (data.isNotEmpty) {
        return data.first.sourceName;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Disconnect health integration
  static Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('health_connected');
    await prefs.remove('health_connected_at');
    // Note: We can't revoke permissions programmatically
    // User needs to do this in device settings
  }

  /// Check if connected
  static Future<bool> isConnected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('health_connected') ?? false;
  }

  /// Get connection info
  static Future<HealthConnectionInfo?> getConnectionInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final connected = prefs.getBool('health_connected') ?? false;
    if (!connected) return null;

    final connectedAtStr = prefs.getString('health_connected_at');
    final connectedAt = connectedAtStr != null
        ? DateTime.parse(connectedAtStr)
        : null;

    final source = await getDataSource();

    return HealthConnectionInfo(
      isConnected: connected,
      connectedAt: connectedAt,
      sourceName: source,
    );
  }
}

/// Helper class for building sleep sessions
class _SleepSessionBuilder {
  final String userId;
  DateTime? bedTime;
  DateTime? wakeTime;
  final List<SleepSegment> segments = [];

  _SleepSessionBuilder({required this.userId});

  SleepSession build() {
    // Sort segments by time
    segments.sort((a, b) => a.startTime.compareTo(b.startTime));

    return SleepSession(
      id: '${bedTime!.millisecondsSinceEpoch}',
      userId: userId,
      bedTime: bedTime!,
      wakeTime: wakeTime!,
      segments: segments,
      createdAt: DateTime.now(),
    );
  }
}

/// Data point classes for health data
class WeightDataPoint {
  final DateTime date;
  final double weightKg;
  final String source;

  const WeightDataPoint({
    required this.date,
    required this.weightKg,
    required this.source,
  });
}

class HeartRateDataPoint {
  final DateTime date;
  final int bpm;
  final String source;

  const HeartRateDataPoint({
    required this.date,
    required this.bpm,
    required this.source,
  });
}

class WorkoutDataPoint {
  final DateTime startTime;
  final DateTime endTime;
  final String workoutType;
  final int caloriesBurned;
  final String source;

  const WorkoutDataPoint({
    required this.startTime,
    required this.endTime,
    required this.workoutType,
    required this.caloriesBurned,
    required this.source,
  });

  Duration get duration => endTime.difference(startTime);
}

class HealthConnectionInfo {
  final bool isConnected;
  final DateTime? connectedAt;
  final String? sourceName;

  const HealthConnectionInfo({
    required this.isConnected,
    this.connectedAt,
    this.sourceName,
  });
}

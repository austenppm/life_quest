import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Sleep quality rating
enum SleepQuality {
  terrible(1, 'Terrible'),
  poor(2, 'Poor'),
  fair(3, 'Fair'),
  good(4, 'Good'),
  excellent(5, 'Excellent');

  final int value;
  final String displayName;
  const SleepQuality(this.value, this.displayName);

  static SleepQuality fromValue(int value) {
    return SleepQuality.values.firstWhere(
      (q) => q.value == value,
      orElse: () => SleepQuality.fair,
    );
  }
}

/// Sleep stage detected during sleep
enum SleepStage {
  awake('Awake'),
  light('Light Sleep'),
  deep('Deep Sleep'),
  rem('REM Sleep');

  final String displayName;
  const SleepStage(this.displayName);
}

/// A segment of sleep with its detected stage
class SleepSegment {
  final DateTime startTime;
  final DateTime endTime;
  final SleepStage stage;

  const SleepSegment({
    required this.startTime,
    required this.endTime,
    required this.stage,
  });

  Duration get duration => endTime.difference(startTime);

  factory SleepSegment.fromMap(Map<String, dynamic> map) {
    return SleepSegment(
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      stage: SleepStage.values.firstWhere(
        (s) => s.name == map['stage'],
        orElse: () => SleepStage.light,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'stage': stage.name,
    };
  }
}

/// A recorded sleep session
class SleepSession extends Equatable {
  final String id;
  final String userId;
  final DateTime bedTime;
  final DateTime wakeTime;
  final SleepQuality? quality;
  final String? notes;
  final List<SleepSegment> segments; // For detailed sleep analysis
  final bool hasSnoreRecording;
  final String? snoreRecordingUrl;
  final int? snoreCount; // Number of snore events detected
  final int? snoreTotalSeconds; // Total snoring duration
  final List<String> factors; // Factors affecting sleep (caffeine, stress, etc.)
  final DateTime createdAt;

  const SleepSession({
    required this.id,
    required this.userId,
    required this.bedTime,
    required this.wakeTime,
    this.quality,
    this.notes,
    this.segments = const [],
    this.hasSnoreRecording = false,
    this.snoreRecordingUrl,
    this.snoreCount,
    this.snoreTotalSeconds,
    this.factors = const [],
    required this.createdAt,
  });

  /// Total sleep duration
  Duration get duration => wakeTime.difference(bedTime);

  /// Duration in hours (decimal)
  double get durationHours => duration.inMinutes / 60;

  /// Formatted duration string
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  /// Time in each sleep stage
  Map<SleepStage, Duration> get stageBreakdown {
    final breakdown = <SleepStage, Duration>{};
    for (final stage in SleepStage.values) {
      breakdown[stage] = Duration.zero;
    }
    for (final segment in segments) {
      breakdown[segment.stage] = breakdown[segment.stage]! + segment.duration;
    }
    return breakdown;
  }

  /// Sleep efficiency (time asleep / time in bed)
  double get efficiency {
    if (segments.isEmpty) return 1.0;
    final awakeTime = stageBreakdown[SleepStage.awake] ?? Duration.zero;
    final sleepTime = duration - awakeTime;
    return sleepTime.inMinutes / duration.inMinutes;
  }

  factory SleepSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SleepSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      bedTime: (data['bedTime'] as Timestamp).toDate(),
      wakeTime: (data['wakeTime'] as Timestamp).toDate(),
      quality: data['quality'] != null
          ? SleepQuality.fromValue(data['quality'])
          : null,
      notes: data['notes'],
      segments: (data['segments'] as List<dynamic>?)
              ?.map((s) => SleepSegment.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      hasSnoreRecording: data['hasSnoreRecording'] ?? false,
      snoreRecordingUrl: data['snoreRecordingUrl'],
      snoreCount: data['snoreCount'],
      snoreTotalSeconds: data['snoreTotalSeconds'],
      factors: List<String>.from(data['factors'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bedTime': Timestamp.fromDate(bedTime),
      'wakeTime': Timestamp.fromDate(wakeTime),
      'quality': quality?.value,
      'notes': notes,
      'segments': segments.map((s) => s.toMap()).toList(),
      'hasSnoreRecording': hasSnoreRecording,
      'snoreRecordingUrl': snoreRecordingUrl,
      'snoreCount': snoreCount,
      'snoreTotalSeconds': snoreTotalSeconds,
      'factors': factors,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SleepSession copyWith({
    DateTime? bedTime,
    DateTime? wakeTime,
    SleepQuality? quality,
    String? notes,
    List<SleepSegment>? segments,
    bool? hasSnoreRecording,
    String? snoreRecordingUrl,
    int? snoreCount,
    int? snoreTotalSeconds,
    List<String>? factors,
  }) {
    return SleepSession(
      id: id,
      userId: userId,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      segments: segments ?? this.segments,
      hasSnoreRecording: hasSnoreRecording ?? this.hasSnoreRecording,
      snoreRecordingUrl: snoreRecordingUrl ?? this.snoreRecordingUrl,
      snoreCount: snoreCount ?? this.snoreCount,
      snoreTotalSeconds: snoreTotalSeconds ?? this.snoreTotalSeconds,
      factors: factors ?? this.factors,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, bedTime, wakeTime, quality, notes, segments,
        hasSnoreRecording, snoreRecordingUrl, snoreCount, snoreTotalSeconds,
        factors, createdAt,
      ];
}

/// Weekly sleep statistics
class SleepStats {
  final double averageDurationHours;
  final double averageQuality;
  final Duration totalSleep;
  final int sessionsCount;
  final DateTime? earliestBedTime;
  final DateTime? latestBedTime;
  final DateTime? earliestWakeTime;
  final DateTime? latestWakeTime;
  final double averageEfficiency;

  const SleepStats({
    this.averageDurationHours = 0,
    this.averageQuality = 0,
    this.totalSleep = Duration.zero,
    this.sessionsCount = 0,
    this.earliestBedTime,
    this.latestBedTime,
    this.earliestWakeTime,
    this.latestWakeTime,
    this.averageEfficiency = 0,
  });

  factory SleepStats.fromSessions(List<SleepSession> sessions) {
    if (sessions.isEmpty) return const SleepStats();

    final totalMinutes = sessions.fold(0, (sum, s) => sum + s.duration.inMinutes);
    final qualitySum = sessions.where((s) => s.quality != null).fold(0, (sum, s) => sum + s.quality!.value);
    final qualityCount = sessions.where((s) => s.quality != null).length;
    final efficiencySum = sessions.fold(0.0, (sum, s) => sum + s.efficiency);

    // Find bed/wake time ranges (normalize to same day for comparison)
    DateTime? earliestBed, latestBed, earliestWake, latestWake;
    for (final session in sessions) {
      final bedMinutes = session.bedTime.hour * 60 + session.bedTime.minute;
      final wakeMinutes = session.wakeTime.hour * 60 + session.wakeTime.minute;

      if (earliestBed == null || bedMinutes < (earliestBed.hour * 60 + earliestBed.minute)) {
        earliestBed = session.bedTime;
      }
      if (latestBed == null || bedMinutes > (latestBed.hour * 60 + latestBed.minute)) {
        latestBed = session.bedTime;
      }
      if (earliestWake == null || wakeMinutes < (earliestWake.hour * 60 + earliestWake.minute)) {
        earliestWake = session.wakeTime;
      }
      if (latestWake == null || wakeMinutes > (latestWake.hour * 60 + latestWake.minute)) {
        latestWake = session.wakeTime;
      }
    }

    return SleepStats(
      averageDurationHours: totalMinutes / sessions.length / 60,
      averageQuality: qualityCount > 0 ? qualitySum / qualityCount : 0,
      totalSleep: Duration(minutes: totalMinutes),
      sessionsCount: sessions.length,
      earliestBedTime: earliestBed,
      latestBedTime: latestBed,
      earliestWakeTime: earliestWake,
      latestWakeTime: latestWake,
      averageEfficiency: efficiencySum / sessions.length,
    );
  }

  /// Check if meeting sleep goal (default 7-9 hours)
  bool get meetingSleepGoal => averageDurationHours >= 7 && averageDurationHours <= 9;
}

/// Pre-defined sleep factors that may affect sleep quality
class SleepFactors {
  static const List<String> all = [
    'Caffeine',
    'Alcohol',
    'Late meal',
    'Exercise',
    'Stress',
    'Screen time',
    'Nap',
    'Travel',
    'Medication',
    'Illness',
    'Noise',
    'Temperature',
  ];
}

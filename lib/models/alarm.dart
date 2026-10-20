import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Alarm extends Equatable {
  final String id;
  final String userId;
  final String label;
  final int hour;
  final int minute;
  final List<int> days; // 1-7 for Mon-Sun, empty for one-time
  final bool isEnabled;
  final bool vibrate;
  final String? soundUri;
  final String? linkedTaskId;
  final DateTime createdAt;
  final int snoozeMinutes;
  final bool isRepeating;

  const Alarm({
    required this.id,
    required this.userId,
    required this.label,
    required this.hour,
    required this.minute,
    this.days = const [],
    this.isEnabled = true,
    this.vibrate = true,
    this.soundUri,
    this.linkedTaskId,
    required this.createdAt,
    this.snoozeMinutes = 5,
    this.isRepeating = true,
  });

  factory Alarm.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Alarm(
      id: doc.id,
      userId: data['userId'] ?? '',
      label: data['label'] ?? 'Alarm',
      hour: data['hour'] ?? 8,
      minute: data['minute'] ?? 0,
      days: List<int>.from(data['days'] ?? []),
      isEnabled: data['isEnabled'] ?? true,
      vibrate: data['vibrate'] ?? true,
      soundUri: data['soundUri'],
      linkedTaskId: data['linkedTaskId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      snoozeMinutes: data['snoozeMinutes'] ?? 5,
      isRepeating: data['isRepeating'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'label': label,
      'hour': hour,
      'minute': minute,
      'days': days,
      'isEnabled': isEnabled,
      'vibrate': vibrate,
      'soundUri': soundUri,
      'linkedTaskId': linkedTaskId,
      'createdAt': Timestamp.fromDate(createdAt),
      'snoozeMinutes': snoozeMinutes,
      'isRepeating': isRepeating,
    };
  }

  String get formattedTime {
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String get formattedDays {
    if (days.isEmpty) return 'Once';
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Weekends';
    }

    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d]).join(', ');
  }

  DateTime get nextAlarmTime {
    final now = DateTime.now();
    var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (days.isEmpty) {
      // One-time alarm
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }
      return alarmTime;
    }

    // Repeating alarm
    for (int i = 0; i < 7; i++) {
      final checkTime = alarmTime.add(Duration(days: i));
      if (days.contains(checkTime.weekday) && checkTime.isAfter(now)) {
        return checkTime;
      }
    }

    // Should not reach here, but fallback
    return alarmTime.add(const Duration(days: 1));
  }

  Alarm copyWith({
    String? label,
    int? hour,
    int? minute,
    List<int>? days,
    bool? isEnabled,
    bool? vibrate,
    String? soundUri,
    String? linkedTaskId,
    int? snoozeMinutes,
    bool? isRepeating,
  }) {
    return Alarm(
      id: id,
      userId: userId,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
      isEnabled: isEnabled ?? this.isEnabled,
      vibrate: vibrate ?? this.vibrate,
      soundUri: soundUri ?? this.soundUri,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      createdAt: createdAt,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      isRepeating: isRepeating ?? this.isRepeating,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        label,
        hour,
        minute,
        days,
        isEnabled,
        vibrate,
        soundUri,
        linkedTaskId,
        createdAt,
        snoozeMinutes,
        isRepeating,
      ];
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/water_intake.dart';
import 'auth_provider.dart';

// Water settings provider with persistence
class WaterSettingsNotifier extends StateNotifier<WaterSettings> {
  WaterSettingsNotifier() : super(const WaterSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = WaterSettings(
      dailyGoal: prefs.getDouble('water_daily_goal') ?? 2000,
      remindersEnabled: prefs.getBool('water_reminders_enabled') ?? true,
      reminderIntervalMinutes: prefs.getInt('water_reminder_interval') ?? 60,
      reminderStartHour: prefs.getInt('water_reminder_start') ?? 8,
      reminderEndHour: prefs.getInt('water_reminder_end') ?? 22,
    );
  }

  Future<void> setDailyGoal(double goal) async {
    state = state.copyWith(dailyGoal: goal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('water_daily_goal', goal);
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    state = state.copyWith(remindersEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('water_reminders_enabled', enabled);
  }

  Future<void> setReminderInterval(int minutes) async {
    state = state.copyWith(reminderIntervalMinutes: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_reminder_interval', minutes);
  }

  Future<void> setReminderHours(int startHour, int endHour) async {
    state = state.copyWith(
      reminderStartHour: startHour,
      reminderEndHour: endHour,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_reminder_start', startHour);
    await prefs.setInt('water_reminder_end', endHour);
  }
}

final waterSettingsProvider =
    StateNotifierProvider<WaterSettingsNotifier, WaterSettings>(
  (ref) => WaterSettingsNotifier(),
);

// Today's water intake stream
final todayWaterIntakeProvider = StreamProvider<List<WaterIntake>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('waterIntake')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => WaterIntake.fromFirestore(doc)).toList());
});

// Today's water summary
final todayWaterSummaryProvider = Provider<DailyWaterSummary>((ref) {
  final intakes = ref.watch(todayWaterIntakeProvider).valueOrNull ?? [];
  final settings = ref.watch(waterSettingsProvider);
  final now = DateTime.now();

  final totalAmount = intakes.fold(0.0, (sum, intake) => sum + intake.amount);

  return DailyWaterSummary(
    date: DateTime(now.year, now.month, now.day),
    totalAmount: totalAmount,
    goal: settings.dailyGoal,
    logCount: intakes.length,
    logs: intakes,
  );
});

// Water intake for a specific date
final waterIntakeByDateProvider =
    StreamProvider.family<List<WaterIntake>, DateTime>((ref, date) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('waterIntake')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => WaterIntake.fromFirestore(doc)).toList());
});

// Weekly water history (last 7 days)
final weeklyWaterHistoryProvider = Provider<List<DailyWaterSummary>>((ref) {
  final user = ref.watch(currentUserProvider);
  final settings = ref.watch(waterSettingsProvider);
  if (user == null) return [];

  // This would need async data - simplified for now
  // In practice, you'd watch multiple date providers or use a single query
  return [];
});

// Water streak (consecutive days meeting goal)
final waterStreakProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  final settings = ref.watch(waterSettingsProvider);
  if (user == null) return 0;

  int streak = 0;
  DateTime checkDate = DateTime.now().subtract(const Duration(days: 1));

  while (true) {
    final startOfDay = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('waterIntake')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final dayTotal = snapshot.docs.fold(0.0, (sum, doc) {
      final data = doc.data();
      return sum + ((data['amount'] as num?)?.toDouble() ?? 0);
    });

    if (dayTotal >= settings.dailyGoal) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }

    // Limit check to 365 days
    if (streak >= 365) break;
  }

  return streak;
});

// Water intake notifier for CRUD operations
class WaterIntakeNotifier extends StateNotifier<AsyncValue<void>> {
  final String? _userId;

  WaterIntakeNotifier(this._userId) : super(const AsyncValue.data(null));

  Future<void> addWaterIntake({
    required double amount,
    WaterContainerType containerType = WaterContainerType.glass,
    String? note,
    DateTime? timestamp,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final intake = WaterIntake(
        id: const Uuid().v4(),
        userId: _userId,
        timestamp: timestamp ?? DateTime.now(),
        amount: amount,
        containerType: containerType,
        note: note,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('waterIntake')
          .doc(intake.id)
          .set(intake.toFirestore());

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> quickAdd(double amount) async {
    await addWaterIntake(amount: amount);
  }

  Future<void> updateWaterIntake(String intakeId, {double? amount, String? note}) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};
      if (amount != null) updates['amount'] = amount;
      if (note != null) updates['note'] = note;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('waterIntake')
          .doc(intakeId)
          .update(updates);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWaterIntake(String intakeId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('waterIntake')
          .doc(intakeId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Undo last water intake (delete most recent entry)
  Future<void> undoLastIntake() async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('waterIntake')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final waterIntakeNotifierProvider =
    StateNotifierProvider<WaterIntakeNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return WaterIntakeNotifier(user?.uid);
});

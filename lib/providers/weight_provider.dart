import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/weight_entry.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/xp_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

// Weight entries stream provider
final weightEntriesProvider = StreamProvider<List<WeightEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('weightEntries')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => WeightEntry.fromFirestore(doc)).toList());
});

// Weight goal provider
final weightGoalProvider = StreamProvider<WeightGoal?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('weightGoal')
      .doc('current')
      .snapshots()
      .map((snapshot) {
    if (!snapshot.exists) return null;
    return WeightGoal.fromFirestore(snapshot);
  });
});

// Weight stats provider
final weightStatsProvider = Provider<WeightStats>((ref) {
  final entries = ref.watch(weightEntriesProvider).valueOrNull ?? [];
  return WeightStats.fromEntries(entries);
});

// Recent weight entries (last 7 days)
final recentWeightEntriesProvider = Provider<List<WeightEntry>>((ref) {
  final entries = ref.watch(weightEntriesProvider).valueOrNull ?? [];
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  return entries.where((e) => e.date.isAfter(weekAgo)).toList();
});

// Weight unit preference
final weightUnitProvider = StateProvider<WeightUnit>((ref) => WeightUnit.kg);

// Check if logged today
final hasLoggedTodayProvider = Provider<bool>((ref) {
  final entries = ref.watch(weightEntriesProvider).valueOrNull ?? [];
  if (entries.isEmpty) return false;
  
  final today = DateTime.now();
  return entries.any((e) =>
      e.date.year == today.year &&
      e.date.month == today.month &&
      e.date.day == today.day);
});

// Weight notifier for CRUD operations
class WeightNotifier extends StateNotifier<AsyncValue<void>> {
  final String? _userId;
  final UserProfile? _profile;
  final XPService _xpService;
  final Ref _ref;

  WeightNotifier(this._userId, this._profile, this._xpService, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> addWeightEntry({
    required double weight,
    required WeightUnit unit,
    DateTime? date,
    String? note,
    double? bodyFat,
    double? muscleMass,
    double? waterPercentage,
    Map<String, double>? measurements,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final entry = WeightEntry(
        id: const Uuid().v4(),
        userId: _userId,
        weight: weight,
        unit: unit,
        date: date ?? DateTime.now(),
        note: note,
        bodyFat: bodyFat,
        muscleMass: muscleMass,
        waterPercentage: waterPercentage,
        measurements: measurements,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('weightEntries')
          .doc(entry.id)
          .set(entry.toFirestore());

      // Award XP for logging weight (constitution stat)
      if (_profile != null) {
        // Check if this is first entry today for bonus XP
        final hasLoggedToday = _ref.read(hasLoggedTodayProvider);
        final xpAmount = hasLoggedToday ? 5 : 15; // More XP for daily logging

        await _xpService.awardWeightLogXP(
          userId: _userId,
          profile: _profile,
          xpAmount: xpAmount,
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateWeightEntry(WeightEntry entry) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('weightEntries')
          .doc(entry.id)
          .update(entry.toFirestore());

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWeightEntry(String entryId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('weightEntries')
          .doc(entryId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setWeightGoal({
    required double targetWeight,
    required WeightUnit unit,
    required double startWeight,
    required String goalType,
    DateTime? targetDate,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final goal = WeightGoal(
        userId: _userId,
        targetWeight: targetWeight,
        unit: unit,
        startWeight: startWeight,
        startDate: DateTime.now(),
        targetDate: targetDate,
        goalType: goalType,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('weightGoal')
          .doc('current')
          .set(goal.toFirestore());

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearWeightGoal() async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('weightGoal')
          .doc('current')
          .delete();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final weightNotifierProvider =
    StateNotifierProvider<WeightNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;
  final firestoreService = ref.watch(firestoreServiceProvider);
  final xpService = XPService(firestoreService);

  return WeightNotifier(user?.uid, profile, xpService, ref);
});

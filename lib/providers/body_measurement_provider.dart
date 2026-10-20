import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/body_measurement.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// Body measurements stream provider
final bodyMeasurementsProvider = StreamProvider<List<BodyMeasurement>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('bodyMeasurements')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => BodyMeasurement.fromFirestore(doc)).toList());
});

// Latest measurement
final latestMeasurementProvider = Provider<BodyMeasurement?>((ref) {
  final measurements = ref.watch(bodyMeasurementsProvider).valueOrNull ?? [];
  return measurements.isEmpty ? null : measurements.first;
});

// Weight history for charts
final weightHistoryProvider = Provider<List<MapEntry<DateTime, double>>>((ref) {
  final measurements = ref.watch(bodyMeasurementsProvider).valueOrNull ?? [];
  return measurements
      .where((m) => m.weight != null)
      .map((m) => MapEntry(m.date, m.weight!))
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));
});

// Body fat history for charts
final bodyFatHistoryProvider = Provider<List<MapEntry<DateTime, double>>>((ref) {
  final measurements = ref.watch(bodyMeasurementsProvider).valueOrNull ?? [];
  return measurements
      .where((m) => m.bodyFat != null)
      .map((m) => MapEntry(m.date, m.bodyFat!))
      .toList()
    ..sort((a, b) => a.key.compareTo(b.key));
});

// Body measurement notifier for CRUD operations
class BodyMeasurementNotifier extends StateNotifier<AsyncValue<void>> {
  final String? _userId;

  BodyMeasurementNotifier(this._userId) : super(const AsyncValue.data(null));

  Future<void> addMeasurement({
    required DateTime date,
    double? weight,
    double? bodyFat,
    double? neck,
    double? shoulders,
    double? chest,
    double? leftBicep,
    double? rightBicep,
    double? leftForearm,
    double? rightForearm,
    double? waist,
    double? hips,
    double? leftThigh,
    double? rightThigh,
    double? leftCalf,
    double? rightCalf,
    String? notes,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final measurement = BodyMeasurement(
        id: const Uuid().v4(),
        userId: _userId,
        date: date,
        weight: weight,
        bodyFat: bodyFat,
        neck: neck,
        shoulders: shoulders,
        chest: chest,
        leftBicep: leftBicep,
        rightBicep: rightBicep,
        leftForearm: leftForearm,
        rightForearm: rightForearm,
        waist: waist,
        hips: hips,
        leftThigh: leftThigh,
        rightThigh: rightThigh,
        leftCalf: leftCalf,
        rightCalf: rightCalf,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('bodyMeasurements')
          .doc(measurement.id)
          .set(measurement.toFirestore());

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMeasurement(String measurementId, Map<String, dynamic> updates) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('bodyMeasurements')
          .doc(measurementId)
          .update(updates);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMeasurement(String measurementId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('bodyMeasurements')
          .doc(measurementId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final bodyMeasurementNotifierProvider =
    StateNotifierProvider<BodyMeasurementNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return BodyMeasurementNotifier(user?.uid);
});

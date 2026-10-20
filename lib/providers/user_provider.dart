import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Ensure user profile exists
final _ensureProfileProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) {
    final newProfile = UserProfile.newUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Adventurer',
    ).copyWith(avatarUrl: user.photoURL);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(newProfile.toFirestore());
  }
});

// User profile stream provider
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  // Ensure profile exists first
  ref.watch(_ensureProfileProvider);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchUserProfile(user.uid);
});

// User profile notifier for updates
class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final String? _userId;

  UserProfileNotifier(this._firestoreService, this._userId)
      : super(const AsyncValue.data(null));

  Future<void> updateDisplayName(String displayName) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateUserProfile(_userId, {
        'displayName': displayName,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateAvatar(String avatarUrl) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateUserProfile(_userId, {
        'avatarUrl': avatarUrl,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(UserSettings settings) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateUserProfile(_userId, {
        'settings': settings.toMap(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStats(UserStats stats) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateUserProfile(_userId, {
        'stats': stats.toMap(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = ref.watch(currentUserProvider);
  return UserProfileNotifier(firestoreService, user?.uid);
});

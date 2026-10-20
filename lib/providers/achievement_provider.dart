import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement.dart';
import 'auth_provider.dart';

/// Stream of user's unlocked achievements
final userAchievementsProvider = StreamProvider<List<UserAchievement>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('achievements')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => UserAchievement.fromFirestore(doc)).toList());
});

/// Set of unlocked achievement IDs for quick lookup
final unlockedAchievementIdsProvider = Provider<Set<String>>((ref) {
  final userAchievements = ref.watch(userAchievementsProvider).valueOrNull ?? [];
  return userAchievements
      .where((ua) => ua.isUnlocked)
      .map((ua) => ua.achievementId)
      .toSet();
});

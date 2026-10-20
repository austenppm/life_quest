import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

import '../models/models.dart';
import '../models/transaction.dart';
import '../models/food_entry.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Profile
  DocumentReference<Map<String, dynamic>> userRef(String userId) =>
      _firestore.collection('users').doc(userId);

  Stream<UserProfile?> watchUserProfile(String userId) {
    return userRef(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await userRef(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await userRef(userId).update(data);
  }

  // Tasks
  CollectionReference<Map<String, dynamic>> tasksRef(String userId) =>
      userRef(userId).collection('tasks');

  Stream<List<Task>> watchTasks(String userId) {
    return tasksRef(userId)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList());
  }

  Future<List<Task>> getTasks(String userId) async {
    final snapshot = await tasksRef(userId).orderBy('sortOrder').get();
    return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
  }

  Future<Task> getTask(String userId, String taskId) async {
    final doc = await tasksRef(userId).doc(taskId).get();
    return Task.fromFirestore(doc);
  }

  Future<String> createTask(String userId, Task task) async {
    final doc = await tasksRef(userId).add(task.toFirestore());
    return doc.id;
  }

  Future<void> updateTask(String userId, String taskId, Map<String, dynamic> data) async {
    await tasksRef(userId).doc(taskId).update(data);
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await tasksRef(userId).doc(taskId).delete();
  }

  // Quests
  CollectionReference<Map<String, dynamic>> questsRef(String userId) =>
      userRef(userId).collection('quests');

  Stream<List<Quest>> watchQuests(String userId) {
    return questsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Quest.fromFirestore(doc)).toList());
  }

  Stream<List<Quest>> watchActiveQuests(String userId) {
    return questsRef(userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Quest.fromFirestore(doc)).toList());
  }

  Future<String> createQuest(String userId, Quest quest) async {
    final doc = await questsRef(userId).add(quest.toFirestore());
    return doc.id;
  }

  Future<void> updateQuest(String userId, String questId, Map<String, dynamic> data) async {
    await questsRef(userId).doc(questId).update(data);
  }

  Future<void> deleteQuest(String userId, String questId) async {
    await questsRef(userId).doc(questId).delete();
  }

  // Workouts
  CollectionReference<Map<String, dynamic>> workoutsRef(String userId) =>
      userRef(userId).collection('workouts');

  Stream<List<Workout>> watchWorkouts(String userId, {int? limit}) {
    var query = workoutsRef(userId).orderBy('date', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList());
  }

  Future<List<Workout>> getWorkoutsInRange(
      String userId, DateTime start, DateTime end) async {
    final snapshot = await workoutsRef(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
  }

  Future<String> createWorkout(String userId, Workout workout) async {
    final doc = await workoutsRef(userId).add(workout.toFirestore());
    return doc.id;
  }

  Future<void> updateWorkout(String userId, String workoutId, Map<String, dynamic> data) async {
    await workoutsRef(userId).doc(workoutId).update(data);
  }

  Future<void> deleteWorkout(String userId, String workoutId) async {
    await workoutsRef(userId).doc(workoutId).delete();
  }

  // Study Sessions
  CollectionReference<Map<String, dynamic>> studySessionsRef(String userId) =>
      userRef(userId).collection('studySessions');

  Stream<List<StudySession>> watchStudySessions(String userId, {int? limit}) {
    var query = studySessionsRef(userId).orderBy('startTime', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => StudySession.fromFirestore(doc)).toList());
  }

  Stream<StudySession?> watchActiveStudySession(String userId) {
    return studySessionsRef(userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return StudySession.fromFirestore(snapshot.docs.first);
    });
  }

  Future<String> createStudySession(String userId, StudySession session) async {
    final doc = await studySessionsRef(userId).add(session.toFirestore());
    return doc.id;
  }

  Future<void> updateStudySession(
      String userId, String sessionId, Map<String, dynamic> data) async {
    await studySessionsRef(userId).doc(sessionId).update(data);
  }

  // Work Logs
  CollectionReference<Map<String, dynamic>> workLogsRef(String userId) =>
      userRef(userId).collection('workLogs');

  Stream<List<WorkLog>> watchWorkLogs(String userId, {int? limit}) {
    var query = workLogsRef(userId).orderBy('startTime', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => WorkLog.fromFirestore(doc)).toList());
  }

  Stream<WorkLog?> watchActiveWorkLog(String userId) {
    return workLogsRef(userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return WorkLog.fromFirestore(snapshot.docs.first);
    });
  }

  Future<String> createWorkLog(String userId, WorkLog log) async {
    final doc = await workLogsRef(userId).add(log.toFirestore());
    return doc.id;
  }

  Future<void> updateWorkLog(String userId, String logId, Map<String, dynamic> data) async {
    await workLogsRef(userId).doc(logId).update(data);
  }

  // Projects
  CollectionReference<Map<String, dynamic>> projectsRef(String userId) =>
      userRef(userId).collection('projects');

  Stream<List<Project>> watchProjects(String userId) {
    return projectsRef(userId).where('isActive', isEqualTo: true).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Project.fromFirestore(doc)).toList());
  }

  Future<String> createProject(String userId, Project project) async {
    final doc = await projectsRef(userId).add(project.toFirestore());
    return doc.id;
  }

  // Alarms
  CollectionReference<Map<String, dynamic>> alarmsRef(String userId) =>
      userRef(userId).collection('alarms');

  Stream<List<Alarm>> watchAlarms(String userId) {
    return alarmsRef(userId).orderBy('hour').orderBy('minute').snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Alarm.fromFirestore(doc)).toList());
  }

  Future<String> createAlarm(String userId, Alarm alarm) async {
    final doc = await alarmsRef(userId).add(alarm.toFirestore());
    return doc.id;
  }

  Future<void> updateAlarm(String userId, String alarmId, Map<String, dynamic> data) async {
    await alarmsRef(userId).doc(alarmId).update(data);
  }

  Future<void> deleteAlarm(String userId, String alarmId) async {
    await alarmsRef(userId).doc(alarmId).delete();
  }

  // Achievements
  CollectionReference<Map<String, dynamic>> achievementsRef(String userId) =>
      userRef(userId).collection('achievements');

  Stream<List<UserAchievement>> watchUserAchievements(String userId) {
    return achievementsRef(userId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserAchievement.fromFirestore(doc)).toList());
  }

  Future<void> unlockAchievement(String userId, String achievementId) async {
    final existing = await achievementsRef(userId)
        .where('achievementId', isEqualTo: achievementId)
        .get();

    if (existing.docs.isEmpty) {
      await achievementsRef(userId).add({
        'userId': userId,
        'achievementId': achievementId,
        'unlockedAt': FieldValue.serverTimestamp(),
        'progress': 1,
        'target': 1,
      });
    }
  }

  // Subjects (for study)
  CollectionReference<Map<String, dynamic>> subjectsRef(String userId) =>
      userRef(userId).collection('subjects');

  Stream<List<Subject>> watchSubjects(String userId) {
    return subjectsRef(userId).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList());
  }

  Future<String> createSubject(String userId, Subject subject) async {
    final doc = await subjectsRef(userId).add(subject.toFirestore());
    return doc.id;
  }

  // Transactions (Money)
  CollectionReference<Map<String, dynamic>> transactionsRef(String userId) =>
      userRef(userId).collection('transactions');

  Stream<List<Transaction>> watchTransactions(String userId) {
    return transactionsRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList());
  }

  Future<List<Transaction>> getTransactionsInRange(
      String userId, DateTime start, DateTime end) async {
    final snapshot = await transactionsRef(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
  }

  Future<String> createTransaction(String userId, Transaction transaction) async {
    final doc = await transactionsRef(userId).add(transaction.toFirestore());
    return doc.id;
  }

  Future<void> updateTransaction(
      String userId, String transactionId, Map<String, dynamic> data) async {
    await transactionsRef(userId).doc(transactionId).update(data);
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    await transactionsRef(userId).doc(transactionId).delete();
  }

  // Food Entries
  CollectionReference<Map<String, dynamic>> foodEntriesRef(String userId) =>
      userRef(userId).collection('foodEntries');

  Stream<List<FoodEntry>> watchFoodEntries(String userId) {
    return foodEntriesRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FoodEntry.fromFirestore(doc)).toList());
  }

  Future<List<FoodEntry>> getFoodEntriesForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final snapshot = await foodEntriesRef(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .get();
    return snapshot.docs.map((doc) => FoodEntry.fromFirestore(doc)).toList();
  }

  Future<String> createFoodEntry(String userId, FoodEntry entry) async {
    final doc = await foodEntriesRef(userId).add(entry.toFirestore());
    return doc.id;
  }

  Future<void> updateFoodEntry(
      String userId, String entryId, Map<String, dynamic> data) async {
    await foodEntriesRef(userId).doc(entryId).update(data);
  }

  Future<void> deleteFoodEntry(String userId, String entryId) async {
    await foodEntriesRef(userId).doc(entryId).delete();
  }

  // Batch operations
  WriteBatch batch() => _firestore.batch();

  // Delete all user data
  Future<void> deleteUserData(String userId) async {
    final userDoc = userRef(userId);

    // Delete all subcollections
    final subcollections = [
      'tasks',
      'quests',
      'workouts',
      'studySessions',
      'workLogs',
      'projects',
      'alarms',
      'achievements',
      'subjects',
      'transactions',
      'foodEntries',
    ];

    for (final collection in subcollections) {
      final snapshot = await userDoc.collection(collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    // Delete the user document itself
    await userDoc.delete();
  }
}

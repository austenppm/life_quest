import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/food_entry.dart';
import '../models/transaction.dart';
import '../models/workout.dart';
import '../models/task.dart';

/// Service for exporting user data to CSV and JSON formats
class DataExportService {
  final String userId;

  DataExportService(this.userId);

  /// Export all data to a JSON backup file
  Future<String> exportAllToJson() async {
    final data = <String, dynamic>{
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'userId': userId,
    };

    // Export food entries
    data['foodEntries'] = await _exportFoodEntries();

    // Export transactions
    data['transactions'] = await _exportTransactions();

    // Export workouts
    data['workouts'] = await _exportWorkouts();

    // Export tasks
    data['tasks'] = await _exportTasks();

    // Export water intake
    data['waterIntake'] = await _exportWaterIntake();

    // Export body measurements
    data['bodyMeasurements'] = await _exportBodyMeasurements();

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final file = await _saveToFile('life_quest_backup', 'json', jsonString);
    return file.path;
  }

  /// Export food entries to CSV
  Future<String> exportFoodToCSV() async {
    final entries = await _exportFoodEntries();

    final headers = [
      'Date',
      'Meal',
      'Name',
      'Calories',
      'Protein (g)',
      'Carbs (g)',
      'Fat (g)',
      'Fiber (g)',
      'Sugar (g)',
      'Serving Size',
      'Unit',
      'Notes'
    ];

    final rows = <List<String>>[headers];

    for (final entry in entries) {
      rows.add([
        entry['date'] ?? '',
        entry['mealType'] ?? '',
        _escapeCsv(entry['name'] ?? ''),
        entry['calories']?.toString() ?? '',
        entry['protein']?.toString() ?? '',
        entry['carbs']?.toString() ?? '',
        entry['fat']?.toString() ?? '',
        entry['fiber']?.toString() ?? '',
        entry['sugar']?.toString() ?? '',
        entry['servingSize']?.toString() ?? '',
        entry['servingUnit'] ?? '',
        _escapeCsv(entry['notes'] ?? ''),
      ]);
    }

    final csv = rows.map((r) => r.join(',')).join('\n');
    final file = await _saveToFile('food_diary', 'csv', csv);
    return file.path;
  }

  /// Export transactions to CSV
  Future<String> exportTransactionsToCSV() async {
    final transactions = await _exportTransactions();

    final headers = [
      'Date',
      'Type',
      'Amount',
      'Category',
      'Note',
      'Is Recurring'
    ];

    final rows = <List<String>>[headers];

    for (final t in transactions) {
      rows.add([
        t['date'] ?? '',
        t['type'] ?? '',
        t['amount']?.toString() ?? '',
        t['categoryId'] ?? '',
        _escapeCsv(t['note'] ?? ''),
        t['isRecurring']?.toString() ?? 'false',
      ]);
    }

    final csv = rows.map((r) => r.join(',')).join('\n');
    final file = await _saveToFile('transactions', 'csv', csv);
    return file.path;
  }

  /// Export workouts to CSV
  Future<String> exportWorkoutsToCSV() async {
    final workouts = await _exportWorkouts();

    final headers = [
      'Date',
      'Name',
      'Duration (min)',
      'Exercises',
      'Total Sets',
      'Total Volume (kg)',
      'Calories Burned',
      'Notes'
    ];

    final rows = <List<String>>[headers];

    for (final w in workouts) {
      final exercises = (w['exercises'] as List?) ?? [];
      int totalSets = 0;
      double totalVolume = 0;

      for (final e in exercises) {
        final sets = (e['sets'] as List?) ?? [];
        totalSets += sets.length;
        for (final s in sets) {
          final weight = (s['weight'] as num?)?.toDouble() ?? 0;
          final reps = (s['reps'] as num?)?.toInt() ?? 0;
          totalVolume += weight * reps;
        }
      }

      rows.add([
        w['date'] ?? '',
        _escapeCsv(w['name'] ?? ''),
        w['durationMinutes']?.toString() ?? '',
        exercises.length.toString(),
        totalSets.toString(),
        totalVolume.toStringAsFixed(1),
        w['caloriesBurned']?.toString() ?? '',
        _escapeCsv(w['notes'] ?? ''),
      ]);
    }

    final csv = rows.map((r) => r.join(',')).join('\n');
    final file = await _saveToFile('workouts', 'csv', csv);
    return file.path;
  }

  /// Export tasks to CSV
  Future<String> exportTasksToCSV() async {
    final tasks = await _exportTasks();

    final headers = [
      'Title',
      'Type',
      'Priority',
      'Status',
      'Due Date',
      'XP Reward',
      'Current Streak',
      'Best Streak',
      'Times Completed',
      'Description'
    ];

    final rows = <List<String>>[headers];

    for (final t in tasks) {
      rows.add([
        _escapeCsv(t['title'] ?? ''),
        t['type'] ?? '',
        t['priority'] ?? '',
        t['status'] ?? '',
        t['dueDate'] ?? '',
        t['xpReward']?.toString() ?? '',
        t['currentStreak']?.toString() ?? '',
        t['bestStreak']?.toString() ?? '',
        ((t['completedDates'] as List?)?.length ?? 0).toString(),
        _escapeCsv(t['description'] ?? ''),
      ]);
    }

    final csv = rows.map((r) => r.join(',')).join('\n');
    final file = await _saveToFile('tasks', 'csv', csv);
    return file.path;
  }

  /// Export weight/body measurements to CSV
  Future<String> exportBodyMeasurementsToCSV() async {
    final measurements = await _exportBodyMeasurements();

    final headers = [
      'Date',
      'Weight (kg)',
      'Body Fat (%)',
      'Neck (cm)',
      'Shoulders (cm)',
      'Chest (cm)',
      'Waist (cm)',
      'Hips (cm)',
      'Left Bicep (cm)',
      'Right Bicep (cm)',
      'Left Thigh (cm)',
      'Right Thigh (cm)',
    ];

    final rows = <List<String>>[headers];

    for (final m in measurements) {
      rows.add([
        m['date'] ?? '',
        m['weight']?.toString() ?? '',
        m['bodyFat']?.toString() ?? '',
        m['neck']?.toString() ?? '',
        m['shoulders']?.toString() ?? '',
        m['chest']?.toString() ?? '',
        m['waist']?.toString() ?? '',
        m['hips']?.toString() ?? '',
        m['leftBicep']?.toString() ?? '',
        m['rightBicep']?.toString() ?? '',
        m['leftThigh']?.toString() ?? '',
        m['rightThigh']?.toString() ?? '',
      ]);
    }

    final csv = rows.map((r) => r.join(',')).join('\n');
    final file = await _saveToFile('body_measurements', 'csv', csv);
    return file.path;
  }

  /// Share exported file
  Future<void> shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)]);
  }

  // Helper methods

  Future<List<Map<String, dynamic>>> _exportFoodEntries() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('foodEntries')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'date': _formatDate((data['date'] as Timestamp?)?.toDate()),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportTransactions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'date': _formatDate((data['date'] as Timestamp?)?.toDate()),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportWorkouts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'date': _formatDate((data['date'] as Timestamp?)?.toDate()),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportTasks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'dueDate': _formatDate((data['dueDate'] as Timestamp?)?.toDate()),
        'createdAt': _formatDate((data['createdAt'] as Timestamp?)?.toDate()),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportWaterIntake() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('waterIntake')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'timestamp': _formatDateTime((data['timestamp'] as Timestamp?)?.toDate()),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportBodyMeasurements() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('bodyMeasurements')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        ...data,
        'date': _formatDate((data['date'] as Timestamp?)?.toDate()),
      };
    }).toList();
  }

  Future<File> _saveToFile(String baseName, String extension, String content) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${baseName}_$timestamp.$extension';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

/// Export type options
enum ExportType {
  allJson('Full Backup (JSON)', 'Complete backup of all your data'),
  foodCsv('Food Diary (CSV)', 'Export food entries to spreadsheet'),
  transactionsCsv('Transactions (CSV)', 'Export financial data to spreadsheet'),
  workoutsCsv('Workouts (CSV)', 'Export workout history to spreadsheet'),
  tasksCsv('Tasks (CSV)', 'Export tasks to spreadsheet'),
  measurementsCsv('Body Measurements (CSV)', 'Export weight and measurements');

  final String displayName;
  final String description;
  const ExportType(this.displayName, this.description);
}

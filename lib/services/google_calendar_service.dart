import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/task.dart';
import '../models/quest.dart';

/// Configuration for Google Calendar API
class GoogleCalendarConfig {
  // You need to set these up in Google Cloud Console
  static const String clientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
  static const String clientSecret = 'YOUR_CLIENT_SECRET'; // For installed apps
  
  static const List<String> scopes = [
    gcal.CalendarApi.calendarReadonlyScope,
    gcal.CalendarApi.calendarEventsScope,
  ];
}

/// Represents a calendar event from Google Calendar
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime? start;
  final DateTime? end;
  final bool isAllDay;
  final String? recurrence;
  final String? location;
  final String? calendarId;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    this.start,
    this.end,
    this.isAllDay = false,
    this.recurrence,
    this.location,
    this.calendarId,
  });

  factory CalendarEvent.fromGoogleEvent(gcal.Event event, {String? calendarId}) {
    final start = event.start;
    final end = event.end;
    
    DateTime? startTime;
    DateTime? endTime;
    bool isAllDay = false;

    if (start?.dateTime != null) {
      startTime = start!.dateTime!.toLocal();
    } else if (start?.date != null) {
      // All-day event - date is already a DateTime
      startTime = start!.date!;
      isAllDay = true;
    }

    if (end?.dateTime != null) {
      endTime = end!.dateTime!.toLocal();
    } else if (end?.date != null) {
      endTime = end!.date!;
    }

    return CalendarEvent(
      id: event.id ?? '',
      title: event.summary ?? 'Untitled Event',
      description: event.description,
      start: startTime,
      end: endTime,
      isAllDay: isAllDay,
      recurrence: event.recurrence?.join(', '),
      location: event.location,
      calendarId: calendarId,
    );
  }

  /// Convert calendar event to a task
  Task toTask({required String userId}) {
    return Task(
      id: 'cal_$id',
      userId: userId,
      title: title,
      description: description,
      type: recurrence != null ? TaskType.daily : TaskType.oneTime,
      stat: 'discipline', // Default, AI can change this
      xpReward: 10,
      dueDate: start,
      createdAt: DateTime.now(),
      isFromCalendar: true,
      calendarEventId: id,
    );
  }
}

/// Google Calendar service for syncing events
class GoogleCalendarService {
  AutoRefreshingAuthClient? _client;
  gcal.CalendarApi? _calendarApi;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isAvailable => _calendarApi != null;

  /// Initialize authentication (call on app start if previously authenticated)
  Future<bool> initializeFromSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCredentials = prefs.getString('google_calendar_credentials');
      
      if (savedCredentials != null) {
        final credentials = AccessCredentials.fromJson(
          jsonDecode(savedCredentials) as Map<String, dynamic>,
        );
        
        _client = autoRefreshingClient(
          ClientId(GoogleCalendarConfig.clientId, GoogleCalendarConfig.clientSecret),
          credentials,
          http.Client(),
        );
        
        _calendarApi = gcal.CalendarApi(_client!);
        _isAuthenticated = true;
        return true;
      }
    } catch (e) {
      print('Error initializing Google Calendar: $e');
    }
    return false;
  }

  /// Authenticate with Google Calendar
  Future<bool> authenticate() async {
    try {
      final clientId = ClientId(
        GoogleCalendarConfig.clientId,
        GoogleCalendarConfig.clientSecret,
      );

      // For mobile apps, use userPrompt to open browser
      _client = await clientViaUserConsent(
        clientId,
        GoogleCalendarConfig.scopes,
        (url) async {
          // Open the authorization URL in browser
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      );

      if (_client != null) {
        _calendarApi = gcal.CalendarApi(_client!);
        _isAuthenticated = true;

        // Save credentials for later
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'google_calendar_credentials',
          jsonEncode(_client!.credentials.toJson()),
        );

        return true;
      }
    } catch (e) {
      print('Google Calendar auth error: $e');
    }
    return false;
  }

  /// Sign out and clear saved credentials
  Future<void> signOut() async {
    _client?.close();
    _client = null;
    _calendarApi = null;
    _isAuthenticated = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('google_calendar_credentials');
  }

  /// Get list of user's calendars
  Future<List<gcal.CalendarListEntry>> getCalendarList() async {
    if (!isAvailable) return [];

    try {
      final calendarList = await _calendarApi!.calendarList.list();
      return calendarList.items ?? [];
    } catch (e) {
      print('Error getting calendar list: $e');
      return [];
    }
  }

  /// Get events for today
  Future<List<CalendarEvent>> getTodayEvents({String? calendarId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getEvents(
      calendarId: calendarId ?? 'primary',
      timeMin: startOfDay,
      timeMax: endOfDay,
    );
  }

  /// Get events for this week
  Future<List<CalendarEvent>> getWeekEvents({String? calendarId}) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfDay.add(const Duration(days: 7));
    
    return getEvents(
      calendarId: calendarId ?? 'primary',
      timeMin: startOfDay,
      timeMax: endOfWeek,
    );
  }

  /// Get events in a date range
  Future<List<CalendarEvent>> getEvents({
    required String calendarId,
    DateTime? timeMin,
    DateTime? timeMax,
    int maxResults = 50,
  }) async {
    if (!isAvailable) return [];

    try {
      final events = await _calendarApi!.events.list(
        calendarId,
        timeMin: timeMin?.toUtc(),
        timeMax: timeMax?.toUtc(),
        maxResults: maxResults,
        singleEvents: true,
        orderBy: 'startTime',
      );

      return (events.items ?? [])
          .map((e) => CalendarEvent.fromGoogleEvent(e, calendarId: calendarId))
          .toList();
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }

  /// Create an event on the calendar (for exporting tasks/quests)
  Future<CalendarEvent?> createEvent({
    required String title,
    String? description,
    required DateTime start,
    DateTime? end,
    bool isAllDay = false,
    String calendarId = 'primary',
  }) async {
    if (!isAvailable) return null;

    try {
      final event = gcal.Event()
        ..summary = title
        ..description = description;

      if (isAllDay) {
        event.start = gcal.EventDateTime()
          ..date = DateTime(start.year, start.month, start.day);
        final endDate = end ?? start.add(const Duration(days: 1));
        event.end = gcal.EventDateTime()
          ..date = DateTime(endDate.year, endDate.month, endDate.day);
      } else {
        event.start = gcal.EventDateTime()
          ..dateTime = start.toUtc()
          ..timeZone = 'UTC';
        event.end = gcal.EventDateTime()
          ..dateTime = (end ?? start.add(const Duration(hours: 1))).toUtc()
          ..timeZone = 'UTC';
      }

      final createdEvent = await _calendarApi!.events.insert(event, calendarId);
      return CalendarEvent.fromGoogleEvent(createdEvent, calendarId: calendarId);
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  /// Export a task to Google Calendar
  Future<CalendarEvent?> exportTask(Task task, {String calendarId = 'primary'}) async {
    if (task.dueDate == null) return null;

    return createEvent(
      title: '[Task] ${task.title}',
      description: '${task.description ?? ''}\n\nStats: ${task.stat}\nXP: ${task.xpReward}',
      start: task.dueDate!,
      isAllDay: true,
      calendarId: calendarId,
    );
  }

  /// Export a quest deadline to Google Calendar
  Future<CalendarEvent?> exportQuestDeadline(Quest quest, {String calendarId = 'primary'}) async {
    if (quest.deadline == null) return null;

    final subtaskList = quest.subtasks.map((s) => '- ${s.title}').join('\n');

    return createEvent(
      title: '[Quest] ${quest.title}',
      description: '${quest.description ?? ''}\n\nDifficulty: ${quest.difficulty.name}\nXP: ${quest.xpReward}\n\nSubtasks:\n$subtaskList',
      start: quest.deadline!,
      isAllDay: true,
      calendarId: calendarId,
    );
  }

  /// Delete an event from calendar
  Future<bool> deleteEvent(String eventId, {String calendarId = 'primary'}) async {
    if (!isAvailable) return false;

    try {
      await _calendarApi!.events.delete(calendarId, eventId);
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  /// Convert recurring calendar events to daily tasks
  List<Task> convertRecurringEventsToTasks(
    List<CalendarEvent> events,
    String userId,
  ) {
    return events
        .where((e) => e.recurrence != null)
        .map((e) => e.toTask(userId: userId))
        .toList();
  }
}

// Add isFromCalendar field to Task model
extension TaskCalendarExtension on Task {
  bool get isFromCalendar => false; // Will be set properly when created
}

/// Provider for Google Calendar service
final googleCalendarServiceProvider = Provider<GoogleCalendarService>((ref) {
  return GoogleCalendarService();
});

/// Provider for today's calendar events
final todayCalendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final service = ref.watch(googleCalendarServiceProvider);
  if (!service.isAuthenticated) return [];
  return service.getTodayEvents();
});

/// Provider for week's calendar events
final weekCalendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final service = ref.watch(googleCalendarServiceProvider);
  if (!service.isAuthenticated) return [];
  return service.getWeekEvents();
});

/// Provider for calendar authentication state
final calendarAuthStateProvider = StateProvider<bool>((ref) {
  return ref.watch(googleCalendarServiceProvider).isAuthenticated;
});

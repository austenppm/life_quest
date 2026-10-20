# Life Quest - Expanded Stats, Calendar Sync & Weight Tracker Implementation

## Overview
This update adds an expanded 10-stat system (up from 6), Google Calendar sync, Gemini AI-powered automatic stat detection for tasks, and a comprehensive weight tracker.

## 1. Expanded 10-Stat System

### Physical Stats
- **Strength (STR)** - Physical power, weightlifting, carrying
- **Dexterity (DEX)** - Agility, cardio, running, flexibility, balance
- **Constitution (CON)** - Health, nutrition, sleep, endurance

### Mental Stats
- **Intelligence (INT)** - Learning, studying, reading, courses
- **Wisdom (WIS)** - Mindfulness, meditation, perception, insight
- **Focus (FOC)** - Concentration, deep work, attention

### Social Stats
- **Charisma (CHA)** - Leadership, public speaking, persuasion
- **Social (SOC)** - Networking, relationships, communication

### Lifestyle Stats
- **Discipline (DIS)** - Habits, routines, consistency, work ethic
- **Creativity (CRE)** - Art, music, writing, design, innovation

## 2. AI-Powered Stat Detection

When creating a new task, users can tap the ✨ (AI) button to have Gemini analyze the task and automatically:
- Detect which stats (1-3) the task affects
- Suggest XP amounts for each stat
- Calculate total XP reward based on difficulty
- Provide reasoning for the suggestions
- Add relevant tags

### How it works:
1. User enters task title (e.g., "30-minute morning run")
2. User taps AI analyze button
3. Gemini analyzes the task and responds:
   - Stats: { dexterity: 15, constitution: 10 }
   - Total XP: 20
   - Reasoning: "Running improves cardiovascular health and endurance"
   - Tags: ["cardio", "morning-routine"]
4. User can accept or modify suggestions
5. Task is created with multi-stat rewards

### Fallback Analysis:
If Gemini API is unavailable, keyword-based detection:
- "workout", "gym", "lift" → Strength
- "run", "cardio", "yoga" → Dexterity
- "eat", "sleep", "health" → Constitution
- "study", "learn", "read" → Intelligence
- "meditate", "journal" → Wisdom
- "focus", "deep work" → Focus
- "present", "lead" → Charisma
- "meet", "call", "friend" → Social
- "routine", "clean", "plan" → Discipline
- "art", "write", "create" → Creativity

## 3. Google Calendar Sync

### Features:
- Connect Google Calendar account
- View today's and week's calendar events
- Import events as tasks (one-time or recurring)
- AI analyzes imported events to detect stats
- Export tasks/quests to Google Calendar

### Sync Settings:
- **Auto Import Events** - Automatically create tasks from calendar events
- **AI Stat Detection** - Use Gemini to detect stats for imported events

### Integration Flow:
1. User connects Google Calendar in Profile → Calendar Sync
2. Calendar events are loaded
3. Each event is analyzed by Gemini AI
4. Events become tasks with appropriate stat rewards
5. Completing tasks awards XP to detected stats

## 4. Updated Task Model

Tasks now support:
```dart
class Task {
  // Multi-stat support
  Map<String, int> statRewards;  // e.g., {"dexterity": 15, "strength": 10}
  String stat;  // Primary stat (backward compatibility)
  
  // Calendar integration
  bool isFromCalendar;
  String? calendarEventId;
  
  // AI analysis
  String? aiReasoning;
  List<String> tags;
}
```

## 5. Updated XP System

The XP service now handles multi-stat rewards:
```dart
// When completing a task with multiple stats:
await xpService.awardTaskXPMultiStat(
  userId: userId,
  task: task,  // Contains statRewards map
  profile: profile,
);

// Each stat in statRewards receives its XP amount
```

## 6. Updated Screens

### Stats Screen (`/stats`)
- Radar chart showing all 10 stats
- Tabs: All, Physical, Mental, Social, Lifestyle
- Category summaries with stat descriptions
- XP progress bars for each stat
- D&D-style modifiers displayed

### Dashboard
- Updated radar chart with 10 stats
- Stat highlights showing highest/lowest stats
- Quick stat pill indicators

### Create Task Dialog
- AI analyze button ✨
- Multi-stat selection (tap to toggle, long-press for XP)
- AI suggestion card with reasoning
- Toggle to accept/ignore AI suggestions

### Calendar Sync Screen (`/calendar-sync`)
- Google Calendar connection status
- Sync settings toggles
- Today's events preview
- Import individual or all events

## 7. File Changes

### New Files:
- `lib/services/google_calendar_service.dart` - Calendar integration
- `lib/screens/settings/calendar_sync_screen.dart` - Calendar UI

### Updated Files:
- `lib/models/user_profile.dart` - 10 stats with XP tracking
- `lib/models/task.dart` - Multi-stat support, calendar fields
- `lib/services/ai_service.dart` - Task analysis, quest analysis
- `lib/services/xp_service.dart` - Multi-stat XP awarding
- `lib/theme/app_theme.dart` - 10 stat colors and helpers
- `lib/screens/stats/stats_screen.dart` - Full stat display
- `lib/screens/tasks/create_task_dialog.dart` - AI analysis
- `lib/screens/dashboard/dashboard_content.dart` - 10-stat radar
- `lib/screens/profile/profile_screen.dart` - Calendar menu item
- `lib/providers/task_provider.dart` - Multi-stat task creation
- `lib/app.dart` - Calendar sync route
- `pubspec.yaml` - Google APIs dependencies

## 8. Dependencies Added

```yaml
# Google Calendar API
googleapis: ^12.0.0
googleapis_auth: ^1.4.1
url_launcher: ^6.2.2
http: ^1.1.2
```

## 9. Setup Required

### Google Cloud Console:
1. Create a project
2. Enable Google Calendar API
3. Create OAuth 2.0 credentials
4. Add credentials to `google_calendar_service.dart`

### Environment Variables (.env):
```
GEMINI_API_KEY=your_gemini_api_key
```

## 10. Usage Examples

### Creating a Task with AI Analysis:
1. Open Tasks → Add Task
2. Type "Study Japanese for 1 hour"
3. Tap ✨ AI button
4. AI suggests: Intelligence +15, Focus +10, Discipline +5
5. Review and adjust if needed
6. Create task

### Importing Calendar Events:
1. Go to Profile → Calendar Sync
2. Connect Google Calendar
3. View today's events
4. Tap import on "Team meeting at 3pm"
5. AI detects: Charisma +10, Social +15
6. Event becomes a task with stat rewards

## 11. Weight Tracker

### Features:
- **Log Weight**: Record daily weight with optional notes
- **Unit Support**: Toggle between kg and lbs
- **Goal Setting**: Set weight loss/gain/maintain goals with target dates
- **Progress Charts**: Visual 30-day weight trend chart
- **Statistics**:
  - Current, lowest, highest, and average weight
  - Weekly and monthly change
  - Logging streak
- **History View**: Grouped by month with full entry history
- **XP Rewards**: Earn Constitution and Discipline XP for logging
  - +15 XP for first daily log
  - +5 XP for additional logs same day

### Location: `/weight`

### Data Model:
```dart
class WeightEntry {
  String id;
  String userId;
  double weight;
  WeightUnit unit; // kg or lbs
  DateTime date;
  String? note;
  double? bodyFat;
  double? muscleMass;
  double? waterPercentage;
  Map<String, double>? measurements;
}

class WeightGoal {
  double targetWeight;
  double startWeight;
  DateTime startDate;
  DateTime? targetDate;
  String goalType; // 'lose', 'gain', 'maintain'
}
```

### Statistics Tracked:
- Current weight
- Lowest/highest weight (all-time)
- Average weight
- Weekly change
- Monthly change
- Total change
- Logging streak

### UI Components:
1. **Overview Tab**:
   - Current weight card with weekly change
   - Goal progress (if set)
   - Quick stats (streak, entries, today status)
   - 30-day weight chart
   - Pro tips

2. **History Tab**:
   - Entries grouped by month
   - Edit/delete entries
   - Notes display

3. **Stats Tab**:
   - All-time statistics
   - Recent changes (weekly/monthly)
   - Consistency/streak info

### Files:
- `lib/models/weight_entry.dart` - Weight entry & goal models
- `lib/providers/weight_provider.dart` - State management
- `lib/screens/weight/weight_tracker_screen.dart` - Full UI

### Access Points:
- Profile → Weight Tracker
- Dashboard → Quick Actions → Log Weight
- Route: `/weight`

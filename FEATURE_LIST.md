# Life Quest App - Complete Feature List

## 🎮 Core Gamification System

### Character Stats (10 Stats - D&D Style)
| Category | Stat | Abbrev | Description |
|----------|------|--------|-------------|
| **Physical** | Strength | STR | Physical power, weightlifting |
| | Dexterity | DEX | Agility, cardio, flexibility |
| | Constitution | CON | Health, nutrition, sleep, endurance |
| **Mental** | Intelligence | INT | Learning, studying, reading |
| | Wisdom | WIS | Mindfulness, meditation, insight |
| | Focus | FOC | Concentration, deep work |
| **Social** | Charisma | CHA | Leadership, public speaking |
| | Social | SOC | Networking, relationships |
| **Lifestyle** | Discipline | DIS | Habits, routines, consistency |
| | Creativity | CRE | Art, music, writing, design |

### XP & Leveling System
- Character level with XP progression
- Individual stat levels with separate XP
- Stat modifiers (D&D style: (level - 10) / 2)
- Streak bonuses for consistent completion
- Level-up notifications

---

## ✅ Task Management

### Task Types
- **Daily Tasks**: Recurring daily habits
- **One-Time Tasks**: Single completion tasks
- **Custom Frequency**: Weekdays, weekends, or specific days

### Task Features
- Multi-stat XP rewards (tasks can affect 1-3 stats)
- AI-powered stat detection (Gemini)
- Streak tracking (current & best)
- Due dates and reminders
- Task completion history
- Sort order customization
- Tags support

### AI Task Analysis
- Automatic stat detection from task title/description
- Suggested XP amounts per stat
- Reasoning explanation
- Keyword-based fallback if AI unavailable

---

## 🏆 Quest System

### Quest Features
- Multi-step quests with subtasks
- Difficulty levels: Easy, Medium, Hard, Epic, Legendary
- XP multipliers based on difficulty
- Progress tracking (percentage complete)
- Category organization
- Start/end dates

### Quest AI Analysis
- Auto-generate subtasks from quest description
- Difficulty suggestion
- Stat reward recommendations

---

## 💪 Workout Tracking

### Workout Logging
- Exercise library (custom exercises)
- Sets, reps, and weight tracking
- Duration tracking
- Workout templates
- Exercise history

### Workout Stats
- Total workouts logged
- Exercises performed
- Personal records
- XP rewards: Dexterity, Strength, Constitution, Discipline

---

## 📚 Study Tracking

### Study Sessions
- Timer-based sessions
- Subject/topic categorization
- Focus score tracking
- Break reminders
- Session history

### Study Stats
- Total study time
- Sessions completed
- XP rewards: Intelligence, Focus, Discipline

---

## 💼 Work Tracking

### Work Logging
- Clock in/out functionality
- Task completion within work sessions
- Duration tracking
- Notes support

### Work Stats
- Total hours worked
- Tasks completed
- XP rewards: Discipline

---

## ⚖️ Weight Tracker

### Weight Logging
- Daily weight entries
- Unit toggle (kg/lbs)
- Optional notes
- Advanced metrics: body fat %, muscle mass, water %
- Body measurements support

### Weight Goals
- Goal types: Lose, Gain, Maintain
- Target weight setting
- Target date (optional)
- Progress percentage tracking

### Weight Statistics
- Current, lowest, highest, average weight
- Weekly and monthly change
- Total change from start
- Logging streak

### Weight Visualization
- 30-day trend chart
- Progress indicators
- XP rewards: Constitution, Discipline (+15 XP daily)

---

## 🍎 Food & Nutrition Tracking

### Food Logging
- Meal categories: Breakfast, Lunch, Dinner, Snacks
- Calorie tracking
- Macronutrients: Protein, Carbs, Fat, Fiber
- Micronutrients support
- Meal photos (optional)

### Nutrition Goals
- Daily calorie targets
- Macro targets
- Progress tracking

### Food Statistics
- Daily/weekly/monthly summaries
- Nutrient breakdowns
- XP rewards: Constitution, Wisdom

---

## 💰 Money Management

### Accounts
- Multiple account support
- Account types: Cash, Bank, Credit Card, Savings, Investment
- Balance tracking per account

### Transactions
- Income and expense tracking
- Category organization (40+ preset categories)
- Custom categories
- Recurring transactions
- Transaction notes
- Date selection

### Budget Features
- Monthly income/expense summaries
- Category-wise spending breakdown
- Balance trends

### Money Statistics
- Total balance across accounts
- Monthly income vs expenses
- Transaction history with filters

---

## ⏰ Alarms & Reminders

### Alarm Features
- Custom alarm times
- Repeat patterns (daily, weekdays, weekends, custom)
- Snooze functionality
- Alarm labels
- Sound customization

### Reminder Integration
- Task due date reminders
- Quest deadline reminders
- Habit reminders

---

## 🏅 Achievements System

### Achievement Categories
- Fitness achievements
- Study achievements
- Work achievements
- Social achievements
- Consistency achievements
- Milestone achievements

### Achievement Features
- Progress tracking
- Unlock notifications
- XP bonuses for unlocking
- Rarity levels

---

## 📅 Google Calendar Sync

### Calendar Integration
- Google OAuth authentication
- Import calendar events as tasks
- View today's/week's events
- Export tasks to calendar

### AI Event Analysis
- Auto-detect stats from event titles
- Suggest XP rewards
- Tag generation

### Sync Settings
- Auto-import toggle
- AI analysis toggle

---

## 📊 Statistics & Analytics

### Stats Screen
- 10-stat radar chart
- Category tabs: All, Physical, Mental, Social, Lifestyle
- Individual stat cards with:
  - Current level
  - XP progress to next level
  - Stat modifier
  - Description

### Dashboard Analytics
- Character overview
- Today's task completion
- Active quests
- Recent activity
- Quick action buttons

---

## 👤 User Profile

### Profile Features
- Display name and avatar
- Email display
- Character level badge
- XP progress bar

### Profile Menu
- Statistics
- Weight Tracker
- Achievements
- Calendar Sync
- Alarms
- Settings
- Sign out

---

## ⚙️ Settings

### App Settings
- Theme preferences
- Notification settings
- Unit preferences (metric/imperial)
- Data export
- Account management

---

## 🔐 Authentication

### Auth Features
- Email/password registration
- Email/password login
- Google Sign-In
- Password reset
- Session persistence

---

## 🤖 AI Integration (Gemini)

### AI Features
- Task stat detection
- Quest subtask generation
- Calendar event analysis
- Personalized recommendations
- Keyword fallback system

---

## 🔔 Notifications

### Notification Types
- Task reminders
- Quest deadlines
- Level-up celebrations
- Achievement unlocks
- Streak warnings
- Daily summaries

---

## 📱 UI/UX Features

### Navigation
- Bottom navigation bar (5 tabs)
- Drawer menu
- Deep linking support
- Pull-to-refresh

### Design
- Dark theme
- Custom color scheme per stat
- Animated transitions
- Charts and visualizations
- Responsive layouts

---

## 📁 Data Management

### Storage
- Firebase Firestore (cloud sync)
- Real-time updates
- Offline support (cached)

### Data Models
- User profiles
- Tasks
- Quests
- Workouts
- Study sessions
- Work logs
- Weight entries
- Food entries
- Transactions
- Alarms
- Achievements

---

## 🛠️ Technical Stack

### Frontend
- Flutter (Dart)
- Riverpod (state management)
- GoRouter (navigation)
- FL Chart (visualizations)

### Backend
- Firebase Authentication
- Cloud Firestore
- Google APIs (Calendar)
- Gemini AI API

### Key Packages
- flutter_riverpod
- go_router
- fl_chart
- firebase_core
- firebase_auth
- cloud_firestore
- google_generative_ai
- googleapis
- intl
- uuid
- equatable

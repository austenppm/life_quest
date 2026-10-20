# Life Quest 🎮

A life gamification app where **you** are the RPG character. Turn your daily tasks, habits, and goals into an epic adventure!

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## ✨ Features

### 📊 Character Stats
Level up 6 core attributes by completing related activities:
- **Fitness** - Cardio, endurance, health
- **Strength** - Physical power, muscle building
- **Intelligence** - Learning, studying, mental growth
- **Discipline** - Work ethic, consistency, habits
- **Creativity** - Art, music, writing, innovation
- **Social** - Relationships, networking, communication

### ✅ Task System
- **Daily Tasks** - Recurring habits with streak tracking
- **One-time Tasks** - Goals with optional deadlines
- **XP Rewards** - Earn experience for completions
- **Streak Bonuses** - Extra XP for consistency

### 🗺️ Quests
- Multi-step goals with subtasks
- Difficulty levels (Easy → Legendary)
- Stat-specific rewards
- Progress tracking

### 🏋️ Activity Tracking
- **Workouts** - Log exercises, sets, reps
- **Study Sessions** - Track learning time by subject
- **Work Hours** - Monitor productivity

### ⏰ Reminders & Alarms
- Task reminders
- Daily check-in notifications
- Custom alarm scheduling

### 🏆 Achievements
- Unlock badges for milestones
- Rarity tiers (Common → Legendary)
- Collection showcase

### 🤖 AI Features (Optional)
- Quest suggestions based on your stats
- Motivational messages
- Workout and study recommendations

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.2.0+)
- Dart SDK (3.2.0+)
- Firebase account
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/life_quest.git
   cd life_quest
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and add your API keys:
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. **Configure Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password and Google Sign-In)
   - Enable Cloud Firestore
   - Download and add config files:
     - Android: `google-services.json` → `android/app/`
     - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - Run FlutterFire CLI to generate `firebase_options.dart`:
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔐 Security

This app follows security best practices:

- **API keys** are stored in `.env` (git-ignored)
- **Firebase security rules** protect user data
- **Secrets** are never hardcoded in source code
- **Authentication** via Firebase Auth

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GEMINI_API_KEY` | Google Gemini AI API key | Optional (for AI features) |

## 📁 Project Structure

```
lib/
├── main.dart              # Entry point
├── app.dart               # App widget & routing
├── firebase_options.dart  # Firebase configuration
├── models/                # Data models
│   ├── user_profile.dart
│   ├── task.dart
│   ├── quest.dart
│   └── ...
├── providers/             # Riverpod state management
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   └── ...
├── screens/               # UI screens
│   ├── auth/
│   ├── home/
│   ├── tasks/
│   └── ...
├── services/              # Business logic
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── xp_service.dart
│   └── ...
├── theme/                 # App theming
│   └── app_theme.dart
├── utils/                 # Utilities
└── widgets/               # Reusable widgets
```

## 🛠️ Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore, Cloud Messaging)
- **Navigation**: Go Router
- **AI**: Google Gemini (optional)
- **Charts**: FL Chart
- **Notifications**: Flutter Local Notifications

## 🏗️ Building

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- RPG mechanics inspired by habit-building apps
- UI design inspired by modern gaming interfaces
- Icons from Material Design and Font Awesome

---

**Level up your life, one quest at a time! 🚀**

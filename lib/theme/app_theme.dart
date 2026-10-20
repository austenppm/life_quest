import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color primaryDark = Color(0xFF4834D4);

  // Background colors
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252542);
  static const Color card = Color(0xFF16162A);

  // Accent colors
  static const Color accent = Color(0xFFFFD700);
  static const Color accentSecondary = Color(0xFFFF6B6B);

  // 10 Character Stats - organized by category
  // Physical Stats
  static const Color strength = Color(0xFFFF6B6B);      // Red - power
  static const Color dexterity = Color(0xFF00D9FF);     // Cyan - agility
  static const Color constitution = Color(0xFF6BCB77); // Green - health
  
  // Mental Stats
  static const Color intelligence = Color(0xFFA29BFE); // Purple - mind
  static const Color wisdom = Color(0xFFFFD93D);        // Yellow - insight
  static const Color focus = Color(0xFF45B7D1);         // Teal - concentration
  
  // Social Stats
  static const Color charisma = Color(0xFFFF85A2);      // Pink - leadership
  static const Color social = Color(0xFFFFA07A);        // Salmon - relationships
  
  // Lifestyle Stats
  static const Color discipline = Color(0xFFE17055);    // Orange - habits
  static const Color creativity = Color(0xFFDDA0DD);    // Plum - art

  // Legacy aliases for compatibility
  static const Color fitness = dexterity;

  // Status colors
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C3);
  static const Color textMuted = Color(0xFF6B6B80);

  // XP and Level colors
  static const Color xpBar = Color(0xFF6C5CE7);
  static const Color levelBadge = Color(0xFFFFD700);

  // Get stat color by name
  static Color getStatColor(String stat) {
    switch (stat.toLowerCase()) {
      case 'strength':
      case 'str':
        return strength;
      case 'dexterity':
      case 'dex':
        return dexterity;
      case 'constitution':
      case 'con':
        return constitution;
      case 'intelligence':
      case 'int':
        return intelligence;
      case 'wisdom':
      case 'wis':
        return wisdom;
      case 'focus':
      case 'foc':
        return focus;
      case 'charisma':
      case 'cha':
        return charisma;
      case 'social':
      case 'soc':
        return social;
      case 'discipline':
      case 'dis':
        return discipline;
      case 'creativity':
      case 'cre':
        return creativity;
      // Legacy support
      case 'fitness':
        return dexterity;
      default:
        return primary;
    }
  }

  static IconData getStatIcon(String stat) {
    switch (stat.toLowerCase()) {
      case 'strength':
      case 'str':
        return Icons.fitness_center;
      case 'dexterity':
      case 'dex':
        return Icons.directions_run;
      case 'constitution':
      case 'con':
        return Icons.favorite;
      case 'intelligence':
      case 'int':
        return Icons.psychology;
      case 'wisdom':
      case 'wis':
        return Icons.visibility;
      case 'focus':
      case 'foc':
        return Icons.center_focus_strong;
      case 'charisma':
      case 'cha':
        return Icons.record_voice_over;
      case 'social':
      case 'soc':
        return Icons.people;
      case 'discipline':
      case 'dis':
        return Icons.schedule;
      case 'creativity':
      case 'cre':
        return Icons.brush;
      default:
        return Icons.star;
    }
  }

  static String getStatDescription(String stat) {
    switch (stat.toLowerCase()) {
      case 'strength':
      case 'str':
        return 'Physical power, weightlifting, carrying';
      case 'dexterity':
      case 'dex':
        return 'Agility, reflexes, cardio, flexibility';
      case 'constitution':
      case 'con':
        return 'Health, stamina, endurance, nutrition';
      case 'intelligence':
      case 'int':
        return 'Learning, memory, reasoning, study';
      case 'wisdom':
      case 'wis':
        return 'Perception, insight, mindfulness';
      case 'focus':
      case 'foc':
        return 'Concentration, deep work, attention';
      case 'charisma':
      case 'cha':
        return 'Leadership, persuasion, confidence';
      case 'social':
      case 'soc':
        return 'Networking, relationships, communication';
      case 'discipline':
      case 'dis':
        return 'Habits, consistency, work ethic';
      case 'creativity':
      case 'cre':
        return 'Art, music, writing, innovation';
      default:
        return '';
    }
  }

  static String getStatAbbreviation(String stat) {
    switch (stat.toLowerCase()) {
      case 'strength':
        return 'STR';
      case 'dexterity':
        return 'DEX';
      case 'constitution':
        return 'CON';
      case 'intelligence':
        return 'INT';
      case 'wisdom':
        return 'WIS';
      case 'focus':
        return 'FOC';
      case 'charisma':
        return 'CHA';
      case 'social':
        return 'SOC';
      case 'discipline':
        return 'DIS';
      case 'creativity':
        return 'CRE';
      default:
        return stat.substring(0, 3).toUpperCase();
    }
  }

  static String getStatCategory(String stat) {
    switch (stat.toLowerCase()) {
      case 'strength':
      case 'dexterity':
      case 'constitution':
        return 'Physical';
      case 'intelligence':
      case 'wisdom':
      case 'focus':
        return 'Mental';
      case 'charisma':
      case 'social':
        return 'Social';
      case 'discipline':
      case 'creativity':
        return 'Lifestyle';
      default:
        return 'Other';
    }
  }

  static const List<String> statNames = [
    'strength', 'dexterity', 'constitution', 'intelligence', 'wisdom',
    'focus', 'charisma', 'social', 'discipline', 'creativity'
  ];

  static const List<String> physicalStats = ['strength', 'dexterity', 'constitution'];
  static const List<String> mentalStats = ['intelligence', 'wisdom', 'focus'];
  static const List<String> socialStatsList = ['charisma', 'social'];
  static const List<String> lifestyleStats = ['discipline', 'creativity'];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceLight,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceLight,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.5);
          }
          return AppColors.surfaceLight;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.textMuted, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

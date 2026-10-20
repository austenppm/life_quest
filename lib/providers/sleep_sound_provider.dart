import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sleep_sound.dart';

/// Provider for the current playback state
final sleepSoundPlaybackProvider =
    StateNotifierProvider<SleepSoundPlaybackNotifier, SleepSoundPlaybackState>(
  (ref) => SleepSoundPlaybackNotifier(),
);

/// Provider for saved custom mixes
final customSoundMixesProvider =
    StateNotifierProvider<CustomSoundMixesNotifier, List<SleepSoundMix>>(
  (ref) => CustomSoundMixesNotifier(),
);

/// Provider for recent sounds
final recentSoundsProvider =
    StateNotifierProvider<RecentSoundsNotifier, List<String>>(
  (ref) => RecentSoundsNotifier(),
);

/// Provider for favorite sounds
final favoriteSoundsProvider =
    StateNotifierProvider<FavoriteSoundsNotifier, Set<String>>(
  (ref) => FavoriteSoundsNotifier(),
);

/// Notifier for playback state
class SleepSoundPlaybackNotifier extends StateNotifier<SleepSoundPlaybackState> {
  Timer? _timerCountdown;

  SleepSoundPlaybackNotifier() : super(const SleepSoundPlaybackState());

  /// Toggle a sound on/off
  void toggleSound(String soundId, {double initialVolume = 0.5}) {
    final activeSounds = Map<String, double>.from(state.activeSounds);

    if (activeSounds.containsKey(soundId)) {
      activeSounds.remove(soundId);
    } else {
      activeSounds[soundId] = initialVolume;
    }

    state = state.copyWith(
      activeSounds: activeSounds,
      isPlaying: activeSounds.isNotEmpty,
    );
  }

  /// Set volume for a specific sound
  void setSoundVolume(String soundId, double volume) {
    if (!state.activeSounds.containsKey(soundId)) return;

    final activeSounds = Map<String, double>.from(state.activeSounds);
    activeSounds[soundId] = volume.clamp(0.0, 1.0);

    state = state.copyWith(activeSounds: activeSounds);
  }

  /// Set master volume
  void setMasterVolume(double volume) {
    state = state.copyWith(masterVolume: volume.clamp(0.0, 1.0));
  }

  /// Load a mix
  void loadMix(SleepSoundMix mix) {
    final activeSounds = <String, double>{};
    for (final entry in mix.sounds) {
      activeSounds[entry.soundId] = entry.volume;
    }

    state = state.copyWith(
      activeSounds: activeSounds,
      isPlaying: activeSounds.isNotEmpty,
    );
  }

  /// Start sleep timer
  void startTimer(Duration duration) {
    _timerCountdown?.cancel();

    state = state.copyWith(
      timerDuration: duration,
      timerRemaining: duration,
    );

    _timerCountdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.timerRemaining;
      if (remaining == null || remaining.inSeconds <= 0) {
        stopAll();
        timer.cancel();
        return;
      }

      state = state.copyWith(
        timerRemaining: remaining - const Duration(seconds: 1),
      );
    });
  }

  /// Cancel sleep timer
  void cancelTimer() {
    _timerCountdown?.cancel();
    _timerCountdown = null;
    state = SleepSoundPlaybackState(
      isPlaying: state.isPlaying,
      activeSounds: state.activeSounds,
      masterVolume: state.masterVolume,
    );
  }

  /// Play all active sounds
  void play() {
    if (state.activeSounds.isEmpty) return;
    state = state.copyWith(isPlaying: true);
  }

  /// Pause all sounds
  void pause() {
    state = state.copyWith(isPlaying: false);
  }

  /// Stop all sounds and reset
  void stopAll() {
    _timerCountdown?.cancel();
    _timerCountdown = null;
    state = const SleepSoundPlaybackState();
  }

  /// Get current mix as SleepSoundMix
  SleepSoundMix? getCurrentAsMix(String name) {
    if (state.activeSounds.isEmpty) return null;

    return SleepSoundMix(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      sounds: state.activeSounds.entries
          .map((e) => SoundMixEntry(soundId: e.key, volume: e.value))
          .toList(),
      createdAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _timerCountdown?.cancel();
    super.dispose();
  }
}

/// Notifier for custom sound mixes
class CustomSoundMixesNotifier extends StateNotifier<List<SleepSoundMix>> {
  static const String _key = 'custom_sound_mixes';

  CustomSoundMixesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      try {
        final list = jsonDecode(data) as List;
        state = list.map((m) => SleepSoundMix.fromMap(m)).toList();
      } catch (_) {
        state = [];
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(state.map((m) => m.toMap()).toList()),
    );
  }

  Future<void> addMix(SleepSoundMix mix) async {
    state = [...state, mix];
    await _save();
  }

  Future<void> removeMix(String mixId) async {
    state = state.where((m) => m.id != mixId).toList();
    await _save();
  }

  Future<void> updateMix(SleepSoundMix mix) async {
    state = state.map((m) => m.id == mix.id ? mix : m).toList();
    await _save();
  }
}

/// Notifier for recent sounds
class RecentSoundsNotifier extends StateNotifier<List<String>> {
  static const String _key = 'recent_sounds';
  static const int _maxRecent = 10;

  RecentSoundsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);
    if (data != null) {
      state = data;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  Future<void> addRecent(String soundId) async {
    final newList = [
      soundId,
      ...state.where((id) => id != soundId),
    ].take(_maxRecent).toList();
    state = newList;
    await _save();
  }
}

/// Notifier for favorite sounds
class FavoriteSoundsNotifier extends StateNotifier<Set<String>> {
  static const String _key = 'favorite_sounds';

  FavoriteSoundsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key);
    if (data != null) {
      state = data.toSet();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }

  Future<void> toggleFavorite(String soundId) async {
    final newSet = Set<String>.from(state);
    if (newSet.contains(soundId)) {
      newSet.remove(soundId);
    } else {
      newSet.add(soundId);
    }
    state = newSet;
    await _save();
  }

  bool isFavorite(String soundId) => state.contains(soundId);
}

/// Convenience providers

/// All available sounds organized by category
final soundsByCategoryProvider = Provider<Map<SleepSoundCategory, List<SleepSound>>>((ref) {
  final map = <SleepSoundCategory, List<SleepSound>>{};
  for (final category in SleepSoundCategory.values) {
    map[category] = SleepSoundLibrary.getSoundsByCategory(category);
  }
  return map;
});

/// All mixes (default + custom)
final allSoundMixesProvider = Provider<List<SleepSoundMix>>((ref) {
  final customMixes = ref.watch(customSoundMixesProvider);
  return [...SleepSoundLibrary.defaultMixes, ...customMixes];
});

/// Recent sounds as SleepSound objects
final recentSoundsWithDetailsProvider = Provider<List<SleepSound>>((ref) {
  final recentIds = ref.watch(recentSoundsProvider);
  return recentIds
      .map((id) => SleepSoundLibrary.getSoundById(id))
      .whereType<SleepSound>()
      .toList();
});

/// Favorite sounds as SleepSound objects
final favoriteSoundsWithDetailsProvider = Provider<List<SleepSound>>((ref) {
  final favoriteIds = ref.watch(favoriteSoundsProvider);
  return favoriteIds
      .map((id) => SleepSoundLibrary.getSoundById(id))
      .whereType<SleepSound>()
      .toList();
});

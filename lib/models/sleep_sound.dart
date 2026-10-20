import 'package:flutter/material.dart';

/// Category of sleep sounds
enum SleepSoundCategory {
  nature('Nature', Icons.park),
  rain('Rain', Icons.water_drop),
  ambient('Ambient', Icons.air),
  white_noise('White Noise', Icons.graphic_eq),
  music('Music', Icons.music_note),
  meditation('Meditation', Icons.self_improvement);

  final String displayName;
  final IconData icon;
  const SleepSoundCategory(this.displayName, this.icon);
}

/// A sleep sound that can be played
class SleepSound {
  final String id;
  final String name;
  final String description;
  final SleepSoundCategory category;
  final String iconEmoji;
  final Color color;
  final bool isPremium;
  // In a real app, this would be a URL to the audio file
  // For now, we'll use placeholder identifiers
  final String audioAsset;

  const SleepSound({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.iconEmoji,
    required this.color,
    this.isPremium = false,
    required this.audioAsset,
  });
}

/// A mix of multiple sounds with individual volumes
class SleepSoundMix {
  final String id;
  final String name;
  final List<SoundMixEntry> sounds;
  final DateTime? createdAt;

  const SleepSoundMix({
    required this.id,
    required this.name,
    required this.sounds,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sounds': sounds.map((s) => s.toMap()).toList(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory SleepSoundMix.fromMap(Map<String, dynamic> map) {
    return SleepSoundMix(
      id: map['id'],
      name: map['name'],
      sounds: (map['sounds'] as List)
          .map((s) => SoundMixEntry.fromMap(s))
          .toList(),
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}

/// An entry in a sound mix
class SoundMixEntry {
  final String soundId;
  final double volume; // 0.0 - 1.0

  const SoundMixEntry({
    required this.soundId,
    this.volume = 0.5,
  });

  SoundMixEntry copyWith({double? volume}) {
    return SoundMixEntry(
      soundId: soundId,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'soundId': soundId,
      'volume': volume,
    };
  }

  factory SoundMixEntry.fromMap(Map<String, dynamic> map) {
    return SoundMixEntry(
      soundId: map['soundId'],
      volume: (map['volume'] as num?)?.toDouble() ?? 0.5,
    );
  }
}

/// Sleep timer configuration
class SleepTimer {
  final Duration duration;
  final bool fadeOut;
  final Duration fadeOutDuration;

  const SleepTimer({
    required this.duration,
    this.fadeOut = true,
    this.fadeOutDuration = const Duration(minutes: 5),
  });

  /// Preset durations
  static const presets = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
    Duration(minutes: 90),
    Duration(hours: 2),
  ];
}

/// Library of available sleep sounds
class SleepSoundLibrary {
  static const List<SleepSound> sounds = [
    // Nature sounds
    SleepSound(
      id: 'forest',
      name: 'Forest',
      description: 'Peaceful forest ambiance with birds',
      category: SleepSoundCategory.nature,
      iconEmoji: '🌲',
      color: Color(0xFF2E7D32),
      audioAsset: 'assets/sounds/forest.mp3',
    ),
    SleepSound(
      id: 'ocean_waves',
      name: 'Ocean Waves',
      description: 'Gentle waves on a sandy beach',
      category: SleepSoundCategory.nature,
      iconEmoji: '🌊',
      color: Color(0xFF1565C0),
      audioAsset: 'assets/sounds/ocean.mp3',
    ),
    SleepSound(
      id: 'river',
      name: 'River Stream',
      description: 'Flowing water in a peaceful stream',
      category: SleepSoundCategory.nature,
      iconEmoji: '🏞️',
      color: Color(0xFF00838F),
      audioAsset: 'assets/sounds/river.mp3',
    ),
    SleepSound(
      id: 'birds',
      name: 'Birds Chirping',
      description: 'Morning birds in the garden',
      category: SleepSoundCategory.nature,
      iconEmoji: '🐦',
      color: Color(0xFF558B2F),
      audioAsset: 'assets/sounds/birds.mp3',
    ),
    SleepSound(
      id: 'crickets',
      name: 'Night Crickets',
      description: 'Summer night cricket sounds',
      category: SleepSoundCategory.nature,
      iconEmoji: '🦗',
      color: Color(0xFF33691E),
      audioAsset: 'assets/sounds/crickets.mp3',
    ),
    SleepSound(
      id: 'wind',
      name: 'Wind',
      description: 'Gentle breeze through trees',
      category: SleepSoundCategory.nature,
      iconEmoji: '💨',
      color: Color(0xFF78909C),
      audioAsset: 'assets/sounds/wind.mp3',
    ),
    SleepSound(
      id: 'campfire',
      name: 'Campfire',
      description: 'Crackling fire sounds',
      category: SleepSoundCategory.nature,
      iconEmoji: '🔥',
      color: Color(0xFFE65100),
      audioAsset: 'assets/sounds/campfire.mp3',
    ),
    SleepSound(
      id: 'waterfall',
      name: 'Waterfall',
      description: 'Majestic waterfall in the distance',
      category: SleepSoundCategory.nature,
      iconEmoji: '⛰️',
      color: Color(0xFF0277BD),
      audioAsset: 'assets/sounds/waterfall.mp3',
    ),

    // Rain sounds
    SleepSound(
      id: 'light_rain',
      name: 'Light Rain',
      description: 'Gentle rain drops',
      category: SleepSoundCategory.rain,
      iconEmoji: '🌧️',
      color: Color(0xFF5C6BC0),
      audioAsset: 'assets/sounds/light_rain.mp3',
    ),
    SleepSound(
      id: 'heavy_rain',
      name: 'Heavy Rain',
      description: 'Intense rainstorm',
      category: SleepSoundCategory.rain,
      iconEmoji: '⛈️',
      color: Color(0xFF303F9F),
      audioAsset: 'assets/sounds/heavy_rain.mp3',
    ),
    SleepSound(
      id: 'rain_on_window',
      name: 'Rain on Window',
      description: 'Rain drops on a window pane',
      category: SleepSoundCategory.rain,
      iconEmoji: '🪟',
      color: Color(0xFF7986CB),
      audioAsset: 'assets/sounds/rain_window.mp3',
    ),
    SleepSound(
      id: 'rain_on_roof',
      name: 'Rain on Roof',
      description: 'Rain pattering on a tin roof',
      category: SleepSoundCategory.rain,
      iconEmoji: '🏠',
      color: Color(0xFF3949AB),
      audioAsset: 'assets/sounds/rain_roof.mp3',
    ),
    SleepSound(
      id: 'thunder',
      name: 'Thunder',
      description: 'Distant thunder rumbles',
      category: SleepSoundCategory.rain,
      iconEmoji: '⚡',
      color: Color(0xFF512DA8),
      audioAsset: 'assets/sounds/thunder.mp3',
    ),
    SleepSound(
      id: 'rain_and_thunder',
      name: 'Rain & Thunder',
      description: 'Rain with occasional thunder',
      category: SleepSoundCategory.rain,
      iconEmoji: '🌩️',
      color: Color(0xFF4527A0),
      audioAsset: 'assets/sounds/rain_thunder.mp3',
    ),

    // Ambient sounds
    SleepSound(
      id: 'fan',
      name: 'Fan',
      description: 'Electric fan running',
      category: SleepSoundCategory.ambient,
      iconEmoji: '🌀',
      color: Color(0xFF607D8B),
      audioAsset: 'assets/sounds/fan.mp3',
    ),
    SleepSound(
      id: 'air_conditioner',
      name: 'Air Conditioner',
      description: 'AC unit humming',
      category: SleepSoundCategory.ambient,
      iconEmoji: '❄️',
      color: Color(0xFF00ACC1),
      audioAsset: 'assets/sounds/ac.mp3',
    ),
    SleepSound(
      id: 'cafe',
      name: 'Cafe Ambiance',
      description: 'Quiet coffee shop chatter',
      category: SleepSoundCategory.ambient,
      iconEmoji: '☕',
      color: Color(0xFF795548),
      audioAsset: 'assets/sounds/cafe.mp3',
    ),
    SleepSound(
      id: 'train',
      name: 'Train Journey',
      description: 'Train on tracks rhythm',
      category: SleepSoundCategory.ambient,
      iconEmoji: '🚂',
      color: Color(0xFF5D4037),
      audioAsset: 'assets/sounds/train.mp3',
    ),
    SleepSound(
      id: 'airplane',
      name: 'Airplane Cabin',
      description: 'Airplane engine white noise',
      category: SleepSoundCategory.ambient,
      iconEmoji: '✈️',
      color: Color(0xFF546E7A),
      audioAsset: 'assets/sounds/airplane.mp3',
    ),
    SleepSound(
      id: 'car_ride',
      name: 'Car Ride',
      description: 'Highway driving sounds',
      category: SleepSoundCategory.ambient,
      iconEmoji: '🚗',
      color: Color(0xFF455A64),
      audioAsset: 'assets/sounds/car.mp3',
    ),

    // White noise
    SleepSound(
      id: 'white_noise',
      name: 'White Noise',
      description: 'Pure white noise',
      category: SleepSoundCategory.white_noise,
      iconEmoji: '📻',
      color: Color(0xFF9E9E9E),
      audioAsset: 'assets/sounds/white_noise.mp3',
    ),
    SleepSound(
      id: 'pink_noise',
      name: 'Pink Noise',
      description: 'Softer pink noise',
      category: SleepSoundCategory.white_noise,
      iconEmoji: '🎀',
      color: Color(0xFFE91E63),
      audioAsset: 'assets/sounds/pink_noise.mp3',
    ),
    SleepSound(
      id: 'brown_noise',
      name: 'Brown Noise',
      description: 'Deep brown noise',
      category: SleepSoundCategory.white_noise,
      iconEmoji: '🟤',
      color: Color(0xFF6D4C41),
      audioAsset: 'assets/sounds/brown_noise.mp3',
    ),
    SleepSound(
      id: 'tv_static',
      name: 'TV Static',
      description: 'Television static',
      category: SleepSoundCategory.white_noise,
      iconEmoji: '📺',
      color: Color(0xFF616161),
      audioAsset: 'assets/sounds/tv_static.mp3',
    ),

    // Music/Meditation
    SleepSound(
      id: 'piano',
      name: 'Soft Piano',
      description: 'Gentle piano melodies',
      category: SleepSoundCategory.music,
      iconEmoji: '🎹',
      color: Color(0xFF7E57C2),
      audioAsset: 'assets/sounds/piano.mp3',
    ),
    SleepSound(
      id: 'guitar',
      name: 'Acoustic Guitar',
      description: 'Peaceful guitar strings',
      category: SleepSoundCategory.music,
      iconEmoji: '🎸',
      color: Color(0xFFAB47BC),
      audioAsset: 'assets/sounds/guitar.mp3',
    ),
    SleepSound(
      id: 'lullaby',
      name: 'Lullaby',
      description: 'Classic sleep lullabies',
      category: SleepSoundCategory.music,
      iconEmoji: '🌙',
      color: Color(0xFF9C27B0),
      audioAsset: 'assets/sounds/lullaby.mp3',
    ),
    SleepSound(
      id: 'singing_bowl',
      name: 'Singing Bowl',
      description: 'Tibetan singing bowls',
      category: SleepSoundCategory.meditation,
      iconEmoji: '🔔',
      color: Color(0xFFFFB300),
      audioAsset: 'assets/sounds/singing_bowl.mp3',
    ),
    SleepSound(
      id: 'binaural_beats',
      name: 'Binaural Beats',
      description: 'Delta waves for deep sleep',
      category: SleepSoundCategory.meditation,
      iconEmoji: '🧘',
      color: Color(0xFF00897B),
      audioAsset: 'assets/sounds/binaural.mp3',
    ),
    SleepSound(
      id: 'breathing',
      name: 'Breathing Guide',
      description: '4-7-8 breathing exercise',
      category: SleepSoundCategory.meditation,
      iconEmoji: '🌬️',
      color: Color(0xFF26A69A),
      audioAsset: 'assets/sounds/breathing.mp3',
    ),
    SleepSound(
      id: 'chimes',
      name: 'Wind Chimes',
      description: 'Gentle wind chimes',
      category: SleepSoundCategory.meditation,
      iconEmoji: '🎐',
      color: Color(0xFF80DEEA),
      audioAsset: 'assets/sounds/chimes.mp3',
    ),
  ];

  /// Get sounds by category
  static List<SleepSound> getSoundsByCategory(SleepSoundCategory category) {
    return sounds.where((s) => s.category == category).toList();
  }

  /// Get sound by id
  static SleepSound? getSoundById(String id) {
    try {
      return sounds.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Default mixes
  static final List<SleepSoundMix> defaultMixes = [
    SleepSoundMix(
      id: 'rainy_night',
      name: 'Rainy Night',
      sounds: [
        SoundMixEntry(soundId: 'rain_on_window', volume: 0.7),
        SoundMixEntry(soundId: 'thunder', volume: 0.3),
      ],
    ),
    SleepSoundMix(
      id: 'cozy_cabin',
      name: 'Cozy Cabin',
      sounds: [
        SoundMixEntry(soundId: 'campfire', volume: 0.6),
        SoundMixEntry(soundId: 'rain_on_roof', volume: 0.5),
        SoundMixEntry(soundId: 'wind', volume: 0.3),
      ],
    ),
    SleepSoundMix(
      id: 'beach_day',
      name: 'Beach Day',
      sounds: [
        SoundMixEntry(soundId: 'ocean_waves', volume: 0.7),
        SoundMixEntry(soundId: 'birds', volume: 0.3),
      ],
    ),
    SleepSoundMix(
      id: 'forest_night',
      name: 'Forest Night',
      sounds: [
        SoundMixEntry(soundId: 'forest', volume: 0.5),
        SoundMixEntry(soundId: 'crickets', volume: 0.6),
        SoundMixEntry(soundId: 'river', volume: 0.4),
      ],
    ),
    SleepSoundMix(
      id: 'deep_focus',
      name: 'Deep Focus',
      sounds: [
        SoundMixEntry(soundId: 'brown_noise', volume: 0.5),
        SoundMixEntry(soundId: 'binaural_beats', volume: 0.3),
      ],
    ),
    SleepSoundMix(
      id: 'meditation_space',
      name: 'Meditation Space',
      sounds: [
        SoundMixEntry(soundId: 'singing_bowl', volume: 0.5),
        SoundMixEntry(soundId: 'river', volume: 0.4),
        SoundMixEntry(soundId: 'chimes', volume: 0.3),
      ],
    ),
  ];
}

/// Sleep sound playback state
class SleepSoundPlaybackState {
  final bool isPlaying;
  final Map<String, double> activeSounds; // soundId -> volume
  final Duration? timerDuration;
  final Duration? timerRemaining;
  final double masterVolume;

  const SleepSoundPlaybackState({
    this.isPlaying = false,
    this.activeSounds = const {},
    this.timerDuration,
    this.timerRemaining,
    this.masterVolume = 1.0,
  });

  SleepSoundPlaybackState copyWith({
    bool? isPlaying,
    Map<String, double>? activeSounds,
    Duration? timerDuration,
    Duration? timerRemaining,
    double? masterVolume,
  }) {
    return SleepSoundPlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      activeSounds: activeSounds ?? this.activeSounds,
      timerDuration: timerDuration ?? this.timerDuration,
      timerRemaining: timerRemaining ?? this.timerRemaining,
      masterVolume: masterVolume ?? this.masterVolume,
    );
  }

  /// Check if a specific sound is active
  bool isSoundActive(String soundId) => activeSounds.containsKey(soundId);

  /// Get volume for a specific sound
  double getSoundVolume(String soundId) => activeSounds[soundId] ?? 0.0;
}

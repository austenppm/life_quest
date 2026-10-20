import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sleep_sound.dart';
import '../../providers/sleep_sound_provider.dart';

class SleepSoundsScreen extends ConsumerStatefulWidget {
  const SleepSoundsScreen({super.key});

  @override
  ConsumerState<SleepSoundsScreen> createState() => _SleepSoundsScreenState();
}

class _SleepSoundsScreenState extends ConsumerState<SleepSoundsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: SleepSoundCategory.values.length + 2, // +2 for Mixes and Favorites
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(sleepSoundPlaybackProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Sounds'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Mixes'),
            const Tab(text: 'Favorites'),
            ...SleepSoundCategory.values.map((c) => Tab(text: c.displayName)),
          ],
        ),
        actions: [
          if (playbackState.activeSounds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save as Mix',
              onPressed: () => _showSaveMixDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMixesTab(),
                _buildFavoritesTab(),
                ...SleepSoundCategory.values.map((c) => _buildCategoryTab(c)),
              ],
            ),
          ),
          if (playbackState.activeSounds.isNotEmpty) _buildNowPlayingBar(),
        ],
      ),
    );
  }

  Widget _buildMixesTab() {
    final allMixes = ref.watch(allSoundMixesProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allMixes.length,
      itemBuilder: (context, index) {
        final mix = allMixes[index];
        return _MixCard(
          mix: mix,
          onTap: () {
            ref.read(sleepSoundPlaybackProvider.notifier).loadMix(mix);
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    final favorites = ref.watch(favoriteSoundsWithDetailsProvider);

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any sound to add it here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return _buildSoundGrid(favorites);
  }

  Widget _buildCategoryTab(SleepSoundCategory category) {
    final sounds = SleepSoundLibrary.getSoundsByCategory(category);
    return _buildSoundGrid(sounds);
  }

  Widget _buildSoundGrid(List<SleepSound> sounds) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: sounds.length,
      itemBuilder: (context, index) {
        return _SoundTile(sound: sounds[index]);
      },
    );
  }

  Widget _buildNowPlayingBar() {
    final playbackState = ref.watch(sleepSoundPlaybackProvider);
    final activeSoundNames = playbackState.activeSounds.keys
        .map((id) => SleepSoundLibrary.getSoundById(id)?.name ?? id)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timer display
            if (playbackState.timerRemaining != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(playbackState.timerRemaining!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        ref.read(sleepSoundPlaybackProvider.notifier).cancelTimer();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            // Main controls
            InkWell(
              onTap: () => _showMixerSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        playbackState.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                      ),
                      iconSize: 48,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        if (playbackState.isPlaying) {
                          ref.read(sleepSoundPlaybackProvider.notifier).pause();
                        } else {
                          ref.read(sleepSoundPlaybackProvider.notifier).play();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    // Now playing info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${activeSoundNames.length} sound${activeSoundNames.length != 1 ? 's' : ''} playing',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            activeSoundNames.join(', '),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Timer button
                    IconButton(
                      icon: const Icon(Icons.timer_outlined),
                      onPressed: () => _showTimerPicker(context),
                    ),
                    // Stop button
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: () {
                        ref.read(sleepSoundPlaybackProvider.notifier).stopAll();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMixerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _MixerSheet(),
    );
  }

  void _showTimerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sleep Timer',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...SleepTimer.presets.map((duration) {
              return ListTile(
                leading: const Icon(Icons.timer),
                title: Text(_formatDuration(duration)),
                onTap: () {
                  ref
                      .read(sleepSoundPlaybackProvider.notifier)
                      .startTimer(duration);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSaveMixDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Mix'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Mix Name',
            hintText: 'My Relaxing Mix',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final mix = ref
                  .read(sleepSoundPlaybackProvider.notifier)
                  .getCurrentAsMix(name);

              if (mix != null) {
                ref.read(customSoundMixesProvider.notifier).addMix(mix);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mix "$name" saved')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

class _SoundTile extends ConsumerWidget {
  final SleepSound sound;

  const _SoundTile({required this.sound});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(sleepSoundPlaybackProvider);
    final isActive = playbackState.activeSounds.containsKey(sound.id);
    final isFavorite = ref.watch(favoriteSoundsProvider).contains(sound.id);

    return GestureDetector(
      onTap: () {
        ref.read(sleepSoundPlaybackProvider.notifier).toggleSound(sound.id);
        if (!isActive) {
          ref.read(recentSoundsProvider.notifier).addRecent(sound.id);
        }
      },
      onLongPress: () {
        ref.read(favoriteSoundsProvider.notifier).toggleFavorite(sound.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? sound.color.withOpacity(0.3)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? sound.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  sound.iconEmoji,
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    sound.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sound.color,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.graphic_eq,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Playing',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 24),
              ],
            ),
            // Favorite indicator
            if (isFavorite)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.favorite,
                  size: 16,
                  color: Colors.red.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MixCard extends StatelessWidget {
  final SleepSoundMix mix;
  final VoidCallback onTap;

  const _MixCard({
    required this.mix,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final soundNames = mix.sounds
        .map((e) => SleepSoundLibrary.getSoundById(e.soundId)?.name ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    final soundEmojis = mix.sounds
        .map((e) => SleepSoundLibrary.getSoundById(e.soundId)?.iconEmoji ?? '')
        .where((emoji) => emoji.isNotEmpty)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sound emojis
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Wrap(
                    children: soundEmojis.take(4).map((emoji) {
                      return Text(
                        emoji,
                        style: const TextStyle(fontSize: 16),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Mix info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mix.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      soundNames.join(', '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${mix.sounds.length} sound${mix.sounds.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              // Play button
              Icon(
                Icons.play_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MixerSheet extends ConsumerWidget {
  const _MixerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(sleepSoundPlaybackProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Sound Mixer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    // Master volume
                    const Icon(Icons.volume_up, size: 20),
                    SizedBox(
                      width: 100,
                      child: Slider(
                        value: playbackState.masterVolume,
                        onChanged: (value) {
                          ref
                              .read(sleepSoundPlaybackProvider.notifier)
                              .setMasterVolume(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Individual sound controls
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: playbackState.activeSounds.length,
                  itemBuilder: (context, index) {
                    final entry =
                        playbackState.activeSounds.entries.elementAt(index);
                    final sound = SleepSoundLibrary.getSoundById(entry.key);

                    if (sound == null) return const SizedBox.shrink();

                    return _SoundMixerItem(
                      sound: sound,
                      volume: entry.value,
                      onVolumeChanged: (value) {
                        ref
                            .read(sleepSoundPlaybackProvider.notifier)
                            .setSoundVolume(sound.id, value);
                      },
                      onRemove: () {
                        ref
                            .read(sleepSoundPlaybackProvider.notifier)
                            .toggleSound(sound.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SoundMixerItem extends StatelessWidget {
  final SleepSound sound;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onRemove;

  const _SoundMixerItem({
    required this.sound,
    required this.volume,
    required this.onVolumeChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Sound icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: sound.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                sound.iconEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sound name and slider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sound.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Row(
                  children: [
                    Icon(
                      Icons.volume_down,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: sound.color,
                          thumbColor: sound.color,
                          overlayColor: sound.color.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: volume,
                          onChanged: onVolumeChanged,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.volume_up,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Remove button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

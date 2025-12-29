import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/playlist_provider.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressBar(context),
          const SizedBox(height: 12),
          _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: audio.progress.clamp(0.0, 1.0),
                onChanged: (value) => audio.seek(value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    audio.positionText,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    audio.durationText,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Shuffle
        Consumer<AudioProvider>(
          builder: (context, audio, _) {
            return IconButton(
              onPressed: audio.toggleShuffle,
              icon: Icon(
                Icons.shuffle_rounded,
                color: audio.isShuffled ? AppColors.accent : AppColors.textMuted,
              ),
              tooltip: 'Shuffle',
            );
          },
        ),
        const SizedBox(width: 16),
        // Previous
        Consumer<PlaylistProvider>(
          builder: (context, playlist, _) {
            return IconButton(
              onPressed: () {
                playlist.previousSong();
                if (playlist.currentSong != null) {
                  context.read<AudioProvider>().loadAndPlay(playlist.currentSong!.filePath);
                  if (playlist.currentSong!.eqProfile != null) {
                    // Would apply EQ here
                  }
                }
              },
              icon: const Icon(Icons.skip_previous_rounded, size: 32),
              color: AppColors.textPrimary,
              tooltip: 'Previous',
            );
          },
        ),
        const SizedBox(width: 8),
        // Play/Pause
        Consumer<AudioProvider>(
          builder: (context, audio, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => audio.togglePlayPause(),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    audio.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(audio.isPlaying),
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                iconSize: 36,
                padding: const EdgeInsets.all(12),
                tooltip: audio.isPlaying ? 'Pause' : 'Play',
              ),
            ).animate(target: audio.isPlaying ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
          },
        ),
        const SizedBox(width: 8),
        // Next
        Consumer<PlaylistProvider>(
          builder: (context, playlist, _) {
            return IconButton(
              onPressed: () {
                playlist.nextSong();
                if (playlist.currentSong != null) {
                  context.read<AudioProvider>().loadAndPlay(playlist.currentSong!.filePath);
                  if (playlist.currentSong!.eqProfile != null) {
                    // Would apply EQ here
                  }
                }
              },
              icon: const Icon(Icons.skip_next_rounded, size: 32),
              color: AppColors.textPrimary,
              tooltip: 'Next',
            );
          },
        ),
        const SizedBox(width: 16),
        // Repeat
        Consumer<AudioProvider>(
          builder: (context, audio, _) {
            return IconButton(
              onPressed: audio.toggleRepeat,
              icon: Icon(
                Icons.repeat_rounded,
                color: audio.isRepeating ? AppColors.accent : AppColors.textMuted,
              ),
              tooltip: 'Repeat',
            );
          },
        ),
        const Spacer(),
        // Volume
        _buildVolumeControl(context),
      ],
    );
  }

  Widget _buildVolumeControl(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: audio.toggleMute,
              icon: Icon(
                audio.isMuted || audio.volume == 0
                    ? Icons.volume_off_rounded
                    : audio.volume < 0.5
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
                color: AppColors.textSecondary,
              ),
              tooltip: audio.isMuted ? 'Unmute' : 'Mute',
            ),
            SizedBox(
              width: 100,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                ),
                child: Slider(
                  value: audio.isMuted ? 0 : audio.volume,
                  onChanged: (value) => audio.setVolume(value),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

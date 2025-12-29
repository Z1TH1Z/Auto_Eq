import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_provider.dart';

class NowPlayingCard extends StatelessWidget {
  const NowPlayingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlaylistProvider, AudioProvider>(
      builder: (context, playlist, audio, _) {
        final song = playlist.currentSong;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surface,
                AppColors.surfaceLight.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: song == null
              ? _buildEmptyState(context)
              : _buildNowPlaying(context, song, audio),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note_rounded,
              size: 48,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No track selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a song from the playlist',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildNowPlaying(BuildContext context, song, AudioProvider audio) {
    final colorIndex = playlist(context).currentIndex % AppColors.eqGradient.length;
    final primaryColor = AppColors.eqGradient[colorIndex];
    final secondaryColor = AppColors.eqGradient[(colorIndex + 3) % AppColors.eqGradient.length];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Album art placeholder
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated rings when playing
                          if (audio.isPlaying) ...[
                            _buildPulsingRing(0, primaryColor),
                            _buildPulsingRing(200, secondaryColor),
                            _buildPulsingRing(400, primaryColor),
                          ],
                          // Music icon
                          Icon(
                            Icons.music_note_rounded,
                            size: 64,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ],
                      ),
                    ),
                  ).animate(target: audio.isPlaying ? 1 : 0)
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 300.ms),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Song info
          Text(
            song.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // EQ status badge
          if (song.isAnalyzed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_fix_high, color: AppColors.success, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Auto EQ Applied',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildPulsingRing(int delayMs, Color color) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.3, 1.3),
          duration: 2000.ms,
          delay: delayMs.ms,
        )
        .fadeOut(duration: 2000.ms, delay: delayMs.ms);
  }

  PlaylistProvider playlist(BuildContext context) =>
      context.read<PlaylistProvider>();
}

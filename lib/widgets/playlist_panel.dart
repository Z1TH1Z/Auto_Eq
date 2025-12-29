import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/eq_provider.dart';
import '../models/song.dart';

class PlaylistPanel extends StatelessWidget {
  const PlaylistPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildPlaylist(context)),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.queue_music_rounded, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(
            'Playlist',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Consumer<PlaylistProvider>(
            builder: (context, playlist, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${playlist.length} songs',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylist(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlist, _) {
        if (playlist.isEmpty) {
          return _buildEmptyState(context);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: playlist.songs.length,
          itemBuilder: (context, index) {
            return _SongTile(
              song: playlist.songs[index],
              index: index,
              isSelected: index == playlist.currentIndex,
            ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.1);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 64,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No songs yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drop files here or click Browse',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.read<PlaylistProvider>().pickFiles(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Browse'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<PlaylistProvider>(
            builder: (context, playlist, _) {
              return IconButton(
                onPressed: playlist.isEmpty ? null : () => _showAnalyzeDialog(context),
                icon: const Icon(Icons.auto_fix_high_rounded),
                tooltip: 'Analyze All',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  disabledBackgroundColor: AppColors.surfaceLight.withOpacity(0.5),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Consumer<PlaylistProvider>(
            builder: (context, playlist, _) {
              return IconButton(
                onPressed: playlist.isEmpty ? null : playlist.clearPlaylist,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Clear Playlist',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  disabledBackgroundColor: AppColors.surfaceLight.withOpacity(0.5),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAnalyzeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_fix_high_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            const Text('Analyze Playlist'),
          ],
        ),
        content: const Text(
          'This will analyze all songs and generate optimal EQ profiles for each track.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PlaylistProvider>().analyzeAll();
            },
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final int index;
  final bool isSelected;

  const _SongTile({
    required this.song,
    required this.index,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.accent.withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.eqGradient[index % AppColors.eqGradient.length],
                AppColors.eqGradient[(index + 3) % AppColors.eqGradient.length],
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: isSelected
                ? const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24)
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                song.artist,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (song.isAnalyzed) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.check, color: AppColors.success, size: 10),
              ),
            ],
          ],
        ),
        trailing: SizedBox(
          width: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                song.formattedDuration,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16),
                padding: EdgeInsets.zero,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Remove'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'remove') {
                    context.read<PlaylistProvider>().removeSong(index);
                  }
                },
              ),
            ],
          ),
        ),
        onTap: () {
          context.read<PlaylistProvider>().selectSong(index);
          // Apply song's EQ profile if analyzed
          if (song.eqProfile != null) {
            context.read<EQProvider>().setAllGains(song.eqProfile!);
          }
          // Play the audio file
          context.read<AudioProvider>().loadAndPlay(song.filePath);
        },
      ),
    );
  }
}

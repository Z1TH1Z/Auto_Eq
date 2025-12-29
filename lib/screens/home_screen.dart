import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:desktop_drop/desktop_drop.dart';

import '../theme/app_theme.dart';
import '../providers/playlist_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/playlist_panel.dart';
import '../widgets/eq_panel.dart';
import '../widgets/player_controls.dart';
import '../widgets/now_playing_card.dart';
import '../widgets/visualizer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DropTarget(
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        onDragDone: (details) {
          setState(() => _isDragging = false);
          final paths = details.files.map((f) => f.path).toList();
          context.read<PlaylistProvider>().addSongs(paths);
        },
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Row(
                    children: [
                      // Left: Playlist
                      const Expanded(
                        flex: 3,
                        child: PlaylistPanel(),
                      ),
                      // Center: Now Playing + Visualizer
                      Expanded(
                        flex: 4,
                        child: _buildCenterPanel(),
                      ),
                      // Right: EQ
                      const Expanded(
                        flex: 4,
                        child: EQPanel(),
                      ),
                    ],
                  ),
                ),
                const PlayerControls(),
              ],
            ),
            // Drop overlay
            if (_isDragging)
              _buildDropOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.equalizer_rounded, color: Colors.white, size: 28),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto EQ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Intelligent Audio Equalizer',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          // Backend connection status
          Consumer<AudioProvider>(
            builder: (context, audio, _) {
              return GestureDetector(
                onTap: () => audio.reconnectBackend(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: audio.backendConnected 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: audio.backendConnected 
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: audio.backendConnected ? AppColors.success : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        audio.backendConnected ? 'Backend Connected' : 'Backend Offline',
                        style: TextStyle(
                          color: audio.backendConnected ? AppColors.success : AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Analysis status
          Consumer<PlaylistProvider>(
            builder: (context, playlist, _) {
              if (playlist.isAnalyzing) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: playlist.analysisProgress,
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        playlist.analysisStatus,
                        style: const TextStyle(color: AppColors.accent, fontSize: 13),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideX(begin: 0.1);
              }
              if (playlist.analysisStatus.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        playlist.analysisStatus,
                        style: const TextStyle(color: AppColors.success, fontSize: 13),
                      ),
                    ],
                  ),
                ).animate().fadeIn();
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Expanded(
            flex: 2,
            child: NowPlayingCard(),
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const AudioVisualizer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropOverlay() {
    return Container(
      color: AppColors.background.withOpacity(0.9),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 64,
                color: AppColors.accent,
              ).animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 600.ms)
                .then()
                .scale(begin: const Offset(1.1, 1.1), end: const Offset(1, 1), duration: 600.ms),
              const SizedBox(height: 16),
              Text(
                'Drop audio files here',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'MP3, WAV, FLAC, OGG, M4A',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ).animate().scale(begin: const Offset(0.9, 0.9), duration: 200.ms),
      ),
    );
  }
}

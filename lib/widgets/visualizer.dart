import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/audio_provider.dart';
import '../providers/eq_provider.dart';

class AudioVisualizer extends StatefulWidget {
  const AudioVisualizer({super.key});

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = List.generate(32, (_) => 0.1);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateBars);
  }

  void _updateBars() {
    final audio = context.read<AudioProvider>();
    final eq = context.read<EQProvider>();
    
    if (audio.isPlaying) {
      setState(() {
        for (int i = 0; i < _barHeights.length; i++) {
          // Create smooth random movement influenced by EQ
          final eqIndex = (i * eq.bands.length / _barHeights.length).floor();
          final eqInfluence = eq.isEnabled 
              ? (eq.bands[eqIndex].gain + 12) / 24 
              : 0.5;
          
          final target = 0.2 + _random.nextDouble() * 0.6 * eqInfluence;
          _barHeights[i] = _barHeights[i] * 0.7 + target * 0.3;
        }
      });
    } else {
      setState(() {
        for (int i = 0; i < _barHeights.length; i++) {
          _barHeights[i] = _barHeights[i] * 0.95;
          if (_barHeights[i] < 0.05) _barHeights[i] = 0.05;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        if (audio.isPlaying && !_controller.isAnimating) {
          _controller.repeat();
        } else if (!audio.isPlaying && _controller.isAnimating) {
          // Let it continue to animate down
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Spectrum Analyzer',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: audio.isPlaying
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: audio.isPlaying
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            audio.isPlaying ? 'LIVE' : 'IDLE',
                            style: TextStyle(
                              color: audio.isPlaying
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Visualizer bars
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(_barHeights.length, (index) {
                      final colorIndex =
                          (index * AppColors.eqGradient.length / _barHeights.length)
                              .floor();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: _VisualizerBar(
                            height: _barHeights[index],
                            color: AppColors.eqGradient[colorIndex],
                            isPlaying: audio.isPlaying,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                // Frequency labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '20Hz',
                      style: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '1kHz',
                      style: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '20kHz',
                      style: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VisualizerBar extends StatelessWidget {
  final double height;
  final Color color;
  final bool isPlaying;

  const _VisualizerBar({
    required this.height,
    required this.color,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = constraints.maxHeight * height.clamp(0.05, 1.0);
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.3),
                color,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}

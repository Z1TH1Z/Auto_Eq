import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import '../providers/eq_provider.dart';
import '../models/eq_band.dart';

class EQPanel extends StatelessWidget {
  const EQPanel({super.key});

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
          _buildPresets(context),
          Expanded(child: _buildEQSliders(context)),
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
          const Icon(Icons.tune_rounded, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(
            '10-Band EQ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Consumer<EQProvider>(
            builder: (context, eq, _) {
              return Row(
                children: [
                  Text(
                    eq.isEnabled ? 'ON' : 'OFF',
                    style: TextStyle(
                      color: eq.isEnabled ? AppColors.success : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: eq.isEnabled,
                    onChanged: (_) => eq.toggleEnabled(),
                    activeColor: AppColors.accent,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresets(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Consumer<EQProvider>(
        builder: (context, eq, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: EQPreset.presets.length,
            itemBuilder: (context, index) {
              final preset = EQPreset.presets[index];
              final isSelected = eq.currentPreset?.name == preset.name;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _PresetChip(
                  preset: preset,
                  isSelected: isSelected,
                  onTap: () => eq.applyPreset(preset),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEQSliders(BuildContext context) {
    return Consumer<EQProvider>(
      builder: (context, eq, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: List.generate(eq.bands.length, (index) {
              return Expanded(
                child: _EQBandSlider(
                  band: eq.bands[index],
                  color: AppColors.eqGradient[index],
                  isEnabled: eq.isEnabled,
                  onChanged: (value) => eq.setBandGain(index, value),
                ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.2),
              );
            }),
          ),
        );
      },
    );
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
            child: OutlinedButton.icon(
              onPressed: () => context.read<EQProvider>().reset(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showSaveDialog(context),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('EQ profile saved!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final EQPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(preset.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                preset.name,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EQBandSlider extends StatelessWidget {
  final EQBand band;
  final Color color;
  final bool isEnabled;
  final ValueChanged<double> onChanged;

  const _EQBandSlider({
    required this.band,
    required this.color,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: Column(
        children: [
          // Gain value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${band.gain >= 0 ? '+' : ''}${band.gain.toStringAsFixed(1)}',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Slider
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: color,
                  inactiveTrackColor: color.withOpacity(0.2),
                  thumbColor: color,
                  overlayColor: color.withOpacity(0.2),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: band.gain,
                  min: -12,
                  max: 12,
                  onChanged: isEnabled ? onChanged : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Frequency label
          Text(
            band.frequencyLabel,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Hz',
            style: TextStyle(
              color: AppColors.textMuted.withOpacity(0.5),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

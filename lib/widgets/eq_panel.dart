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
          // A/B Compare Button
          Consumer<EQProvider>(
            builder: (context, eq, _) {
              return _ABCompareButton(
                isComparing: eq.isComparing,
                isEnabled: eq.isEnabled,
                onChanged: (comparing) => eq.setComparing(comparing),
              );
            },
          ),
          const SizedBox(width: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Consumer<EQProvider>(
        builder: (context, eq, _) {
          return Row(
            children: [
              // Default Presets Dropdown
              Expanded(
                child: _PresetDropdown(
                  label: 'Presets',
                  icon: Icons.library_music_rounded,
                  presets: EQPreset.presets,
                  currentPreset: eq.currentPreset,
                  onSelected: (preset) => eq.applyPreset(preset),
                ),
              ),
              const SizedBox(width: 12),
              // Custom Presets Dropdown
              Expanded(
                child: _PresetDropdown(
                  label: 'My Profiles',
                  icon: Icons.star_rounded,
                  presets: eq.customPresets,
                  currentPreset: eq.currentPreset,
                  onSelected: (preset) => eq.applyPreset(preset),
                  onDelete: (preset) => _showDeleteDialog(context, eq, preset),
                  emptyText: 'No saved profiles',
                ),
              ),
            ],
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
    final nameController = TextEditingController();
    String selectedIcon = '🎵';
    final icons = ['🎵', '🎸', '🎹', '🎺', '🎻', '🥁', '🎤', '🎧', '💿', '⭐', '❤️', '🔥'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.save_rounded, color: AppColors.accent),
              SizedBox(width: 12),
              Text('Save EQ Preset'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Preset Name',
                  hintText: 'My Custom EQ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('Choose Icon:', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: icons.map((icon) {
                  final isSelected = selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = icon),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }
                
                final eq = context.read<EQProvider>();
                final success = await eq.saveCurrentAsPreset(name, selectedIcon);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            success ? Icons.check_circle : Icons.error,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          Text(success 
                            ? 'Preset "$name" saved!' 
                            : 'A preset with this name already exists'),
                        ],
                      ),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, EQProvider eq, EQPreset preset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.error),
            SizedBox(width: 12),
            Text('Delete Preset'),
          ],
        ),
        content: Text('Delete "${preset.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              eq.deleteCustomPreset(preset);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('Preset "${preset.name}" deleted'),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PresetDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<EQPreset> presets;
  final EQPreset? currentPreset;
  final Function(EQPreset) onSelected;
  final Function(EQPreset)? onDelete;
  final String emptyText;

  const _PresetDropdown({
    required this.label,
    required this.icon,
    required this.presets,
    required this.currentPreset,
    required this.onSelected,
    this.onDelete,
    this.emptyText = 'No presets',
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentInList = presets.any((p) => p.name == currentPreset?.name);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: PopupMenuButton<EQPreset>(
        enabled: presets.isNotEmpty,
        offset: const Offset(0, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.surface,
        onSelected: onSelected,
        itemBuilder: (context) => presets.map((preset) {
          final isSelected = currentPreset?.name == preset.name;
          return PopupMenuItem<EQPreset>(
            value: preset,
            child: Row(
              children: [
                Text(preset.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    preset.name,
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_rounded, color: AppColors.accent, size: 18),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onDelete!(preset);
                    },
                    child: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isCurrentInList ? AppColors.accent : AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCurrentInList ? currentPreset!.name : label,
                  style: TextStyle(
                    color: isCurrentInList ? AppColors.accent : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isCurrentInList ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                presets.isEmpty ? Icons.block : Icons.arrow_drop_down_rounded,
                color: presets.isEmpty ? AppColors.textMuted : AppColors.textSecondary,
                size: 20,
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


class _ABCompareButton extends StatelessWidget {
  final bool isComparing;
  final bool isEnabled;
  final Function(bool) onChanged;

  const _ABCompareButton({
    required this.isComparing,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isComparing ? 'Playing: Original' : 'Playing: EQ Applied',
      child: GestureDetector(
        onTapDown: (_) => onChanged(true),
        onTapUp: (_) => onChanged(false),
        onTapCancel: () => onChanged(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isComparing 
              ? AppColors.warning.withOpacity(0.2) 
              : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isComparing ? AppColors.warning : AppColors.border,
              width: isComparing ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isComparing ? Icons.hearing_disabled : Icons.hearing,
                size: 16,
                color: isComparing ? AppColors.warning : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                isComparing ? 'A' : 'B',
                style: TextStyle(
                  color: isComparing ? AppColors.warning : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isComparing ? 'Original' : 'EQ',
                style: TextStyle(
                  color: isComparing ? AppColors.warning : AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

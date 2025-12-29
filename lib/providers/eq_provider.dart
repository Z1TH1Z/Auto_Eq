import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/eq_band.dart';
import '../services/audio_backend_service.dart';

class EQProvider extends ChangeNotifier {
  final AudioBackendService _backend = AudioBackendService();
  
  List<EQBand> _bands = EQBand.defaultBands;
  EQPreset? _currentPreset;
  bool _isEnabled = true;
  List<EQPreset> _customPresets = [];
  bool _isComparing = false; // A/B Compare mode

  List<EQBand> get bands => _bands;
  EQPreset? get currentPreset => _currentPreset;
  bool get isEnabled => _isEnabled;
  List<double> get gains => _bands.map((b) => b.gain).toList();
  List<EQPreset> get customPresets => _customPresets;
  List<EQPreset> get allPresets => [...EQPreset.presets, ..._customPresets];
  bool get isComparing => _isComparing; // True = Original, False = EQ'd

  EQProvider() {
    _loadCustomPresets();
  }

  void setBandGain(int index, double gain) {
    if (index >= 0 && index < _bands.length) {
      _bands[index] = _bands[index].copyWith(gain: gain.clamp(-12.0, 12.0));
      _currentPreset = null;
      _sendEQToBackend();
      notifyListeners();
    }
  }

  void setAllGains(List<double> gains, {bool clearPreset = true}) {
    if (gains.length == _bands.length) {
      _bands = List.generate(_bands.length, (i) {
        return _bands[i].copyWith(gain: gains[i].clamp(-12.0, 12.0));
      });
      if (clearPreset) {
        _currentPreset = null;
      }
      _sendEQToBackend();
      notifyListeners();
    }
  }

  void applyPreset(EQPreset preset) {
    _currentPreset = preset;
    setAllGains(preset.gains, clearPreset: false);
  }

  void reset() {
    _bands = EQBand.defaultBands;
    _currentPreset = EQPreset.presets.first;
    _sendEQToBackend();
    notifyListeners();
  }

  void toggleEnabled() {
    _isEnabled = !_isEnabled;
    _sendEQToBackend();
    notifyListeners();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    _sendEQToBackend();
    notifyListeners();
  }

  Future<void> _sendEQToBackend() async {
    if (_isEnabled && !_isComparing) {
      await _backend.setEQ(gains);
    } else {
      // Send flat EQ when disabled or comparing (original)
      await _backend.setEQ(List.filled(10, 0.0));
    }
  }

  // A/B Compare - toggle between original and EQ'd audio
  void toggleCompare() {
    _isComparing = !_isComparing;
    _sendEQToBackend();
    notifyListeners();
  }

  void setComparing(bool comparing) {
    if (_isComparing != comparing) {
      _isComparing = comparing;
      _sendEQToBackend();
      notifyListeners();
    }
  }

  // Custom preset management
  Future<void> _loadCustomPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getStringList('custom_eq_presets') ?? [];
      _customPresets = presetsJson.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return EQPreset(
          name: map['name'] as String,
          icon: map['icon'] as String? ?? '🎵',
          gains: (map['gains'] as List).map((e) => (e as num).toDouble()).toList(),
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading presets: $e');
    }
  }

  Future<void> _saveCustomPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = _customPresets.map((preset) {
        return jsonEncode({
          'name': preset.name,
          'icon': preset.icon,
          'gains': preset.gains,
        });
      }).toList();
      await prefs.setStringList('custom_eq_presets', presetsJson);
    } catch (e) {
      debugPrint('Error saving presets: $e');
    }
  }

  Future<bool> saveCurrentAsPreset(String name, String icon) async {
    // Check if name already exists
    if (allPresets.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      return false;
    }
    
    final newPreset = EQPreset(
      name: name,
      icon: icon,
      gains: List.from(gains),
    );
    
    _customPresets.add(newPreset);
    _currentPreset = newPreset;
    await _saveCustomPresets();
    notifyListeners();
    return true;
  }

  Future<void> deleteCustomPreset(EQPreset preset) async {
    _customPresets.removeWhere((p) => p.name == preset.name);
    if (_currentPreset?.name == preset.name) {
      _currentPreset = null;
    }
    await _saveCustomPresets();
    notifyListeners();
  }

  bool isCustomPreset(EQPreset preset) {
    return _customPresets.any((p) => p.name == preset.name);
  }
}

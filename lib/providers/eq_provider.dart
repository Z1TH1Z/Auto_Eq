import 'package:flutter/foundation.dart';
import '../models/eq_band.dart';
import '../services/audio_backend_service.dart';

class EQProvider extends ChangeNotifier {
  final AudioBackendService _backend = AudioBackendService();
  
  List<EQBand> _bands = EQBand.defaultBands;
  EQPreset? _currentPreset;
  bool _isEnabled = true;

  List<EQBand> get bands => _bands;
  EQPreset? get currentPreset => _currentPreset;
  bool get isEnabled => _isEnabled;
  List<double> get gains => _bands.map((b) => b.gain).toList();

  void setBandGain(int index, double gain) {
    if (index >= 0 && index < _bands.length) {
      _bands[index] = _bands[index].copyWith(gain: gain.clamp(-12.0, 12.0));
      _currentPreset = null;
      _sendEQToBackend();
      notifyListeners();
    }
  }

  void setAllGains(List<double> gains) {
    if (gains.length == _bands.length) {
      _bands = List.generate(_bands.length, (i) {
        return _bands[i].copyWith(gain: gains[i].clamp(-12.0, 12.0));
      });
      _sendEQToBackend();
      notifyListeners();
    }
  }

  void applyPreset(EQPreset preset) {
    _currentPreset = preset;
    setAllGains(preset.gains);
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
    if (_isEnabled) {
      await _backend.setEQ(gains);
    } else {
      // Send flat EQ when disabled
      await _backend.setEQ(List.filled(10, 0.0));
    }
  }
}

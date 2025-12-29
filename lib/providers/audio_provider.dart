import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/audio_backend_service.dart';

enum PlaybackState { stopped, playing, paused }

class AudioProvider extends ChangeNotifier {
  final AudioBackendService _backend = AudioBackendService();
  
  PlaybackState _state = PlaybackState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 0.8;
  bool _isMuted = false;
  bool _isShuffled = false;
  bool _isRepeating = false;
  String? _currentPath;
  bool _backendConnected = false;
  Timer? _statusTimer;

  AudioProvider() {
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    _backendConnected = await _backend.checkHealth();
    if (_backendConnected) {
      _startStatusPolling();
    }
    notifyListeners();
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (_state == PlaybackState.playing) {
        await _updateStatus();
      }
    });
  }

  Future<void> _updateStatus() async {
    final status = await _backend.getStatus();
    if (status['is_playing'] == true) {
      _state = PlaybackState.playing;
      _position = Duration(milliseconds: ((status['position'] ?? 0) * 1000).round());
      _duration = Duration(milliseconds: ((status['duration'] ?? 0) * 1000).round());
    } else if (status['is_paused'] == true) {
      _state = PlaybackState.paused;
    } else {
      if (_state == PlaybackState.playing) {
        _state = PlaybackState.stopped;
        _position = Duration.zero;
      }
    }
    notifyListeners();
  }

  PlaybackState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  bool get isShuffled => _isShuffled;
  bool get isRepeating => _isRepeating;
  bool get isPlaying => _state == PlaybackState.playing;
  String? get currentPath => _currentPath;
  bool get backendConnected => _backendConnected;

  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  String get positionText => _formatDuration(_position);
  String get durationText => _formatDuration(_duration);

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> loadAndPlay(String filePath) async {
    _currentPath = filePath;
    
    if (!_backendConnected) {
      _backendConnected = await _backend.checkHealth();
      if (!_backendConnected) {
        debugPrint('Backend not connected');
        notifyListeners();
        return;
      }
    }

    final loadResult = await _backend.loadAudio(filePath);
    if (loadResult['success'] == true) {
      _duration = Duration(milliseconds: ((loadResult['duration'] ?? 0) * 1000).round());
      _position = Duration.zero;
      
      await _backend.setVolume(_isMuted ? 0 : _volume);
      final playResult = await _backend.play();
      if (playResult['success'] == true) {
        _state = PlaybackState.playing;
      }
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (_currentPath != null) {
      final result = await _backend.play();
      if (result['success'] == true) {
        _state = PlaybackState.playing;
        notifyListeners();
      }
    }
  }

  Future<void> pause() async {
    final result = await _backend.pause();
    if (result['success'] == true) {
      _state = PlaybackState.paused;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    final result = await _backend.stop();
    if (result['success'] == true) {
      _state = PlaybackState.stopped;
      _position = Duration.zero;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    if (_state == PlaybackState.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(double progress) async {
    final positionSeconds = progress * _duration.inSeconds;
    final result = await _backend.seek(positionSeconds);
    if (result['success'] == true) {
      _position = Duration(seconds: positionSeconds.round());
      notifyListeners();
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_volume > 0) _isMuted = false;
    await _backend.setVolume(_isMuted ? 0 : _volume);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _backend.setVolume(_isMuted ? 0 : _volume);
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeating = !_isRepeating;
    notifyListeners();
  }

  Future<void> setEQ(List<double> gains) async {
    await _backend.setEQ(gains);
  }

  Future<Map<String, dynamic>> analyzeAudio(String filePath) async {
    return await _backend.analyzeAudio(filePath);
  }

  Future<void> reconnectBackend() async {
    _backendConnected = await _backend.checkHealth();
    if (_backendConnected) {
      _startStatusPolling();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}

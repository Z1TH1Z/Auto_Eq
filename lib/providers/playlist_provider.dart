import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';
import '../services/audio_backend_service.dart';

class PlaylistProvider extends ChangeNotifier {
  final AudioBackendService _backend = AudioBackendService();
  final List<Song> _songs = [];
  Song? _currentSong;
  int _currentIndex = -1;
  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisStatus = '';

  List<Song> get songs => List.unmodifiable(_songs);
  Song? get currentSong => _currentSong;
  int get currentIndex => _currentIndex;
  bool get isAnalyzing => _isAnalyzing;
  double get analysisProgress => _analysisProgress;
  String get analysisStatus => _analysisStatus;
  bool get isEmpty => _songs.isEmpty;
  int get length => _songs.length;

  static const List<String> supportedFormats = [
    'mp3', 'wav', 'flac', 'ogg', 'm4a', 'aac', 'wma'
  ];

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedFormats,
      allowMultiple: true,
      withData: true, // Important: get file bytes for web
    );

    if (result != null) {
      for (final file in result.files) {
        await _addFileFromPicker(file);
      }
    }
  }

  Future<void> _addFileFromPicker(PlatformFile file) async {
    final fileName = file.name;
    final title = p.basenameWithoutExtension(fileName);
    
    String filePath;
    
    // On web, we need to upload the file
    if (kIsWeb && file.bytes != null) {
      _analysisStatus = 'Uploading $fileName...';
      notifyListeners();
      
      final uploadResult = await _backend.uploadFile(fileName, file.bytes!);
      if (uploadResult['success'] == true) {
        filePath = uploadResult['file_path'];
      } else {
        debugPrint('Upload failed: ${uploadResult['error']}');
        _analysisStatus = 'Upload failed';
        notifyListeners();
        return;
      }
      
      _analysisStatus = '';
      notifyListeners();
    } else {
      // Desktop: use file path directly
      filePath = file.path ?? fileName;
    }
    
    final song = Song(
      id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
      filePath: filePath,
      title: title,
      duration: const Duration(minutes: 3, seconds: 30),
    );
    _songs.add(song);
    notifyListeners();
  }

  void addSong(String filePath) {
    final fileName = p.basenameWithoutExtension(filePath);
    final song = Song(
      id: DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
      filePath: filePath,
      title: fileName,
      duration: const Duration(minutes: 3, seconds: 30),
    );
    _songs.add(song);
    notifyListeners();
  }

  void addSongs(List<String> filePaths) {
    for (final path in filePaths) {
      final ext = p.extension(path).toLowerCase().replaceAll('.', '');
      if (supportedFormats.contains(ext)) {
        addSong(path);
      }
    }
  }

  void removeSong(int index) {
    if (index >= 0 && index < _songs.length) {
      _songs.removeAt(index);
      if (_currentIndex == index) {
        _currentSong = null;
        _currentIndex = -1;
      } else if (_currentIndex > index) {
        _currentIndex--;
      }
      notifyListeners();
    }
  }

  void clearPlaylist() {
    _songs.clear();
    _currentSong = null;
    _currentIndex = -1;
    notifyListeners();
  }

  void selectSong(int index) {
    if (index >= 0 && index < _songs.length) {
      _currentIndex = index;
      _currentSong = _songs[index];
      notifyListeners();
    }
  }

  void nextSong() {
    if (_songs.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _songs.length;
      _currentSong = _songs[_currentIndex];
      notifyListeners();
    }
  }

  void previousSong() {
    if (_songs.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _songs.length) % _songs.length;
      _currentSong = _songs[_currentIndex];
      notifyListeners();
    }
  }

  Future<void> analyzeAll() async {
    if (_songs.isEmpty) return;

    _isAnalyzing = true;
    _analysisProgress = 0.0;
    notifyListeners();

    for (int i = 0; i < _songs.length; i++) {
      _analysisStatus = 'Analyzing ${_songs[i].title}...';
      _analysisProgress = (i + 1) / _songs.length;
      notifyListeners();

      final result = await _backend.analyzeAudio(_songs[i].filePath);
      
      List<double> eqProfile;
      if (result['success'] == true && result['eq_gains'] != null) {
        eqProfile = List<double>.from(result['eq_gains']);
      } else {
        eqProfile = _generateMockEQProfile();
      }
      
      _songs[i] = _songs[i].copyWith(
        eqProfile: eqProfile,
        isAnalyzed: true,
      );
      notifyListeners();
    }

    _isAnalyzing = false;
    _analysisStatus = 'Analysis complete!';
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));
    _analysisStatus = '';
    notifyListeners();
  }

  List<double> _generateMockEQProfile() {
    final random = Random();
    return List.generate(10, (index) {
      double base = (random.nextDouble() - 0.5) * 8;
      return (base * 10).round() / 10;
    });
  }

  void updateSongEQ(String songId, List<double> eqProfile) {
    final index = _songs.indexWhere((s) => s.id == songId);
    if (index != -1) {
      _songs[index] = _songs[index].copyWith(eqProfile: eqProfile);
      notifyListeners();
    }
  }
}

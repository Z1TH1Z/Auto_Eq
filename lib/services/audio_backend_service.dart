import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AudioBackendService {
  static const String baseUrl = 'http://localhost:5000/api';
  static final AudioBackendService _instance = AudioBackendService._internal();
  
  // Cache of uploaded files: original path -> server path
  final Map<String, String> _uploadedFiles = {};
  
  factory AudioBackendService() => _instance;
  AudioBackendService._internal();

  Future<Map<String, dynamic>> _post(String endpoint, [Map<String, dynamic>? body]) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));
      
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Backend error ($endpoint): $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Backend error ($endpoint): $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> checkHealth() async {
    final result = await _get('health');
    return result['status'] == 'ok';
  }

  /// Upload file bytes to backend (for web)
  Future<Map<String, dynamic>> uploadFile(String filename, Uint8List bytes) async {
    try {
      final base64Data = base64Encode(bytes);
      final result = await _post('upload', {
        'filename': filename,
        'data': base64Data,
      });
      
      if (result['success'] == true) {
        _uploadedFiles[filename] = result['file_path'];
      }
      return result;
    } catch (e) {
      debugPrint('Upload error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get server path for a file (uploads if needed on web)
  String? getServerPath(String originalPath) {
    // Check if already uploaded
    for (var entry in _uploadedFiles.entries) {
      if (originalPath.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // On desktop, use original path
    if (!originalPath.startsWith('blob:')) {
      return originalPath;
    }
    
    return null;
  }

  Future<Map<String, dynamic>> loadAudio(String filePath) async {
    // Check if we have a server path
    final serverPath = getServerPath(filePath);
    if (serverPath == null) {
      return {'success': false, 'error': 'File not uploaded. Please upload first.'};
    }
    return await _post('load', {'file_path': serverPath});
  }

  Future<Map<String, dynamic>> play() async {
    return await _post('play');
  }

  Future<Map<String, dynamic>> pause() async {
    return await _post('pause');
  }

  Future<Map<String, dynamic>> stop() async {
    return await _post('stop');
  }

  Future<Map<String, dynamic>> seek(double positionSeconds) async {
    return await _post('seek', {'position': positionSeconds});
  }

  Future<Map<String, dynamic>> setVolume(double volume) async {
    return await _post('volume', {'volume': volume});
  }

  Future<Map<String, dynamic>> setEQ(List<double> gains) async {
    return await _post('eq', {'gains': gains});
  }

  Future<Map<String, dynamic>> getStatus() async {
    return await _get('status');
  }

  Future<Map<String, dynamic>> analyzeAudio(String filePath) async {
    final serverPath = getServerPath(filePath);
    if (serverPath == null) {
      return {'success': false, 'error': 'File not uploaded'};
    }
    return await _post('analyze', {'file_path': serverPath});
  }
}

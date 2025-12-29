class Song {
  final String id;
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? artworkPath;
  final DateTime addedAt;
  List<double>? eqProfile;
  bool isAnalyzed;

  Song({
    required this.id,
    required this.filePath,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.duration = Duration.zero,
    this.artworkPath,
    DateTime? addedAt,
    this.eqProfile,
    this.isAnalyzed = false,
  }) : addedAt = addedAt ?? DateTime.now();

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    String? id,
    String? filePath,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? artworkPath,
    DateTime? addedAt,
    List<double>? eqProfile,
    bool? isAnalyzed,
  }) {
    return Song(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkPath: artworkPath ?? this.artworkPath,
      addedAt: addedAt ?? this.addedAt,
      eqProfile: eqProfile ?? this.eqProfile,
      isAnalyzed: isAnalyzed ?? this.isAnalyzed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration.inMilliseconds,
      'artworkPath': artworkPath,
      'addedAt': addedAt.toIso8601String(),
      'eqProfile': eqProfile?.join(','),
      'isAnalyzed': isAnalyzed ? 1 : 0,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      filePath: map['filePath'],
      title: map['title'],
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'] ?? 'Unknown Album',
      duration: Duration(milliseconds: map['duration'] ?? 0),
      artworkPath: map['artworkPath'],
      addedAt: DateTime.parse(map['addedAt']),
      eqProfile: map['eqProfile'] != null
          ? (map['eqProfile'] as String).split(',').map((e) => double.parse(e)).toList()
          : null,
      isAnalyzed: map['isAnalyzed'] == 1,
    );
  }
}

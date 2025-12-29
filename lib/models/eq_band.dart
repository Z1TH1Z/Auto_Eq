class EQBand {
  final int index;
  final int frequency;
  final String name;
  final String shortName;
  double gain;

  EQBand({
    required this.index,
    required this.frequency,
    required this.name,
    required this.shortName,
    this.gain = 0.0,
  });

  String get frequencyLabel {
    if (frequency >= 1000) {
      return '${frequency ~/ 1000}k';
    }
    return '$frequency';
  }

  EQBand copyWith({double? gain}) {
    return EQBand(
      index: index,
      frequency: frequency,
      name: name,
      shortName: shortName,
      gain: gain ?? this.gain,
    );
  }

  static List<EQBand> get defaultBands => [
    EQBand(index: 0, frequency: 20, name: 'Sub Bass', shortName: 'Sub'),
    EQBand(index: 1, frequency: 60, name: 'Bass', shortName: 'Bass'),
    EQBand(index: 2, frequency: 125, name: 'Low Mid', shortName: 'Low'),
    EQBand(index: 3, frequency: 250, name: 'Low Mid+', shortName: 'L-Mid'),
    EQBand(index: 4, frequency: 500, name: 'Midrange', shortName: 'Mid'),
    EQBand(index: 5, frequency: 1000, name: 'Presence', shortName: 'Pres'),
    EQBand(index: 6, frequency: 2000, name: 'Upper Mid', shortName: 'U-Mid'),
    EQBand(index: 7, frequency: 4000, name: 'Brilliance', shortName: 'Brill'),
    EQBand(index: 8, frequency: 8000, name: 'Air', shortName: 'Air'),
    EQBand(index: 9, frequency: 16000, name: 'Sparkle', shortName: 'Spark'),
  ];
}

class EQPreset {
  final String name;
  final String icon;
  final List<double> gains;

  const EQPreset({
    required this.name,
    required this.icon,
    required this.gains,
  });

  static List<EQPreset> get presets => [
    const EQPreset(name: 'Flat', icon: '⚖️', gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
    const EQPreset(name: 'Bass Boost', icon: '🔊', gains: [6, 5, 4, 2, 0, 0, 0, 0, 0, 0]),
    const EQPreset(name: 'Treble Boost', icon: '✨', gains: [0, 0, 0, 0, 0, 2, 4, 5, 6, 6]),
    const EQPreset(name: 'V-Shape', icon: '📈', gains: [5, 4, 2, 0, -2, -2, 0, 2, 4, 5]),
    const EQPreset(name: 'Vocal', icon: '🎤', gains: [-2, -1, 0, 2, 4, 4, 3, 1, 0, -1]),
    const EQPreset(name: 'Rock', icon: '🎸', gains: [4, 3, 2, 1, -1, 0, 2, 3, 4, 4]),
    const EQPreset(name: 'Electronic', icon: '🎹', gains: [5, 4, 2, 0, -1, 1, 3, 4, 4, 3]),
    const EQPreset(name: 'Jazz', icon: '🎷', gains: [2, 1, 0, 1, 2, 2, 1, 2, 3, 3]),
    const EQPreset(name: 'Classical', icon: '🎻', gains: [3, 2, 1, 1, 0, 0, 0, 1, 2, 3]),
    const EQPreset(name: 'Hip Hop', icon: '🎧', gains: [5, 5, 3, 1, 0, 1, 2, 1, 2, 3]),
  ];
}

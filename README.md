# Auto EQ - Intelligent Audio Equalizer

A beautiful Flutter desktop application with real-time 10-band parametric EQ processing.

![Auto EQ](https://img.shields.io/badge/version-1.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)
![Python](https://img.shields.io/badge/Python-3.9+-3776AB)

## Features

- 🎵 **Drag & Drop Playlist** - Add audio files easily
- 🎚️ **10-Band Parametric EQ** - Real-time audio processing (20Hz - 16kHz)
- 🎨 **10 EQ Presets** - Flat, Bass Boost, V-Shape, Rock, Jazz, etc.
- 📊 **Real-time Visualizer** - Animated spectrum analyzer
- 🔄 **Auto EQ Analysis** - Generates optimal EQ profiles per track
- 🌙 **Modern Dark Theme** - Beautiful, eye-friendly interface

## Quick Start

### One-Click Launch
```
Double-click: run_app.bat
```

### Manual Start
```bash
# Terminal 1: Start Backend
cd backend
python audio_server.py

# Terminal 2: Start Flutter UI
flutter run -d edge
```

## Requirements

- **Python 3.9+** with pip
- **Flutter SDK 3.x**
- **Windows 10/11**

### Python Dependencies
```
flask, flask-cors, numpy, scipy, librosa, sounddevice
```

### Flutter Dependencies
```
provider, flutter_animate, desktop_drop, file_picker, http, google_fonts
```

## Project Structure

```
auto_eq_flutter/
├── run_app.bat              # One-click launcher
├── README.md                # This file
├── pubspec.yaml             # Flutter dependencies
│
├── backend/                 # Python Audio Server
│   ├── audio_server.py      # Flask server with EQ processing
│   └── requirements.txt     # Python dependencies
│
└── lib/                     # Flutter App
    ├── main.dart            # App entry point
    ├── theme/
    │   └── app_theme.dart   # Colors & theming
    ├── models/
    │   ├── song.dart        # Song data model
    │   └── eq_band.dart     # EQ band & preset models
    ├── providers/
    │   ├── audio_provider.dart    # Playback state
    │   ├── eq_provider.dart       # EQ state
    │   └── playlist_provider.dart # Playlist state
    ├── services/
    │   └── audio_backend_service.dart  # Backend API client
    ├── screens/
    │   └── home_screen.dart # Main screen
    └── widgets/
        ├── playlist_panel.dart    # Playlist UI
        ├── eq_panel.dart          # EQ controls
        ├── player_controls.dart   # Playback controls
        ├── now_playing_card.dart  # Current track display
        └── visualizer.dart        # Spectrum analyzer
```

## How It Works

1. **Flutter UI** - Beautiful interface for playlist, EQ controls, and visualization
2. **Python Backend** - Handles audio loading, real-time EQ processing, and playback
3. **Communication** - Flutter sends commands via HTTP to Python backend
4. **EQ Processing** - Biquad filters applied in real-time to audio stream

## EQ Frequency Bands

| Band | Frequency | Purpose |
|------|-----------|---------|
| 1 | 20 Hz | Sub-bass |
| 2 | 60 Hz | Bass |
| 3 | 125 Hz | Low-mid |
| 4 | 250 Hz | Low-mid+ |
| 5 | 500 Hz | Midrange |
| 6 | 1 kHz | Presence |
| 7 | 2 kHz | Upper-mid |
| 8 | 4 kHz | Brilliance |
| 9 | 8 kHz | Air |
| 10 | 16 kHz | Sparkle |

## Supported Audio Formats

MP3, WAV, FLAC, OGG, M4A, AAC, WMA

## Troubleshooting

### "Backend Offline" in UI
- Make sure Python backend is running
- Check if port 5000 is available
- Click the status indicator to reconnect

### No Audio Output
- Check Windows audio settings
- Verify headphones/speakers are connected
- Check volume in app and system

### EQ Not Working
- Ensure backend is connected (green indicator)
- Try moving sliders to extreme values
- Check backend console for "EQ updated" messages

## License

MIT License - Free for personal and commercial use

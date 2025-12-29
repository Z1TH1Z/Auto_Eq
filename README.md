# Auto EQ - Intelligent Audio Equalizer
  Especially for Audiophiles

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/Flutter-3.38-02569B?style=for-the-badge&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Python-3.9+-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows" alt="Windows">
</p>

<p align="center">
  <b>A modern, beautiful desktop audio player with real-time 10-band parametric equalizer</b>
</p>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Inspiration](#-inspiration)
- [Features](#-features)
- [How It Works](#-how-it-works)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Installation](#-installation)
- [Usage](#-usage)
- [EQ Frequency Bands](#-eq-frequency-bands)
- [Future Scope](#-future-scope)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

Auto EQ is a desktop audio player application that combines a beautiful, modern UI with powerful real-time audio processing capabilities. Unlike typical music players where EQ settings are just visual gimmicks, Auto EQ actually processes the audio signal in real-time using professional-grade biquad filters, giving you true control over your listening experience.

The application features an intelligent "Auto Analyze" function that examines the frequency spectrum of your audio files and automatically generates optimized EQ profiles to enhance the listening experience.

---

## 💡 Inspiration

The project was inspired by several observations:

1. **The Gap in Desktop Audio Players** - Most free audio players either lack EQ functionality entirely or implement it poorly with no real audio processing.

2. **Professional Audio Tools Are Complex** - DAWs and professional audio software have powerful EQ, but they're overkill for casual listening and have steep learning curves.

3. **Streaming Services Lock Features** - Spotify, Apple Music, and others often lock EQ features behind premium subscriptions or limit customization.

4. **The Beauty of Modern UI** - Inspired by apps like Spotify's sleek dark interface and hardware EQ units with their satisfying slider controls.

5. **AI-Assisted Audio Enhancement** - The idea that software could analyze music and suggest optimal EQ settings, similar to how auto-tune works but for frequency balance.

---

## ✨ Features

### Core Features
- 🎵 **Drag & Drop Playlist** - Simply drag audio files into the app to build your playlist
- 🎚️ **10-Band Parametric EQ** - Professional-grade equalizer covering 20Hz to 16kHz
- 🔊 **Real-Time Processing** - EQ changes are applied instantly to the audio stream
- 📊 **Auto-Analyze** - AI-powered frequency analysis generates optimal EQ profiles
- 🎨 **10 Built-in Presets** - Flat, Bass Boost, Treble Boost, V-Shape, Rock, Pop, Jazz, Classical, Electronic, Vocal

### User Experience
- 🌙 **Modern Dark Theme** - Easy on the eyes with gradient accents
- 📈 **Live Visualizer** - Animated spectrum analyzer responds to your music
- 🖱️ **Intuitive Controls** - Play, pause, seek, volume - everything where you expect it
- 💾 **Preset Management** - Save and load your custom EQ configurations

### Technical Features
- ⚡ **Low Latency** - Optimized audio callback for minimal delay
- 🔄 **Hybrid Architecture** - Flutter UI + Python audio engine
- 📁 **Wide Format Support** - MP3, WAV, FLAC, OGG, M4A, AAC, WMA
- 🖥️ **Native Windows App** - Compiled to standalone .exe

---

## ⚙️ How It Works

### Audio Processing Pipeline

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Audio File  │────▶│   Decode    │────▶│  EQ Filter  │────▶│   Output    │
│ (MP3/FLAC)  │     │  (librosa)  │     │  (Biquad)   │     │ (speakers)  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                              ▲
                                              │
                                    ┌─────────────────┐
                                    │  Flutter UI     │
                                    │  (EQ Controls)  │
                                    └─────────────────┘
```

### Biquad Filter Implementation

The EQ uses cascaded biquad filters (second-order IIR filters) for each frequency band. Each filter implements a peaking EQ with the transfer function:

```
        b0 + b1*z^-1 + b2*z^-2
H(z) = ────────────────────────
        a0 + a1*z^-1 + a2*z^-2
```

The coefficients are calculated based on:
- **Center Frequency** - The target frequency for each band
- **Gain (dB)** - How much to boost or cut
- **Q Factor** - The bandwidth/sharpness of the filter

### Auto-Analyze Algorithm

1. **Load Audio Sample** - First 30 seconds of the track
2. **Compute STFT** - Short-Time Fourier Transform to get frequency spectrum
3. **Average Magnitude** - Calculate mean energy across time
4. **Band Analysis** - Measure energy in each EQ frequency band
5. **Generate Profile** - High energy bands get cut, low energy bands get boosted
6. **Apply Smoothing** - Prevent extreme adjustments

### Communication Flow

```
┌──────────────────┐         HTTP/REST          ┌──────────────────┐
│                  │  ───────────────────────▶  │                  │
│   Flutter App    │      /api/play             │  Python Backend  │
│   (Frontend)     │      /api/eq               │  (Audio Engine)  │
│                  │  ◀───────────────────────  │                  │
└──────────────────┘         JSON               └──────────────────┘
```

---

## 🏗️ Architecture

### Frontend (Flutter/Dart)
The UI layer built with Flutter, providing:
- Cross-platform compatibility
- Smooth 60fps animations
- Reactive state management with Provider
- Modern Material Design 3 components

### Backend (Python/Flask)
The audio processing engine:
- Flask REST API for communication
- librosa for audio file loading and analysis
- scipy for filter coefficient calculation
- sounddevice for low-level audio output
- NumPy for efficient array operations

### Why This Hybrid Approach?

| Aspect | Flutter Only | Python Only | Hybrid (Our Choice) |
|--------|-------------|-------------|---------------------|
| UI Quality | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Audio Processing | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Development Speed | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Performance | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

Flutter excels at beautiful, responsive UIs but lacks mature audio processing libraries. Python has excellent audio/DSP libraries but UI frameworks (PyQt, Tkinter) feel dated. The hybrid approach gives us the best of both worlds.

---

## 🛠️ Tech Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| **Flutter 3.38** | UI framework |
| **Dart 3.10** | Programming language |
| **Provider** | State management |
| **flutter_animate** | Smooth animations |
| **desktop_drop** | Drag & drop support |
| **file_picker** | File selection dialogs |
| **google_fonts** | Typography (Poppins) |
| **http** | REST API client |

### Backend
| Technology | Purpose |
|------------|---------|
| **Python 3.9+** | Runtime |
| **Flask** | REST API server |
| **Flask-CORS** | Cross-origin requests |
| **librosa** | Audio loading & analysis |
| **NumPy** | Numerical operations |
| **SciPy** | Signal processing |
| **sounddevice** | Audio output |

### Build & Distribution
| Technology | Purpose |
|------------|---------|
| **Flutter Windows** | Native compilation |
| **Visual Studio Build Tools** | C++ compilation |
| **Batch Scripts** | Automation |

---

## 📁 Project Structure

```
auto_eq_flutter/
│
├── 📄 pubspec.yaml              # Flutter dependencies
├── 📄 AutoEQ.bat                # One-click launcher
├── 📄 build_desktop.bat         # Build script
│
├── 📂 backend/                  # Python Audio Engine
│   ├── 📄 audio_server.py       # Flask server + EQ processing
│   └── 📄 requirements.txt      # Python dependencies
│
├── 📂 lib/                      # Flutter Application
│   ├── 📄 main.dart             # App entry point
│   │
│   ├── 📂 theme/
│   │   └── 📄 app_theme.dart    # Colors, gradients, styling
│   │
│   ├── 📂 models/
│   │   ├── 📄 song.dart         # Song data model
│   │   └── 📄 eq_band.dart      # EQ band & preset models
│   │
│   ├── 📂 providers/
│   │   ├── 📄 audio_provider.dart    # Playback state
│   │   ├── 📄 eq_provider.dart       # EQ state & presets
│   │   └── 📄 playlist_provider.dart # Playlist management
│   │
│   ├── 📂 services/
│   │   └── 📄 audio_backend_service.dart  # Backend API client
│   │
│   ├── 📂 screens/
│   │   └── 📄 home_screen.dart  # Main application screen
│   │
│   └── 📂 widgets/
│       ├── 📄 playlist_panel.dart    # Playlist UI
│       ├── 📄 eq_panel.dart          # EQ sliders & presets
│       ├── 📄 player_controls.dart   # Play/pause/seek
│       ├── 📄 now_playing_card.dart  # Current track display
│       └── 📄 visualizer.dart        # Spectrum animation
│
└── 📂 dist/                     # Distribution Package
    └── 📂 AutoEQ/
        ├── 📄 auto_eq_flutter.exe
        ├── 📄 AutoEQ.bat
        └── 📂 backend/
```

---

## 🚀 Installation

### For Users (Pre-built)

1. Download `AutoEQ_v1.0.zip`
2. Extract to any folder
3. Install Python from [python.org](https://www.python.org/downloads/) (check "Add to PATH")
4. Double-click `AutoEQ.bat`

### For Developers

```bash
# Clone the repository
git clone <repository-url>
cd auto_eq_flutter

# Install Flutter dependencies
flutter pub get

# Install Python dependencies
cd backend
pip install -r requirements.txt
cd ..

# Run in development
# Terminal 1:
cd backend && python audio_server.py

# Terminal 2:
flutter run -d windows
```

### Building from Source

```bash
# Ensure Visual Studio Build Tools with C++ workload is installed
flutter doctor  # Verify setup

# Build release
flutter build windows --release

# Output: build/windows/x64/runner/Release/
```

---

## 📖 Usage

### Basic Playback
1. Launch the app via `AutoEQ.bat`
2. Drag audio files onto the playlist panel (left side)
3. Double-click a song to play
4. Use the bottom controls for play/pause/seek

### Using the Equalizer
1. Adjust sliders to boost (+) or cut (-) frequencies
2. Click preset buttons for quick configurations
3. Use "Reset" to return to flat response

### Auto-Analyze Feature
1. With a song loaded, click "Analyze" button
2. Wait for analysis to complete (~2-3 seconds)
3. EQ sliders automatically adjust to optimal settings
4. Fine-tune manually if desired

---

## 🎚️ EQ Frequency Bands

| Band | Frequency | Character | Typical Use |
|------|-----------|-----------|-------------|
| 1 | 20 Hz | Sub-bass | Felt more than heard, adds weight |
| 2 | 60 Hz | Bass | Kick drums, bass guitar fundamental |
| 3 | 125 Hz | Low-mid | Bass warmth, body of instruments |
| 4 | 250 Hz | Low-mid | Muddiness zone, often cut |
| 5 | 500 Hz | Midrange | Body of vocals and instruments |
| 6 | 1 kHz | Upper-mid | Presence, vocal clarity |
| 7 | 2 kHz | Upper-mid | Attack of instruments |
| 8 | 4 kHz | Presence | Clarity, definition |
| 9 | 8 kHz | Brilliance | Sibilance, cymbal shimmer |
| 10 | 16 kHz | Air | Sparkle, openness |

---

## 🔮 Future Scope

### Short-term Improvements
- [ ] **Preset Save/Load** - Save custom EQ presets to files
- [ ] **Keyboard Shortcuts** - Space for play/pause, arrows for seek
- [ ] **Mini Player Mode** - Compact view for desktop corner
- [ ] **System Tray** - Minimize to tray with controls

### Medium-term Features
- [ ] **Playlist Save/Load** - Export and import playlists
- [ ] **Audio Effects** - Reverb, compressor, stereo widener
- [ ] **Crossfade** - Smooth transitions between tracks
- [ ] **Gapless Playback** - Seamless album playback
- [ ] **Lyrics Display** - Fetch and show synchronized lyrics

### Long-term Vision
- [ ] **macOS & Linux Support** - Cross-platform builds
- [ ] **VST Plugin Support** - Load third-party audio plugins
- [ ] **AI DJ Mode** - Auto-generate playlists based on mood
- [ ] **Room Correction** - Microphone calibration for your space
- [ ] **Cloud Sync** - Sync settings across devices
- [ ] **Spotify/Tidal Integration** - Stream with EQ applied

### Technical Improvements
- [ ] **GPU Acceleration** - CUDA/OpenCL for faster processing
- [ ] **ASIO Support** - Professional audio interface support
- [ ] **Bit-perfect Output** - Audiophile-grade playback
- [ ] **Real-time Spectrum** - FFT visualization synced to audio

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Report Bugs** - Open an issue with reproduction steps
2. **Suggest Features** - Describe your idea in an issue
3. **Submit PRs** - Fork, branch, code, and submit
4. **Improve Docs** - Help make documentation clearer

### Development Guidelines
- Follow Flutter/Dart style guide
- Follow PEP 8 for Python code
- Write meaningful commit messages
- Test on Windows before submitting

---

## 📄 License

MIT License - Free for personal and commercial use.

---

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing UI framework
- **librosa** - For powerful audio analysis tools
- **sounddevice** - For reliable audio I/O
- **The Open Source Community** - For all the libraries that made this possible

---

<p align="center">
  <b>Made with ❤️ for music lovers</b>
</p>

<p align="center">
  <i>Turn up the bass. Feel the music. 🎵</i>
</p>

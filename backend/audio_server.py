"""
Auto EQ Backend Server
Handles audio playback with real-time EQ processing
"""

import os
import sys
import json
import threading
import numpy as np
from pathlib import Path
from flask import Flask, request, jsonify
from flask_cors import CORS
import sounddevice as sd
from scipy.signal import iirpeak, sosfilt
import librosa
import tempfile
import base64

app = Flask(__name__)
CORS(app)

# Temp directory for uploaded files
UPLOAD_DIR = Path(tempfile.gettempdir()) / "auto_eq_uploads"
UPLOAD_DIR.mkdir(exist_ok=True)


class BiquadFilter:
    """Biquad filter for real-time EQ processing"""
    def __init__(self, freq, gain_db, q, sample_rate):
        self.freq = freq
        self.gain_db = gain_db
        self.q = q
        self.sample_rate = sample_rate
        self.update_coefficients()
        # Filter state for each channel
        self.z1_l = 0.0
        self.z2_l = 0.0
        self.z1_r = 0.0
        self.z2_r = 0.0
    
    def update_coefficients(self):
        """Calculate biquad coefficients for peaking EQ"""
        A = 10 ** (self.gain_db / 40.0)
        w0 = 2 * np.pi * self.freq / self.sample_rate
        cos_w0 = np.cos(w0)
        sin_w0 = np.sin(w0)
        alpha = sin_w0 / (2 * self.q)
        
        # Peaking EQ coefficients
        self.b0 = 1 + alpha * A
        self.b1 = -2 * cos_w0
        self.b2 = 1 - alpha * A
        self.a0 = 1 + alpha / A
        self.a1 = -2 * cos_w0
        self.a2 = 1 - alpha / A
        
        # Normalize
        self.b0 /= self.a0
        self.b1 /= self.a0
        self.b2 /= self.a0
        self.a1 /= self.a0
        self.a2 /= self.a0
    
    def set_gain(self, gain_db):
        """Update gain and recalculate coefficients"""
        if abs(gain_db - self.gain_db) > 0.1:
            self.gain_db = gain_db
            self.update_coefficients()
    
    def process_sample(self, x, is_right=False):
        """Process a single sample using Direct Form II"""
        if is_right:
            w = x - self.a1 * self.z1_r - self.a2 * self.z2_r
            y = self.b0 * w + self.b1 * self.z1_r + self.b2 * self.z2_r
            self.z2_r = self.z1_r
            self.z1_r = w
        else:
            w = x - self.a1 * self.z1_l - self.a2 * self.z2_l
            y = self.b0 * w + self.b1 * self.z1_l + self.b2 * self.z2_l
            self.z2_l = self.z1_l
            self.z1_l = w
        return y
    
    def process_block(self, audio):
        """Process a block of stereo audio"""
        output = np.zeros_like(audio)
        for i in range(len(audio)):
            output[i, 0] = self.process_sample(audio[i, 0], is_right=False)
            output[i, 1] = self.process_sample(audio[i, 1], is_right=True)
        return output


class AudioEngine:
    def __init__(self):
        self.current_file = None
        self.audio_data = None
        self.sample_rate = 44100
        self.is_playing = False
        self.is_paused = False
        self.position = 0
        self.volume = 0.8
        self.eq_gains = [0.0] * 10
        self.eq_bands = [20, 60, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        self.stream = None
        self.lock = threading.Lock()
        self.duration = 0
        self.eq_enabled = True
        
        # Initialize EQ filters
        self.filters = []
        self._init_filters()
    
    def _init_filters(self):
        """Initialize biquad filters for each EQ band"""
        self.filters = []
        q_values = [0.7, 0.8, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.8, 0.7]  # Q for each band
        for i, freq in enumerate(self.eq_bands):
            q = q_values[i]
            filt = BiquadFilter(freq, self.eq_gains[i], q, self.sample_rate)
            self.filters.append(filt)
        print(f"Initialized {len(self.filters)} EQ filters")
    
    def load_file(self, file_path):
        """Load audio file"""
        try:
            self.stop()
            print(f"Loading: {file_path}")
            
            # Load with librosa
            y, sr = librosa.load(file_path, sr=self.sample_rate, mono=False)
            
            # Ensure stereo
            if y.ndim == 1:
                y = np.stack([y, y])
            
            self.audio_data = y.T.astype(np.float32)  # Shape: (samples, 2)
            self.sample_rate = sr
            self.current_file = file_path
            self.position = 0
            self.duration = len(self.audio_data) / self.sample_rate
            
            # Reinitialize filters with correct sample rate
            self._init_filters()
            
            print(f"Loaded: {self.duration:.2f}s, {self.sample_rate}Hz, shape={self.audio_data.shape}")
            
            return {
                "success": True,
                "duration": self.duration,
                "sample_rate": self.sample_rate,
                "channels": 2
            }
        except Exception as e:
            print(f"Load error: {e}")
            import traceback
            traceback.print_exc()
            return {"success": False, "error": str(e)}
    
    def _apply_eq(self, chunk):
        """Apply EQ filters to audio chunk"""
        if not self.eq_enabled:
            return chunk
        
        # Check if any EQ is active
        if not any(abs(g) > 0.5 for g in self.eq_gains):
            return chunk
        
        output = chunk.copy()
        for filt in self.filters:
            if abs(filt.gain_db) > 0.5:  # Only apply if gain is significant
                output = filt.process_block(output)
        
        return output
    
    def _audio_callback(self, outdata, frames, time, status):
        """Audio stream callback with EQ processing"""
        if status:
            print(f"Stream status: {status}")
        
        with self.lock:
            if not self.is_playing or self.is_paused or self.audio_data is None:
                outdata.fill(0)
                return
            
            end_pos = min(self.position + frames, len(self.audio_data))
            chunk_len = end_pos - self.position
            
            if chunk_len <= 0:
                outdata.fill(0)
                self.is_playing = False
                self.position = 0
                return
            
            # Get audio chunk
            chunk = self.audio_data[self.position:end_pos].copy()
            
            # Apply EQ
            chunk = self._apply_eq(chunk)
            
            # Apply volume
            chunk = chunk * self.volume
            
            # Soft clip to prevent harsh distortion
            chunk = np.tanh(chunk)
            
            # Fill output
            if chunk_len < frames:
                outdata[:chunk_len] = chunk
                outdata[chunk_len:] = 0
                self.is_playing = False
                self.position = 0
            else:
                outdata[:] = chunk
                self.position = end_pos
    
    def play(self):
        """Start playback"""
        if self.audio_data is None:
            return {"success": False, "error": "No audio loaded"}
        
        print(f"Play called. Paused={self.is_paused}, Playing={self.is_playing}")
        
        with self.lock:
            if self.is_paused:
                self.is_paused = False
                self.is_playing = True
                print("Resumed playback")
                return {"success": True, "action": "resumed"}
            
            # Stop existing stream
            if self.stream is not None:
                try:
                    self.stream.stop()
                    self.stream.close()
                except:
                    pass
                self.stream = None
            
            self.is_playing = True
            self.is_paused = False
            
            try:
                print(f"Creating stream: {self.sample_rate}Hz, 2ch")
                self.stream = sd.OutputStream(
                    samplerate=self.sample_rate,
                    channels=2,
                    dtype='float32',
                    callback=self._audio_callback,
                    blocksize=1024  # Smaller for lower latency
                )
                self.stream.start()
                print("Stream started!")
                return {"success": True, "action": "started"}
            except Exception as e:
                print(f"Stream error: {e}")
                self.is_playing = False
                return {"success": False, "error": str(e)}
    
    def pause(self):
        """Pause playback"""
        with self.lock:
            if self.is_playing:
                self.is_paused = True
                print("Paused")
            return {"success": True}
    
    def stop(self):
        """Stop playback"""
        with self.lock:
            self.is_playing = False
            self.is_paused = False
            self.position = 0
            if self.stream is not None:
                try:
                    self.stream.stop()
                    self.stream.close()
                except:
                    pass
                self.stream = None
            print("Stopped")
            return {"success": True}
    
    def seek(self, position_seconds):
        """Seek to position"""
        with self.lock:
            if self.audio_data is not None:
                self.position = int(position_seconds * self.sample_rate)
                self.position = max(0, min(self.position, len(self.audio_data) - 1))
            return {"success": True, "position": self.position / self.sample_rate}
    
    def set_volume(self, volume):
        """Set volume"""
        self.volume = max(0.0, min(1.0, volume))
        print(f"Volume set to: {self.volume}")
        return {"success": True, "volume": self.volume}
    
    def set_eq(self, gains):
        """Set EQ gains and update filters"""
        if len(gains) == 10:
            self.eq_gains = [float(g) for g in gains]
            # Update filter gains
            for i, filt in enumerate(self.filters):
                filt.set_gain(self.eq_gains[i])
            print(f"EQ updated: {self.eq_gains}")
            return {"success": True, "eq_gains": self.eq_gains}
        return {"success": False, "error": "Expected 10 EQ bands"}
    
    def set_eq_enabled(self, enabled):
        """Enable/disable EQ"""
        self.eq_enabled = enabled
        print(f"EQ enabled: {enabled}")
        return {"success": True, "eq_enabled": enabled}
    
    def get_status(self):
        """Get playback status"""
        pos = self.position / self.sample_rate if self.audio_data is not None else 0
        return {
            "is_playing": self.is_playing and not self.is_paused,
            "is_paused": self.is_paused,
            "position": pos,
            "duration": self.duration,
            "volume": self.volume,
            "eq_gains": self.eq_gains,
            "eq_enabled": self.eq_enabled,
            "current_file": self.current_file
        }
    
    def analyze_audio(self, file_path):
        """Analyze audio and generate EQ profile"""
        try:
            print(f"Analyzing: {file_path}")
            y, sr = librosa.load(file_path, sr=self.sample_rate, duration=30, mono=True)
            
            # Compute spectrum
            D = np.abs(librosa.stft(y, n_fft=2048, hop_length=512))
            freqs = librosa.fft_frequencies(sr=sr, n_fft=2048)
            avg_mag = np.mean(D, axis=1)
            
            # Normalize
            avg_mag_db = librosa.amplitude_to_db(avg_mag, ref=np.max)
            avg_mag_norm = (avg_mag_db - np.min(avg_mag_db)) / (np.max(avg_mag_db) - np.min(avg_mag_db) + 1e-8)
            
            # Generate EQ
            eq_gains = []
            for band_freq in self.eq_bands:
                bandwidth = band_freq * 0.3
                mask = (freqs >= band_freq - bandwidth) & (freqs <= band_freq + bandwidth)
                
                if np.any(mask):
                    energy = np.mean(avg_mag_norm[mask])
                else:
                    energy = 0.5
                
                # High energy = cut, low = boost
                gain = -8 * (energy - 0.4)
                gain = np.clip(gain, -12, 12)
                eq_gains.append(round(float(gain), 1))
            
            print(f"Generated EQ: {eq_gains}")
            return {"success": True, "eq_gains": eq_gains, "file_path": file_path}
        except Exception as e:
            print(f"Analysis error: {e}")
            return {"success": False, "error": str(e)}


# Global engine
engine = AudioEngine()

# Routes
@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})

@app.route('/api/upload', methods=['POST'])
def upload_audio():
    """Upload audio file from web browser"""
    try:
        if 'file' in request.files:
            file = request.files['file']
            filename = file.filename or 'audio.mp3'
            filepath = UPLOAD_DIR / filename
            file.save(filepath)
            print(f"Uploaded: {filepath}")
            return jsonify({"success": True, "file_path": str(filepath)})
        
        # Handle base64 encoded data
        data = request.json
        if data and 'data' in data:
            filename = data.get('filename', 'audio.mp3')
            filepath = UPLOAD_DIR / filename
            audio_data = base64.b64decode(data['data'])
            with open(filepath, 'wb') as f:
                f.write(audio_data)
            print(f"Uploaded (base64): {filepath}")
            return jsonify({"success": True, "file_path": str(filepath)})
        
        return jsonify({"success": False, "error": "No file provided"})
    except Exception as e:
        print(f"Upload error: {e}")
        return jsonify({"success": False, "error": str(e)})

@app.route('/api/load', methods=['POST'])
def load_audio():
    data = request.json
    file_path = data.get('file_path', '')
    if file_path.startswith('blob:'):
        return jsonify({"success": False, "error": "Please use /api/upload for web browser"})
    return jsonify(engine.load_file(file_path))

@app.route('/api/play', methods=['POST'])
def play():
    return jsonify(engine.play())

@app.route('/api/pause', methods=['POST'])
def pause():
    return jsonify(engine.pause())

@app.route('/api/stop', methods=['POST'])
def stop():
    return jsonify(engine.stop())

@app.route('/api/seek', methods=['POST'])
def seek():
    data = request.json
    return jsonify(engine.seek(data.get('position', 0)))

@app.route('/api/volume', methods=['POST'])
def set_volume():
    data = request.json
    return jsonify(engine.set_volume(data.get('volume', 0.8)))

@app.route('/api/eq', methods=['POST'])
def set_eq():
    data = request.json
    return jsonify(engine.set_eq(data.get('gains', [0] * 10)))

@app.route('/api/eq/enabled', methods=['POST'])
def set_eq_enabled():
    data = request.json
    return jsonify(engine.set_eq_enabled(data.get('enabled', True)))

@app.route('/api/status', methods=['GET'])
def get_status():
    return jsonify(engine.get_status())

@app.route('/api/analyze', methods=['POST'])
def analyze():
    data = request.json
    return jsonify(engine.analyze_audio(data.get('file_path', '')))

if __name__ == '__main__':
    print("=" * 50)
    print("Auto EQ Backend Server")
    print("=" * 50)
    print("\nAudio devices:")
    print(sd.query_devices())
    print("\nDefault output:", sd.default.device[1])
    print("=" * 50)
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)

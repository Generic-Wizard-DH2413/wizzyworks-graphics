import librosa
import numpy as np
import json
import random
import os

# 🎵 Configuration
FIREWORK_TYPES = ["sphere", "cluster", "willow", "saturn", "chrysanthemum"]

def analyze_audio(file_path):
    print(f"Analyzing {file_path} ...")

    # Load audio (mono)
    y, sr = librosa.load(file_path, mono=True)

    # Detect onsets (peaks in the spectral flux)
    onset_frames = librosa.onset.onset_detect(y=y, sr=sr, backtrack=True)
    onset_times = librosa.frames_to_time(onset_frames, sr=sr)

    # Optional: smooth or filter onsets if too dense
    filtered_times = []
    last_t = -10
    min_gap = 1.0  # seconds between events
    for t in onset_times:
        if t - last_t > min_gap:
            filtered_times.append(t)
            last_t = t

    # Build events
    events = []
    for t in filtered_times:
        event = {
            "time": round(float(t), 2),
            "number_of_fireworks": random.randint(1, 5),
            "firework_type": random.choice(FIREWORK_TYPES)
        }
        events.append(event)

    sound_name = os.path.splitext(os.path.basename(file_path))[0]
    output_file = f"godot-visuals/json_fireworks/json_firework_shows/firework_show_{sound_name}.json"

    data = {
        "sound_file_name": os.path.basename(file_path),
        "events": events
    }

    with open(output_file, "w") as f:
        json.dump(data, f, indent=2)

    print(f"✅ Done! Saved {output_file} with {len(events)} events.")
    return data


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python firework_analyzer.py <audiofile.mp3>")
    else:
        analyze_audio(sys.argv[1])

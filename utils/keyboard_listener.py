import json
import time
import os
from pynput import keyboard
import pygame

# Available firework types
FIREWORK_TYPES = [
    "chrysanthemum",
    "willow",
    "sphere",
    "cluster",
    "another_cluster",
    "pistil",
    "saturn",
    "tornado",
    "fish",
    "drawing"
]

# Global state
current_firework_count = 1
selected_firework_type = None
start_time = None
music_file = None
is_playing = False
round_data = {"events": []}

def initialize_pygame():
    """Initialize pygame mixer for audio playback"""
    pygame.mixer.init()

def select_firework_type():
    """Let user select which firework type for this round"""
    print("\n" + "="*50)
    print("SELECT FIREWORK TYPE FOR THIS ROUND:")
    print("="*50)
    for idx, fw_type in enumerate(FIREWORK_TYPES, 1):
        print(f"{idx}. {fw_type}")
    
    while True:
        try:
            choice = input("\nEnter number (1-10): ")
            choice_idx = int(choice) - 1
            if 0 <= choice_idx < len(FIREWORK_TYPES):
                return FIREWORK_TYPES[choice_idx]
            else:
                print("Invalid choice. Please try again.")
        except ValueError:
            print("Please enter a valid number.")

def select_music_file():
    """Let user select a music file"""
    print("\n" + "="*50)
    print("SELECT MUSIC FILE:")
    print("="*50)
    
    music_path = input("Enter path to music file (or drag & drop): ").strip().strip('"')
    
    if os.path.exists(music_path):
        return music_path
    else:
        print(f"File not found: {music_path}")
        return None

def play_music():
    """Play the selected music file"""
    global is_playing, start_time
    if music_file and os.path.exists(music_file):
        try:
            pygame.mixer.music.load(music_file)
            pygame.mixer.music.play()
            is_playing = True
            start_time = time.time()
            print(f"\n🎵 Playing: {os.path.basename(music_file)}")
            print("="*50)
        except Exception as e:
            print(f"Error playing music: {e}")

def pause_music():
    """Pause/unpause music"""
    global is_playing
    if is_playing:
        pygame.mixer.music.pause()
        is_playing = False
        print("⏸️  Music paused")
    else:
        pygame.mixer.music.unpause()
        is_playing = True
        print("▶️  Music resumed")

def stop_music():
    """Stop music playback"""
    global is_playing
    pygame.mixer.music.stop()
    is_playing = False
    print("⏹️  Music stopped")

def save_round():
    """Save current round to a file"""
    if not round_data["events"]:
        print("\n⚠️  No events recorded in this round!")
        return None
    
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    filename = f"round_{selected_firework_type}_{timestamp}.json"
    
    # Add sound file name to the data
    music_filename = os.path.basename(music_file) if music_file else "unknown"
    round_data["sound_file_name"] = music_filename
    
    with open(filename, "w") as file:
        json.dump(round_data, file, indent=4)
    
    print(f"\n✅ Round saved to: {filename}")
    return filename

# Global list to track all round files from this session
session_rounds = []

def on_press(key):
    global current_firework_count, start_time
    
    try:
        # Number keys 1-4 to record event immediately
        if hasattr(key, 'char') and key.char in ['1', '2', '3', '4']:
            if start_time is None:
                print("⚠️  Music not started yet!")
                return
            
            current_firework_count = int(key.char)
            current_time = round(time.time() - start_time, 2)
            event = {
                "time": current_time,
                "number_of_fireworks": current_firework_count,
                "firework_type": selected_firework_type
            }
            
            round_data["events"].append(event)
            print(f"✨ Added: {current_firework_count}x {selected_firework_type} at {current_time}s")
        
        # P to pause/unpause
        elif hasattr(key, 'char') and key.char == 'p':
            pause_music()
        
        # S to stop and restart
        elif hasattr(key, 'char') and key.char == 's':
            stop_music()
            start_time = None
            print("Press ENTER to restart music")
        
        # R to restart from beginning
        elif hasattr(key, 'char') and key.char == 'r':
            stop_music()
            play_music()
        
        # Enter to start music
        elif key == keyboard.Key.enter:
            if not is_playing and start_time is None:
                play_music()
        
        # ESC to finish this round
        elif key == keyboard.Key.esc:
            stop_music()
            print("\n✅ Round finished!")
            return False
            
    except Exception as e:
        print(f"Error: {e}")

def combine_rounds_from_list(round_files):
    """Combine specific round files into one final show"""
    if not round_files:
        print("No rounds to combine.")
        return
    
    combined_data = {"events": []}
    sound_file_name = None
    
    for filename in round_files:
        if os.path.exists(filename):
            with open(filename, "r") as file:
                data = json.load(file)
                combined_data["events"].extend(data["events"])
                # Get sound file name from first round
                if sound_file_name is None and "sound_file_name" in data:
                    sound_file_name = data["sound_file_name"]
        else:
            print(f"⚠️  Warning: File not found: {filename}")
    
    # Add sound file name to combined data
    if sound_file_name:
        combined_data["sound_file_name"] = sound_file_name
    
    # Sort by time
    combined_data["events"].sort(key=lambda x: x["time"])
    
    # Generate default filename based on music file
    if sound_file_name:
        # Remove extension from music file
        music_base = os.path.splitext(sound_file_name)[0]
        default_filename = f"{music_base}_firework_show.json"
    else:
        default_filename = "final_show.json"
    
    output_filename = input(f"\nEnter output filename (default: {default_filename}): ").strip()
    if not output_filename:
        output_filename = default_filename
    elif not output_filename.endswith('.json'):
        output_filename += '.json'
    
    with open(output_filename, "w") as file:
        json.dump(combined_data, file, indent=4)
    
    print(f"\n✅ Combined {len(round_files)} rounds into: {output_filename}")
    print(f"📊 Total events: {len(combined_data['events'])}")

def combine_rounds():
    """Combine multiple round files into one final show"""
    print("\n" + "="*50)
    print("COMBINE ROUNDS INTO FINAL SHOW")
    print("="*50)
    
    round_files = []
    print("Enter round file names (one per line, empty line to finish):")
    while True:
        filename = input("> ").strip()
        if not filename:
            break
        if os.path.exists(filename):
            round_files.append(filename)
        else:
            print(f"⚠️  File not found: {filename}")
    
    combine_rounds_from_list(round_files)

def start_round():
    """Start a new round with the current music file"""
    global selected_firework_type, start_time, round_data
    
    # Reset round data
    round_data = {"events": []}
    start_time = None
    
    # Select firework type for this round
    selected_firework_type = select_firework_type()
    print(f"\n✅ Selected: {selected_firework_type}")
    
    print("\n" + "="*50)
    print("CONTROLS:")
    print("="*50)
    print("1-4      : Record event with that many fireworks")
    print("ENTER    : Start music")
    print("P        : Pause/Resume music")
    print("R        : Restart music from beginning")
    print("S        : Stop music")
    print("ESC      : Save round and continue")
    print("="*50)
    print("\nPress ENTER when ready to start...")
    
    with keyboard.Listener(on_press=on_press) as listener:
        listener.join()
    
    # Save the round and return the filename
    filename = save_round()
    if filename:
        session_rounds.append(filename)
    
    return filename

def main():
    global music_file
    
    initialize_pygame()
    
    print("\n🎆 FIREWORK SHOW DESIGNER 🎆")
    print("="*50)
    
    # Select music file ONCE at the start
    music_file = select_music_file()
    if not music_file:
        print("No valid music file selected. Exiting.")
        return
    
    print(f"\n✅ Music file: {os.path.basename(music_file)}")
    
    # Start rounds loop
    while True:
        print("\n" + "="*50)
        print("STARTING NEW ROUND")
        print("="*50)
        
        start_round()
        
        # Ask what to do next
        print("\n" + "="*50)
        print("NEXT ACTION:")
        print("="*50)
        print("(1) Start another round")
        print("(2) Finalize and combine all rounds")
        print("(3) Quit without combining")
        
        while True:
            choice = input("\nChoose option (1/2/3): ").strip()
            
            if choice == '1':
                # Continue to next round
                break
            elif choice == '2':
                # Combine all rounds from this session
                if session_rounds:
                    print(f"\nCombining {len(session_rounds)} rounds...")
                    for i, filename in enumerate(session_rounds, 1):
                        print(f"  {i}. {filename}")
                    
                    combine_rounds_from_list(session_rounds)
                else:
                    print("\n⚠️  No rounds to combine!")
                print("\n✅ Session ended!")
                return
            elif choice == '3':
                print("\n👋 Exiting without combining...")
                print("\n✅ Session ended!")
                return
            else:
                print("Invalid choice. Please enter 1, 2, or 3.")

if __name__ == "__main__":
    main()

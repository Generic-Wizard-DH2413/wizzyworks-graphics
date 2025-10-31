import json
import sys
from pathlib import Path


def sort_firework_json(input_file, output_file=None):
    """
    Sort a firework show JSON file by the 'time' field in events.
    
    Args:
        input_file: Path to the input JSON file
        output_file: Path to the output JSON file (optional, defaults to overwriting input)
    """
    # Read the JSON file
    with open(input_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # Check if 'events' key exists
    if 'events' not in data:
        print(f"Error: No 'events' key found in {input_file}")
        return False
    
    # Sort events by time
    data['events'].sort(key=lambda x: x['time'])
    
    # Determine output file
    if output_file is None:
        output_file = input_file
    
    # Write the sorted data back
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent='\t')
    
    print(f"✓ Sorted {len(data['events'])} events by time")
    print(f"✓ Output written to: {output_file}")
    return True


def sort_all_firework_jsons(directory):
    """
    Sort all JSON files in a directory.
    
    Args:
        directory: Path to the directory containing JSON files
    """
    directory = Path(directory)
    json_files = list(directory.glob('*.json'))
    
    if not json_files:
        print(f"No JSON files found in {directory}")
        return
    
    print(f"Found {len(json_files)} JSON file(s) to sort\n")
    
    success_count = 0
    for json_file in json_files:
        print(f"Processing: {json_file.name}")
        if sort_firework_json(json_file):
            success_count += 1
        print()
    
    print(f"Successfully sorted {success_count}/{len(json_files)} files")


def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python sort_firework_json.py <input_file.json> [output_file.json]")
        print("  python sort_firework_json.py --dir <directory>")
        print("\nExamples:")
        print("  python sort_firework_json.py Gravity_fade.json")
        print("  python sort_firework_json.py Gravity_fade.json Gravity_fade_sorted.json")
        print("  python sort_firework_json.py --dir json_firework_shows/")
        sys.exit(1)
    
    if sys.argv[1] == '--dir':
        if len(sys.argv) < 3:
            print("Error: Please provide a directory path")
            sys.exit(1)
        sort_all_firework_jsons(sys.argv[2])
    else:
        input_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else None
        sort_firework_json(input_file, output_file)


if __name__ == '__main__':
    main()

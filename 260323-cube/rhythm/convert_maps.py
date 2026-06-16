import json
import sys

osu_file_path = sys.argv[1] if len(sys.argv) > 1 else './beatmap.osu'

hit_objects = []
metadata = {}
general = {}
difficulty = {}
timing_points = []

with open(osu_file_path, 'r', encoding='utf-8-sig') as f:
    current_section = None

    for line in f:
        line = line.strip()
        if not line:
            continue

        if line.startswith('[') and line.endswith(']'):
            current_section = line[1:-1]
            continue

        if current_section == 'Metadata' and ':' in line:
            key, value = line.split(':', 1)
            metadata[key.strip()] = value.strip()

        elif current_section == 'General' and ':' in line:
            key, value = line.split(':', 1)
            general[key.strip()] = value.strip()

        elif current_section == 'Difficulty' and ':' in line:
            key, value = line.split(':', 1)
            difficulty[key.strip()] = value.strip()

        elif current_section == 'TimingPoints':
            parts = line.split(',')
            if len(parts) >= 2:
                offset_ms = float(parts[0])
                ms_per_beat = float(parts[1])
                # Negative ms_per_beat = inherited (SV) point, skip
                if ms_per_beat > 0:
                    bpm = round(60000.0 / ms_per_beat, 4)
                    timing_points.append({
                        'offset': round(offset_ms, 4),
                        'ms_per_beat': round(ms_per_beat, 4),
                        'bpm': bpm
                    })

        elif current_section == 'HitObjects':
            parts = line.split(',')
            if len(parts) >= 5:
                x = int(parts[0])
                time_ms = round(float(parts[2]), 4)
                obj_type = int(parts[3])

                # Collapse 4 lanes to 2:
                # x=0 (lane 0) and x=128 (lane 1) -> lane 0 (top)
                # x=256 (lane 2) and x=384 (lane 3) -> lane 1 (bottom)
                four_lane = x // 128
                four_lane = min(3, max(0, four_lane))
                lane = 0 if four_lane <= 1 else 1

                note = {
                    'lane': lane,
                    'time': time_ms,
                    'type': 'note'
                }

                hit_objects.append(note)

# Use first uninherited timing point as the master
master = timing_points[0] if timing_points else {'offset': 0, 'ms_per_beat': 500, 'bpm': 120.0}

result = {
    'title': metadata.get('Title', 'Unknown'),
    'artist': metadata.get('Artist', 'Unknown'),
    'audio_filename': general.get('AudioFilename', 'audio.mp3'),
    'bpm': master['bpm'],
    'offset': master['offset'],
    'ms_per_beat': master['ms_per_beat'],
    'circle_size': 2,
    'hit_objects': hit_objects
}

output_path = osu_file_path.replace('.osu', '.json')
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(result, f, indent=2, ensure_ascii=False)

print(f"Conversion complete -> {output_path}")
print(f"  Title:      {result['title']}")
print(f"  Artist:     {result['artist']}")
print(f"  BPM:        {result['bpm']}")
print(f"  Offset:     {result['offset']}ms")
print(f"  Total notes:{len(hit_objects)}")

lane_counts = [0, 0]
for note in hit_objects:
    lane_counts[note['lane']] += 1
print(f"  Lane 0 (top):    {lane_counts[0]} notes  [D / F keys]")
print(f"  Lane 1 (bottom): {lane_counts[1]} notes  [J / K keys]")

print(f"\nFirst 10 notes:")
lane_keys = ['D or F', 'J or K']
for i, note in enumerate(hit_objects[:10]):
    print(f"  {i+1}. Lane {note['lane']} ({lane_keys[note['lane']]}): {note['time']}ms")

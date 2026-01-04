#!/usr/bin/env bash

MUSIC_FILE="$1"
USER="$2"

echo "Starting wakeup music player..."

# Only play music between 6:00 AM and 11:00 AM
# CURRENT_HOUR=$(date +%H)

# if [ "$CURRENT_HOUR" -lt 6 ] || [ "$CURRENT_HOUR" -ge 11 ]; then
#   echo "Not within wakeup window (6:00-11:00 AM). Current time: $(date +%H:%M). Skipping music."
#   exit 0
# fi

# Check if we've already played the alarm today
TODAY=$(date +%Y-%m-%d)
MARKER_FILE="${STATE_DIRECTORY:-/var/lib/wakeup-music-player}/last-played"

if [ -f "$MARKER_FILE" ]; then
  LAST_PLAYED=$(cat "$MARKER_FILE")
  if [ "$LAST_PLAYED" = "$TODAY" ]; then
    echo "Alarm already played today ($TODAY). Marker file: $MARKER_FILE"
    exit 0
  fi
  echo "Marker file exists but is from a previous day ($LAST_PLAYED). Proceeding to play music..."
fi

echo "First boot today within wakeup window. Proceeding to play music..."

# Wait a bit for the audio system to be fully ready
sleep 5

# Check if the music file exists
if [ ! -f "$MUSIC_FILE" ]; then
  echo "ERROR: Music file not found at $MUSIC_FILE"
  exit 1
fi

# Create marker file BEFORE playing music so we don't play again even if interrupted
echo "$TODAY" > "$MARKER_FILE"
echo "Created marker file: $MARKER_FILE with date: $TODAY"

echo "Playing wakeup music from $MUSIC_FILE..."

# Play the music file using mpv in the background, detached from this script
# --no-video: Don't show video window
# --loop=3: Play 3 times in case user is deep asleep
# --volume=80: Set volume to 80%
# Run in background and disown so the script can exit immediately
mpv --no-video --loop=3 --volume=80 "$MUSIC_FILE" &
MPV_PID=$!
disown

echo "Wakeup music started in background (PID: $MPV_PID)"

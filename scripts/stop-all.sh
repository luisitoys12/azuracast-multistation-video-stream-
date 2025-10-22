#!/bin/bash

# Stop all station video streams

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATIONS_DIR="$(dirname "$SCRIPT_DIR")/stations"

echo "=========================================="
echo "Stopping All Station Video Streams"
echo "=========================================="

STOPPED_COUNT=0

for STATION_PATH in "$STATIONS_DIR"/*; do
    if [ -d "$STATION_PATH" ]; then
        STATION_NAME=$(basename "$STATION_PATH")
        PID_DIR="$STATION_PATH/pids"
        
        # Stop FFmpeg
        if [ -f "$PID_DIR/ffmpeg.pid" ]; then
            PID=$(cat "$PID_DIR/ffmpeg.pid")
            if ps -p "$PID" > /dev/null 2>&1; then
                echo "Stopping FFmpeg for station: $STATION_NAME (PID: $PID)"
                kill "$PID"
                rm -f "$PID_DIR/ffmpeg.pid"
                STOPPED_COUNT=$((STOPPED_COUNT + 1))
            fi
        fi
        
        # Stop Now Playing updater
        if [ -f "$PID_DIR/nowplaying.pid" ]; then
            PID=$(cat "$PID_DIR/nowplaying.pid")
            if ps -p "$PID" > /dev/null 2>&1; then
                kill "$PID" 2>/dev/null || true
                rm -f "$PID_DIR/nowplaying.pid"
            fi
        fi
    fi
done

echo "=========================================="
echo "Stopped $STOPPED_COUNT station(s)"
echo "=========================================="

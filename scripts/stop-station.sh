#!/bin/bash

# Stop a specific station video stream

if [ -z "$1" ]; then
    echo "Usage: $0 <station_name>"
    echo "Example: $0 station1"
    exit 1
fi

STATION_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATIONS_DIR="$(dirname "$SCRIPT_DIR")/stations"
STATION_PATH="$STATIONS_DIR/$STATION_NAME"

if [ ! -d "$STATION_PATH" ]; then
    echo "Error: Station directory not found: $STATION_PATH"
    exit 1
fi

PID_DIR="$STATION_PATH/pids"

echo "Stopping station: $STATION_NAME"

# Stop FFmpeg
if [ -f "$PID_DIR/ffmpeg.pid" ]; then
    PID=$(cat "$PID_DIR/ffmpeg.pid")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Stopping FFmpeg (PID: $PID)"
        kill "$PID"
        rm -f "$PID_DIR/ffmpeg.pid"
        echo "✓ FFmpeg stopped"
    else
        echo "FFmpeg is not running (removing stale PID file)"
        rm -f "$PID_DIR/ffmpeg.pid"
    fi
else
    echo "FFmpeg is not running"
fi

# Stop Now Playing updater
if [ -f "$PID_DIR/nowplaying.pid" ]; then
    PID=$(cat "$PID_DIR/nowplaying.pid")
    if ps -p "$PID" > /dev/null 2>&1; then
        kill "$PID" 2>/dev/null || true
        rm -f "$PID_DIR/nowplaying.pid"
    fi
fi

echo "✓ Station '$STATION_NAME' stopped"

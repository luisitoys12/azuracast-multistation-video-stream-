#!/bin/bash

# Start a specific station video stream

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

CONFIG_FILE="$STATION_PATH/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Check if already running
PID_FILE="$STATION_PATH/pids/ffmpeg.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Station '$STATION_NAME' is already running (PID: $PID)"
        exit 1
    fi
fi

echo "Starting station: $STATION_NAME"
bash "$SCRIPT_DIR/station-stream.sh" "$STATION_PATH" &

sleep 2

# Verify it started
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "✓ Station '$STATION_NAME' started successfully (PID: $PID)"
    else
        echo "✗ Station '$STATION_NAME' failed to start"
        exit 1
    fi
else
    echo "✗ Station '$STATION_NAME' failed to start (no PID file)"
    exit 1
fi

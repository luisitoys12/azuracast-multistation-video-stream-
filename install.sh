#!/bin/bash

# AzuraCast Multi-Station Video Streaming Plugin - Global Installer
# This script launches all configured station video streams

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATIONS_DIR="$SCRIPT_DIR/stations"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

echo "=========================================="
echo "AzuraCast Multi-Station Video Streaming"
echo "Global Installation Script"
echo "=========================================="

# Check for required dependencies
echo "Checking dependencies..."

if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed"
    echo "Install with: apt-get install ffmpeg"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    echo "Install with: apt-get install jq"
    exit 1
fi

echo "✓ ffmpeg installed"
echo "✓ jq installed"
echo ""

# Check if stations directory exists
if [ ! -d "$STATIONS_DIR" ]; then
    echo "Error: Stations directory not found: $STATIONS_DIR"
    exit 1
fi

# Find all station directories with config.json
STATION_COUNT=0
STARTED_COUNT=0

echo "Scanning for configured stations..."
echo ""

for STATION_PATH in "$STATIONS_DIR"/*; do
    if [ -d "$STATION_PATH" ]; then
        STATION_NAME=$(basename "$STATION_PATH")
        CONFIG_FILE="$STATION_PATH/config.json"
        
        if [ -f "$CONFIG_FILE" ]; then
            STATION_COUNT=$((STATION_COUNT + 1))
            
            # Check if already running
            PID_FILE="$STATION_PATH/pids/ffmpeg.pid"
            if [ -f "$PID_FILE" ]; then
                PID=$(cat "$PID_FILE")
                if ps -p "$PID" > /dev/null 2>&1; then
                    echo "⚠ Station '$STATION_NAME' is already running (PID: $PID)"
                    continue
                fi
            fi
            
            echo "Starting station: $STATION_NAME"
            
            # Start the station stream in background
            bash "$SCRIPTS_DIR/station-stream.sh" "$STATION_PATH" &
            
            # Give it a moment to initialize
            sleep 2
            
            # Verify it started
            if [ -f "$PID_FILE" ]; then
                PID=$(cat "$PID_FILE")
                if ps -p "$PID" > /dev/null 2>&1; then
                    echo "✓ Station '$STATION_NAME' started successfully (PID: $PID)"
                    STARTED_COUNT=$((STARTED_COUNT + 1))
                else
                    echo "✗ Station '$STATION_NAME' failed to start"
                fi
            else
                echo "✗ Station '$STATION_NAME' failed to start (no PID file)"
            fi
            echo ""
        fi
    fi
done

echo "=========================================="
echo "Installation Summary"
echo "=========================================="
echo "Total stations found: $STATION_COUNT"
echo "Stations started: $STARTED_COUNT"
echo "=========================================="

if [ $STARTED_COUNT -eq 0 ]; then
    echo ""
    echo "No stations were started. Please check:"
    echo "1. Station config.json files are properly configured"
    echo "2. Video/audio sources are accessible"
    echo "3. Check station log files for errors"
    exit 1
fi

echo ""
echo "All configured stations are now streaming!"
echo ""
echo "To check status: bash $SCRIPT_DIR/scripts/status.sh"
echo "To stop all: bash $SCRIPT_DIR/scripts/stop-all.sh"
echo ""

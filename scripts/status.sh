#!/bin/bash

# Check status of all station video streams

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATIONS_DIR="$(dirname "$SCRIPT_DIR")/stations"

echo "=========================================="
echo "Station Video Streams Status"
echo "=========================================="

RUNNING_COUNT=0
TOTAL_COUNT=0

for STATION_PATH in "$STATIONS_DIR"/*; do
    if [ -d "$STATION_PATH" ]; then
        STATION_NAME=$(basename "$STATION_PATH")
        CONFIG_FILE="$STATION_PATH/config.json"
        
        if [ -f "$CONFIG_FILE" ]; then
            TOTAL_COUNT=$((TOTAL_COUNT + 1))
            PID_FILE="$STATION_PATH/pids/ffmpeg.pid"
            
            echo ""
            echo "Station: $STATION_NAME"
            
            if [ -f "$PID_FILE" ]; then
                PID=$(cat "$PID_FILE")
                if ps -p "$PID" > /dev/null 2>&1; then
                    echo "  Status: RUNNING (PID: $PID)"
                    RUNNING_COUNT=$((RUNNING_COUNT + 1))
                    
                    # Show HLS output if enabled
                    if command -v jq &> /dev/null; then
                        HLS_ENABLED=$(jq -r '.outputs.hls.enabled' "$CONFIG_FILE")
                        if [ "$HLS_ENABLED" = "true" ]; then
                            HLS_OUTPUT_DIR=$(jq -r '.outputs.hls.output_dir' "$CONFIG_FILE")
                            HLS_PLAYLIST=$(jq -r '.outputs.hls.playlist_name' "$CONFIG_FILE")
                            if [ -f "$HLS_OUTPUT_DIR/$HLS_PLAYLIST" ]; then
                                echo "  HLS Playlist: $HLS_OUTPUT_DIR/$HLS_PLAYLIST"
                            fi
                        fi
                        
                        # Show active RTMP outputs
                        RTMP_COUNT=$(jq '[.outputs.rtmp[] | select(.enabled == true)] | length' "$CONFIG_FILE")
                        if [ "$RTMP_COUNT" -gt 0 ]; then
                            echo "  Active RTMP outputs: $RTMP_COUNT"
                        fi
                    fi
                    
                    # Show now playing if available
                    NOWPLAYING_FILE="$STATION_PATH/nowplaying.txt"
                    if [ -f "$NOWPLAYING_FILE" ]; then
                        NOWPLAYING=$(cat "$NOWPLAYING_FILE")
                        echo "  $NOWPLAYING"
                    fi
                else
                    echo "  Status: STOPPED (stale PID file)"
                fi
            else
                echo "  Status: STOPPED"
            fi
        fi
    fi
done

echo ""
echo "=========================================="
echo "Summary: $RUNNING_COUNT/$TOTAL_COUNT stations running"
echo "=========================================="

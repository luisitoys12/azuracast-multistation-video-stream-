#!/bin/bash

# Station Video Streaming Script for AzuraCast
# This script handles video streaming with now-playing info for a single station

set -e

STATION_DIR="$1"
if [ -z "$STATION_DIR" ]; then
    echo "Usage: $0 <station_directory>"
    echo "Example: $0 /path/to/stations/station1"
    exit 1
fi

if [ ! -d "$STATION_DIR" ]; then
    echo "Error: Station directory '$STATION_DIR' does not exist"
    exit 1
fi

CONFIG_FILE="$STATION_DIR/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file '$CONFIG_FILE' not found"
    exit 1
fi

# Parse JSON config (requires jq)
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Install with: apt-get install jq"
    exit 1
fi

# Read configuration
STATION_ID=$(jq -r '.station_id' "$CONFIG_FILE")
STATION_NAME=$(jq -r '.station_name' "$CONFIG_FILE")
NOWPLAYING_URL=$(jq -r '.azuracast_nowplaying_url' "$CONFIG_FILE")
API_KEY=$(jq -r '.azuracast_api_key' "$CONFIG_FILE")

# Video settings
BG_IMAGE=$(jq -r '.video.background_image' "$CONFIG_FILE")
BG_VIDEO=$(jq -r '.video.background_video' "$CONFIG_FILE")
USE_VIDEO_BG=$(jq -r '.video.use_video_background' "$CONFIG_FILE")
VIDEO_WIDTH=$(jq -r '.video.width' "$CONFIG_FILE")
VIDEO_HEIGHT=$(jq -r '.video.height' "$CONFIG_FILE")
VIDEO_FPS=$(jq -r '.video.fps' "$CONFIG_FILE")
VIDEO_BITRATE=$(jq -r '.video.bitrate' "$CONFIG_FILE")
FONT_FILE=$(jq -r '.video.font_file' "$CONFIG_FILE")
FONT_SIZE=$(jq -r '.video.font_size' "$CONFIG_FILE")
TEXT_COLOR=$(jq -r '.video.text_color' "$CONFIG_FILE")
TEXT_POSITION=$(jq -r '.video.text_position' "$CONFIG_FILE")

# Audio settings
AUDIO_URL=$(jq -r '.audio.stream_url' "$CONFIG_FILE")
AUDIO_BITRATE=$(jq -r '.audio.bitrate' "$CONFIG_FILE")
AUDIO_SAMPLE_RATE=$(jq -r '.audio.sample_rate' "$CONFIG_FILE")

# HLS settings
HLS_ENABLED=$(jq -r '.outputs.hls.enabled' "$CONFIG_FILE")
HLS_OUTPUT_DIR=$(jq -r '.outputs.hls.output_dir' "$CONFIG_FILE")
HLS_PLAYLIST=$(jq -r '.outputs.hls.playlist_name' "$CONFIG_FILE")
HLS_SEGMENT_DURATION=$(jq -r '.outputs.hls.segment_duration' "$CONFIG_FILE")
HLS_SEGMENT_LIST_SIZE=$(jq -r '.outputs.hls.segment_list_size' "$CONFIG_FILE")
HLS_VIDEO_BITRATE=$(jq -r '.outputs.hls.video_bitrate' "$CONFIG_FILE")
HLS_AUDIO_BITRATE=$(jq -r '.outputs.hls.audio_bitrate' "$CONFIG_FILE")

# Create output directory
mkdir -p "$HLS_OUTPUT_DIR"

# Create PID file directory
PID_DIR="$STATION_DIR/pids"
mkdir -p "$PID_DIR"

# Temporary file for now playing info
NOWPLAYING_FILE="$STATION_DIR/nowplaying.txt"
echo "Now Playing: Loading..." > "$NOWPLAYING_FILE"

echo "=========================================="
echo "Starting Video Stream for $STATION_NAME"
echo "Station ID: $STATION_ID"
echo "=========================================="

# Function to fetch now playing info
fetch_nowplaying() {
    while true; do
        if [ -n "$API_KEY" ] && [ "$API_KEY" != "YOUR_API_KEY_HERE" ]; then
            NOWPLAYING_DATA=$(curl -s -H "X-API-Key: $API_KEY" "$NOWPLAYING_URL" || echo '{}')
        else
            NOWPLAYING_DATA=$(curl -s "$NOWPLAYING_URL" || echo '{}')
        fi
        
        ARTIST=$(echo "$NOWPLAYING_DATA" | jq -r '.now_playing.song.artist // "Unknown Artist"')
        TITLE=$(echo "$NOWPLAYING_DATA" | jq -r '.now_playing.song.title // "Unknown Title"')
        
        if [ "$ARTIST" != "null" ] && [ "$TITLE" != "null" ]; then
            echo "Now Playing: $ARTIST - $TITLE" > "$NOWPLAYING_FILE"
        else
            echo "Now Playing: $STATION_NAME" > "$NOWPLAYING_FILE"
        fi
        
        sleep 10
    done
}

# Start now playing updater in background
fetch_nowplaying &
NOWPLAYING_PID=$!
echo $NOWPLAYING_PID > "$PID_DIR/nowplaying.pid"

# Build FFmpeg command
FFMPEG_CMD="ffmpeg -re"

# Input source (background)
if [ "$USE_VIDEO_BG" = "true" ] && [ -f "$BG_VIDEO" ]; then
    FFMPEG_CMD="$FFMPEG_CMD -stream_loop -1 -i \"$BG_VIDEO\""
elif [ -f "$BG_IMAGE" ]; then
    FFMPEG_CMD="$FFMPEG_CMD -loop 1 -i \"$BG_IMAGE\""
else
    # Use color background if no image/video
    FFMPEG_CMD="$FFMPEG_CMD -f lavfi -i color=c=black:s=${VIDEO_WIDTH}x${VIDEO_HEIGHT}:r=${VIDEO_FPS}"
fi

# Audio input
FFMPEG_CMD="$FFMPEG_CMD -i \"$AUDIO_URL\""

# Video filter with now playing text
FILTER_COMPLEX="[0:v]scale=${VIDEO_WIDTH}:${VIDEO_HEIGHT},setsar=1[bg];"
FILTER_COMPLEX="${FILTER_COMPLEX}[bg]drawtext=fontfile='${FONT_FILE}':textfile='${NOWPLAYING_FILE}':reload=1:fontsize=${FONT_SIZE}:fontcolor=${TEXT_COLOR}:${TEXT_POSITION}[out]"

FFMPEG_CMD="$FFMPEG_CMD -filter_complex \"$FILTER_COMPLEX\""
FFMPEG_CMD="$FFMPEG_CMD -map '[out]' -map 1:a"

# Video encoding settings
FFMPEG_CMD="$FFMPEG_CMD -c:v libx264 -preset veryfast -g $((VIDEO_FPS * 2)) -keyint_min $VIDEO_FPS"
FFMPEG_CMD="$FFMPEG_CMD -c:a aac -ar $AUDIO_SAMPLE_RATE"

# Output configurations
OUTPUT_COUNT=0

# RTMP outputs
RTMP_COUNT=$(jq '.outputs.rtmp | length' "$CONFIG_FILE")
for ((i=0; i<$RTMP_COUNT; i++)); do
    ENABLED=$(jq -r ".outputs.rtmp[$i].enabled" "$CONFIG_FILE")
    if [ "$ENABLED" = "true" ]; then
        RTMP_NAME=$(jq -r ".outputs.rtmp[$i].name" "$CONFIG_FILE")
        RTMP_URL=$(jq -r ".outputs.rtmp[$i].url" "$CONFIG_FILE")
        RTMP_VIDEO_BITRATE=$(jq -r ".outputs.rtmp[$i].video_bitrate" "$CONFIG_FILE")
        RTMP_AUDIO_BITRATE=$(jq -r ".outputs.rtmp[$i].audio_bitrate" "$CONFIG_FILE")
        
        echo "Configuring RTMP output: $RTMP_NAME"
        FFMPEG_CMD="$FFMPEG_CMD -b:v:$OUTPUT_COUNT $RTMP_VIDEO_BITRATE -b:a:$OUTPUT_COUNT $RTMP_AUDIO_BITRATE"
        FFMPEG_CMD="$FFMPEG_CMD -f flv \"$RTMP_URL\""
        OUTPUT_COUNT=$((OUTPUT_COUNT + 1))
    fi
done

# HLS output
if [ "$HLS_ENABLED" = "true" ]; then
    echo "Configuring HLS output: $HLS_OUTPUT_DIR/$HLS_PLAYLIST"
    FFMPEG_CMD="$FFMPEG_CMD -b:v $HLS_VIDEO_BITRATE -b:a $HLS_AUDIO_BITRATE"
    FFMPEG_CMD="$FFMPEG_CMD -f hls -hls_time $HLS_SEGMENT_DURATION"
    FFMPEG_CMD="$FFMPEG_CMD -hls_list_size $HLS_SEGMENT_LIST_SIZE"
    FFMPEG_CMD="$FFMPEG_CMD -hls_flags delete_segments+append_list"
    FFMPEG_CMD="$FFMPEG_CMD -hls_segment_filename \"$HLS_OUTPUT_DIR/segment_%03d.ts\""
    FFMPEG_CMD="$FFMPEG_CMD \"$HLS_OUTPUT_DIR/$HLS_PLAYLIST\""
fi

# Log file
LOG_FILE="$STATION_DIR/stream.log"

echo "Starting FFmpeg stream..."
echo "Log file: $LOG_FILE"
echo "Command: $FFMPEG_CMD"

# Execute FFmpeg
eval "$FFMPEG_CMD" > "$LOG_FILE" 2>&1 &
FFMPEG_PID=$!
echo $FFMPEG_PID > "$PID_DIR/ffmpeg.pid"

echo "=========================================="
echo "Stream started successfully!"
echo "FFmpeg PID: $FFMPEG_PID"
echo "Now Playing Updater PID: $NOWPLAYING_PID"
echo "=========================================="

# Wait for FFmpeg to finish (or be killed)
wait $FFMPEG_PID

# Cleanup
kill $NOWPLAYING_PID 2>/dev/null || true
rm -f "$PID_DIR/ffmpeg.pid" "$PID_DIR/nowplaying.pid"

#!/bin/bash

# Setup example station with test data
# This script creates a working example configuration for testing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
STATION_NAME="example"
STATION_DIR="$ROOT_DIR/stations/$STATION_NAME"

echo "=========================================="
echo "Setting up example station"
echo "=========================================="

# Create station directory
mkdir -p "$STATION_DIR"

# Create example config
cat > "$STATION_DIR/config.json" <<EOF
{
  "station_id": "$STATION_NAME",
  "station_name": "Example Radio Station",
  "azuracast_nowplaying_url": "https://demo.azuracast.com/api/nowplaying/1",
  "azuracast_api_key": "",
  
  "video": {
    "background_image": "$STATION_DIR/background.jpg",
    "background_video": "",
    "use_video_background": false,
    "width": 1280,
    "height": 720,
    "fps": 25,
    "bitrate": "2000k",
    "font_file": "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "font_size": 40,
    "text_color": "white",
    "text_position": "x=(w-text_w)/2:y=h-80"
  },
  
  "audio": {
    "stream_url": "https://demo.azuracast.com/listen/azuratest_radio/radio.mp3",
    "bitrate": "128k",
    "sample_rate": "44100"
  },
  
  "outputs": {
    "rtmp": [],
    "hls": {
      "enabled": true,
      "output_dir": "$ROOT_DIR/output/$STATION_NAME",
      "playlist_name": "stream.m3u8",
      "segment_duration": 4,
      "segment_list_size": 5,
      "video_bitrate": "1500k",
      "audio_bitrate": "128k"
    }
  },
  
  "nowplaying": {
    "update_interval": 10,
    "format": "Now Playing: {artist} - {title}",
    "show_album": true,
    "show_artwork": false
  }
}
EOF

# Create a simple background image using ImageMagick or just a note
if command -v convert &> /dev/null; then
    echo "Creating background image with ImageMagick..."
    convert -size 1280x720 -background "#1a1a2e" -fill white \
            -pointsize 60 -gravity center \
            label:"Example Radio\nStation" \
            "$STATION_DIR/background.jpg"
else
    echo "ImageMagick not found, you'll need to provide your own background.jpg"
    echo "Creating placeholder note..."
    cat > "$STATION_DIR/BACKGROUND_NEEDED.txt" <<EOF
Please place a background image at:
$STATION_DIR/background.jpg

Recommended size: 1280x720 or 1920x1080
Format: JPG or PNG

You can download a free image from:
- https://unsplash.com
- https://pexels.com
EOF
fi

# Create output directory
mkdir -p "$ROOT_DIR/output/$STATION_NAME"

echo ""
echo "✓ Example station created at: $STATION_DIR"
echo ""
echo "Configuration:"
echo "  - Uses AzuraCast demo stream for testing"
echo "  - HLS output enabled"
echo "  - Resolution: 1280x720 @ 25fps"
echo "  - No RTMP outputs (add them in config.json if needed)"
echo ""

if [ ! -f "$STATION_DIR/background.jpg" ]; then
    echo "⚠ NOTE: You need to add a background image:"
    echo "  $STATION_DIR/background.jpg"
    echo ""
fi

echo "To start this example station:"
echo "  bash scripts/start-station.sh $STATION_NAME"
echo ""
echo "To test (requires ffmpeg and jq):"
echo "  bash install.sh"
echo ""

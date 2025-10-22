# AzuraCast Multi-Station Video Stream Plugin

A shell-based plugin for AzuraCast Docker that enables each radio station to stream its own personalized video with real-time "now playing" information, multiple RTMP outputs (YouTube, Facebook, Twitch), and HLS/m3u8 for VLC/IPTV playback.

## Features

- 🎥 **Video Streaming**: Each station can stream video with custom background images or videos
- 🎵 **Real-time Now Playing**: Automatically fetches and displays current track info from AzuraCast API
- 📡 **Multi-RTMP Support**: Stream simultaneously to YouTube, Facebook, Twitch, or custom RTMP servers
- 📺 **HLS/m3u8 Output**: Generate HLS streams for VLC, IPTV, and web players
- ⚙️ **Per-Station Configuration**: Each station has its own config.json and independent setup
- 🔧 **Easy Management**: Simple scripts to start, stop, and monitor all stations

## Requirements

- **FFmpeg** (with libx264 and AAC support)
- **jq** (JSON processor)
- **AzuraCast** instance running (for now-playing API)
- **Bash** shell

## Directory Structure

```
azuracast-multistation-video-stream-/
├── install.sh                    # Global installer - starts all stations
├── README.md                     # This file
├── stations/                     # Station configurations
│   ├── station1/
│   │   ├── config.json          # Station 1 configuration
│   │   ├── background.jpg       # Background image (optional)
│   │   ├── pids/                # Process IDs (auto-generated)
│   │   ├── nowplaying.txt       # Current track info (auto-generated)
│   │   └── stream.log           # FFmpeg logs (auto-generated)
│   └── station2/
│       └── config.json          # Station 2 configuration
├── scripts/                      # Management scripts
│   ├── station-stream.sh        # Core streaming script
│   ├── start-station.sh         # Start a specific station
│   ├── stop-station.sh          # Stop a specific station
│   ├── stop-all.sh              # Stop all stations
│   └── status.sh                # Check status of all stations
├── templates/
│   └── config.json.template     # Configuration template
└── output/                       # HLS output directories
    ├── station1/
    └── station2/
```

## Quick Start

### 1. Install Dependencies

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install ffmpeg jq

# Alpine (Docker)
apk add ffmpeg jq bash
```

### 2. Configure Your Stations

Each station needs a `config.json` file. Copy the template and customize:

```bash
cp templates/config.json.template stations/mystation/config.json
```

Edit `stations/mystation/config.json` with your settings:

```json
{
  "station_id": "mystation",
  "station_name": "My Radio Station",
  "azuracast_nowplaying_url": "http://localhost/api/nowplaying/1",
  "azuracast_api_key": "YOUR_API_KEY_HERE",
  
  "video": {
    "background_image": "/path/to/background.jpg",
    "width": 1920,
    "height": 1080,
    "fps": 30
  },
  
  "audio": {
    "stream_url": "http://localhost:8000/radio.mp3",
    "bitrate": "192k"
  },
  
  "outputs": {
    "rtmp": [
      {
        "enabled": true,
        "name": "YouTube",
        "url": "rtmp://a.rtmp.youtube.com/live2/YOUR_STREAM_KEY"
      }
    ],
    "hls": {
      "enabled": true,
      "output_dir": "./output/mystation",
      "playlist_name": "stream.m3u8"
    }
  }
}
```

### 3. Start All Stations

```bash
bash install.sh
```

This will:
- Check for dependencies
- Find all configured stations
- Start video streaming for each station
- Display status and PIDs

### 4. Check Status

```bash
bash scripts/status.sh
```

### 5. Access Your Streams

**HLS/m3u8 (for VLC/IPTV):**
```
http://your-server/output/station1/stream.m3u8
```

**RTMP streams** will be sent to the configured destinations (YouTube, Facebook, etc.)

## Management Commands

### Start a Specific Station

```bash
bash scripts/start-station.sh station1
```

### Stop a Specific Station

```bash
bash scripts/stop-station.sh station1
```

### Stop All Stations

```bash
bash scripts/stop-all.sh
```

### Check Status of All Stations

```bash
bash scripts/status.sh
```

## Configuration Guide

### Video Settings

```json
"video": {
  "background_image": "/path/to/image.jpg",     // Static background image
  "background_video": "/path/to/video.mp4",     // Loop video background
  "use_video_background": false,                // Use video instead of image
  "width": 1920,                                 // Video width
  "height": 1080,                                // Video height
  "fps": 30,                                     // Frames per second
  "bitrate": "3000k",                            // Video bitrate
  "font_file": "/path/to/font.ttf",             // Font for text overlay
  "font_size": 48,                               // Text size
  "text_color": "white",                         // Text color
  "text_position": "x=(w-text_w)/2:y=h-100"    // Text position (FFmpeg syntax)
}
```

### Audio Settings

```json
"audio": {
  "stream_url": "http://localhost:8000/radio.mp3",  // Audio source URL
  "bitrate": "192k",                                 // Audio bitrate
  "sample_rate": "44100"                             // Sample rate
}
```

### RTMP Outputs (YouTube, Facebook, Twitch)

```json
"rtmp": [
  {
    "enabled": true,
    "name": "YouTube",
    "url": "rtmp://a.rtmp.youtube.com/live2/YOUR_STREAM_KEY",
    "video_bitrate": "2500k",
    "audio_bitrate": "128k"
  },
  {
    "enabled": true,
    "name": "Facebook",
    "url": "rtmps://live-api-s.facebook.com:443/rtmp/YOUR_STREAM_KEY",
    "video_bitrate": "2500k",
    "audio_bitrate": "128k"
  }
]
```

**Getting Stream Keys:**
- **YouTube**: https://studio.youtube.com → Go Live → Stream Settings
- **Facebook**: https://www.facebook.com/live/producer → Stream Key
- **Twitch**: https://dashboard.twitch.tv/settings/stream → Primary Stream Key

### HLS Output Settings

```json
"hls": {
  "enabled": true,
  "output_dir": "./output/station1",    // Where to save HLS files
  "playlist_name": "stream.m3u8",       // Playlist filename
  "segment_duration": 4,                 // Segment length in seconds
  "segment_list_size": 5,                // Number of segments to keep
  "video_bitrate": "2000k",
  "audio_bitrate": "128k"
}
```

### Now Playing Settings

```json
"nowplaying": {
  "update_interval": 10,                           // Update every N seconds
  "format": "Now Playing: {artist} - {title}",    // Display format
  "show_album": true,
  "show_artwork": false
}
```

## Docker Integration

To use with AzuraCast Docker:

### 1. Add to docker-compose.override.yml

```yaml
services:
  web:
    volumes:
      - ./azuracast-multistation-video-stream:/var/azuracast/video-stream
    ports:
      - "8080:80"  # For HLS output access
```

### 2. Enter the container

```bash
docker-compose exec --user=azuracast web bash
cd /var/azuracast/video-stream
bash install.sh
```

### 3. Access HLS streams

```
http://your-azuracast-server:8080/output/station1/stream.m3u8
```

## Troubleshooting

### FFmpeg not found
```bash
sudo apt-get install ffmpeg
```

### jq not found
```bash
sudo apt-get install jq
```

### Station won't start

1. Check the log file: `cat stations/station1/stream.log`
2. Verify config.json syntax: `jq . stations/station1/config.json`
3. Test audio stream: `curl -I http://localhost:8000/radio.mp3`
4. Check AzuraCast API: `curl http://localhost/api/nowplaying/1`

### Stream quality issues

- Reduce video bitrate in config.json
- Lower FPS (24 or 25 instead of 30)
- Use smaller resolution (1280x720 instead of 1920x1080)

### Permission issues

```bash
chmod +x install.sh scripts/*.sh
```

## Advanced Usage

### Custom Text Positioning

The `text_position` field uses FFmpeg's drawtext filter syntax:

```json
"text_position": "x=(w-text_w)/2:y=h-100"  // Centered, 100px from bottom
"text_position": "x=10:y=10"               // Top-left corner
"text_position": "x=w-tw-10:y=10"          // Top-right corner
```

### Multiple Background Images

You can rotate backgrounds by using a script to update `background_image` periodically.

### Custom RTMP Servers

```json
{
  "enabled": true,
  "name": "Custom Server",
  "url": "rtmp://your-server.com:1935/live/streamkey",
  "video_bitrate": "2500k",
  "audio_bitrate": "128k"
}
```

## Performance Tips

1. **CPU Usage**: Video encoding is CPU-intensive. Use faster presets:
   - Modify `station-stream.sh` and change `-preset veryfast` to `-preset ultrafast`

2. **Multiple Outputs**: Each RTMP output adds overhead. Enable only what you need.

3. **HLS Segments**: Larger segments (6-10 seconds) reduce CPU but increase latency.

4. **Resolution**: 720p (1280x720) uses ~60% less CPU than 1080p (1920x1080).

## Credits

Created for the AzuraCast community to enable video streaming capabilities for internet radio stations.

## License

This project is open source. Feel free to modify and distribute.

## Support

For issues and questions:
- Check the log files in each station directory
- Verify FFmpeg and jq are properly installed
- Ensure AzuraCast API is accessible
- Test each component individually (audio stream, API, etc.)

---

**Happy Streaming! 🎵📺**

# Quick Reference Guide

## Common Commands

### Start/Stop Operations

```bash
# Start all configured stations
bash install.sh

# Start a specific station
bash scripts/start-station.sh station1

# Stop a specific station
bash scripts/stop-station.sh station1

# Stop all stations
bash scripts/stop-all.sh

# Check status of all stations
bash scripts/status.sh
```

### Setup and Configuration

```bash
# Create a new station
mkdir -p stations/newstation
cp templates/config.json.template stations/newstation/config.json
nano stations/newstation/config.json

# Setup example station (for testing)
bash scripts/setup-example.sh

# Validate JSON configuration
jq . stations/station1/config.json
```

### Monitoring

```bash
# View live logs for a station
tail -f stations/station1/stream.log

# Check if FFmpeg is running
ps aux | grep ffmpeg

# View process details
top -p $(cat stations/station1/pids/ffmpeg.pid)

# Check current now-playing info
cat stations/station1/nowplaying.txt
```

### Testing Streams

```bash
# Test HLS stream with VLC
vlc http://localhost/output/station1/stream.m3u8

# Check HLS playlist exists
curl -I http://localhost/output/station1/stream.m3u8

# Test audio stream
curl -I http://localhost:8000/radio.mp3

# Test AzuraCast API
curl http://localhost/api/nowplaying/1
```

## Configuration Snippets

### Minimal HLS-Only Configuration

```json
{
  "station_id": "mystation",
  "station_name": "My Station",
  "azuracast_nowplaying_url": "http://localhost/api/nowplaying/1",
  "azuracast_api_key": "",
  "video": {
    "background_image": "/path/to/background.jpg",
    "width": 1280,
    "height": 720,
    "fps": 25
  },
  "audio": {
    "stream_url": "http://localhost:8000/radio.mp3"
  },
  "outputs": {
    "rtmp": [],
    "hls": {
      "enabled": true,
      "output_dir": "./output/mystation"
    }
  }
}
```

### YouTube Live Stream

```json
"outputs": {
  "rtmp": [
    {
      "enabled": true,
      "name": "YouTube",
      "url": "rtmp://a.rtmp.youtube.com/live2/YOUR_KEY",
      "video_bitrate": "2500k",
      "audio_bitrate": "128k"
    }
  ]
}
```

### Multiple RTMP Outputs

```json
"outputs": {
  "rtmp": [
    {
      "enabled": true,
      "name": "YouTube",
      "url": "rtmp://a.rtmp.youtube.com/live2/YOUR_YOUTUBE_KEY"
    },
    {
      "enabled": true,
      "name": "Facebook",
      "url": "rtmps://live-api-s.facebook.com:443/rtmp/YOUR_FB_KEY"
    },
    {
      "enabled": true,
      "name": "Twitch",
      "url": "rtmp://live.twitch.tv/app/YOUR_TWITCH_KEY"
    }
  ]
}
```

### Video Background Instead of Image

```json
"video": {
  "background_video": "/path/to/video.mp4",
  "use_video_background": true
}
```

### Custom Text Positioning

```json
"video": {
  "text_position": "x=(w-text_w)/2:y=h-100",     // Center bottom
  "text_position": "x=10:y=10",                   // Top left
  "text_position": "x=w-tw-10:y=10",              // Top right
  "text_position": "x=(w-text_w)/2:y=(h-text_h)/2" // Center
}
```

## File Locations

```
Station Configuration:     stations/{station_name}/config.json
Background Image:          stations/{station_name}/background.jpg
FFmpeg Logs:              stations/{station_name}/stream.log
Process IDs:              stations/{station_name}/pids/*.pid
Now Playing Cache:        stations/{station_name}/nowplaying.txt
HLS Output:               output/{station_name}/stream.m3u8
HLS Segments:             output/{station_name}/segment_*.ts
```

## FFmpeg Presets

Edit `scripts/station-stream.sh` to change encoding preset:

- `-preset ultrafast` - Fastest, lowest quality, highest CPU efficiency
- `-preset veryfast` - Default, good balance (recommended)
- `-preset fast` - Better quality, more CPU
- `-preset medium` - Even better quality, much more CPU

## Recommended Settings by Use Case

### Low CPU / Testing
```json
"video": {
  "width": 1280,
  "height": 720,
  "fps": 25,
  "bitrate": "1500k"
}
```

### Standard Quality
```json
"video": {
  "width": 1920,
  "height": 1080,
  "fps": 30,
  "bitrate": "2500k"
}
```

### High Quality
```json
"video": {
  "width": 1920,
  "height": 1080,
  "fps": 30,
  "bitrate": "4000k"
}
```

## Troubleshooting Quick Checks

```bash
# Check dependencies
which ffmpeg jq curl

# Check if station is running
bash scripts/status.sh

# View errors in logs
tail -50 stations/station1/stream.log

# Test audio stream
curl -L -I http://localhost:8000/radio.mp3

# Test API endpoint
curl http://localhost/api/nowplaying/1 | jq .

# Check disk space for HLS segments
du -sh output/*

# Check FFmpeg process
ps aux | grep station1

# Kill stuck process
kill $(cat stations/station1/pids/ffmpeg.pid)
```

## Port Reference

- **8000-8999**: Common AzuraCast radio stream ports
- **1935**: RTMP standard port
- **8080**: Common HLS access port (when served via web)

## API Response Example

```json
{
  "station": {...},
  "listeners": {...},
  "now_playing": {
    "song": {
      "artist": "Artist Name",
      "title": "Song Title",
      "album": "Album Name"
    }
  }
}
```

## Getting Help

1. Check logs: `tail -f stations/station1/stream.log`
2. Validate config: `jq . stations/station1/config.json`
3. Test components individually (audio, API, FFmpeg)
4. Check system resources: `htop` or `top`
5. Verify permissions: `ls -la stations/station1/`

## Performance Optimization

```bash
# Monitor CPU usage
top

# Monitor specific FFmpeg process
top -p $(cat stations/station1/pids/ffmpeg.pid)

# Check memory usage
free -h

# Check disk I/O
iostat -x 1

# Monitor network (if streaming to RTMP)
iftop
```

---

For detailed documentation, see README.md and INSTALLATION.md

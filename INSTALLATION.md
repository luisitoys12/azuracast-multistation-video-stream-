# Installation Guide

This guide walks you through setting up the AzuraCast Multi-Station Video Stream Plugin.

## Prerequisites

Before you begin, ensure you have:

1. **AzuraCast installed and running**
   - Either Docker version or standalone installation
   - At least one radio station configured

2. **System Requirements**
   - Linux-based system (Ubuntu, Debian, or Alpine)
   - Sufficient CPU for video encoding (2+ cores recommended per stream)
   - At least 2GB RAM
   - Disk space for HLS segments (~500MB per station)

3. **Required Software**
   - FFmpeg (with libx264 and AAC support)
   - jq (JSON command-line processor)
   - curl (for API requests)
   - bash shell

## Installation Steps

### Step 1: Install Dependencies

#### On Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y ffmpeg jq curl
```

#### On Alpine Linux (Docker):
```bash
apk add --no-cache ffmpeg jq curl bash
```

#### Verify Installation:
```bash
ffmpeg -version
jq --version
```

### Step 2: Clone or Download This Repository

```bash
cd /var/azuracast
git clone https://github.com/luisitoys12/azuracast-multistation-video-stream-.git video-stream
cd video-stream
```

Or download and extract:
```bash
wget https://github.com/luisitoys12/azuracast-multistation-video-stream-/archive/main.zip
unzip main.zip
mv azuracast-multistation-video-stream--main video-stream
cd video-stream
```

### Step 3: Make Scripts Executable

```bash
chmod +x install.sh
chmod +x scripts/*.sh
```

### Step 4: Configure Your First Station

#### 4.1 Create Station Directory
```bash
mkdir -p stations/mystation
```

#### 4.2 Copy Configuration Template
```bash
cp templates/config.json.template stations/mystation/config.json
```

#### 4.3 Edit Configuration
```bash
nano stations/mystation/config.json
```

Update the following fields:

1. **Station Info:**
   ```json
   "station_id": "mystation",
   "station_name": "My Radio Station",
   ```

2. **AzuraCast API:**
   ```json
   "azuracast_nowplaying_url": "http://localhost/api/nowplaying/1",
   "azuracast_api_key": "YOUR_API_KEY_HERE",
   ```
   
   Get your API key from AzuraCast:
   - Go to Profile → API Keys
   - Create a new API key
   - Copy and paste it in the config

3. **Audio Stream:**
   ```json
   "stream_url": "http://localhost:8000/radio.mp3",
   ```
   
   Find your stream URL:
   - Go to your station in AzuraCast
   - Click "Public Pages"
   - Copy the direct stream URL

4. **Background Image:**
   ```json
   "background_image": "/full/path/to/background.jpg",
   ```
   
   Place your background image in the station folder and update the path.

### Step 5: Prepare Background Image

Create or download a background image (1920x1080 recommended):

```bash
# Example: Download a sample image
wget -O stations/mystation/background.jpg https://via.placeholder.com/1920x1080.jpg
```

Or use your own:
```bash
cp /path/to/your/image.jpg stations/mystation/background.jpg
```

### Step 6: Test Configuration

Validate your JSON:
```bash
jq . stations/mystation/config.json
```

If there are no errors, you're good to go!

### Step 7: Create Output Directory

```bash
mkdir -p output/mystation
```

Update the config to use this directory:
```json
"output_dir": "/full/path/to/output/mystation",
```

### Step 8: Start the Stream

#### Option A: Start All Stations
```bash
bash install.sh
```

#### Option B: Start Specific Station
```bash
bash scripts/start-station.sh mystation
```

### Step 9: Verify It's Running

```bash
bash scripts/status.sh
```

You should see:
```
Station: mystation
  Status: RUNNING (PID: 12345)
  HLS Playlist: /path/to/output/mystation/stream.m3u8
  Now Playing: Artist - Song Title
```

### Step 10: Access Your Stream

#### Test HLS Stream with VLC:
```bash
vlc http://localhost/output/mystation/stream.m3u8
```

#### Test with curl:
```bash
curl -I http://localhost/output/mystation/stream.m3u8
```

## Setting Up Multiple Stations

Repeat steps 4-7 for each additional station:

```bash
# Station 2
mkdir -p stations/station2 output/station2
cp templates/config.json.template stations/station2/config.json
nano stations/station2/config.json
# ... configure ...

# Station 3
mkdir -p stations/station3 output/station3
cp templates/config.json.template stations/station3/config.json
nano stations/station3/config.json
# ... configure ...
```

Then start all stations:
```bash
bash install.sh
```

## Docker Integration

If using AzuraCast Docker:

### Method 1: Volume Mount

1. Edit `docker-compose.override.yml`:
```yaml
version: '2.2'
services:
  web:
    volumes:
      - ./video-stream:/var/azuracast/video-stream
```

2. Restart the container:
```bash
docker-compose down
docker-compose up -d
```

3. Enter the container:
```bash
docker-compose exec --user=azuracast web bash
cd /var/azuracast/video-stream
bash install.sh
```

### Method 2: Copy into Container

```bash
docker cp ./video-stream azuracast_web:/var/azuracast/
docker-compose exec --user=azuracast web bash
cd /var/azuracast/video-stream
bash install.sh
```

## Enabling RTMP Outputs (YouTube, Facebook)

### YouTube Live

1. Go to https://studio.youtube.com
2. Click "Create" → "Go Live"
3. Select "Stream" option
4. Copy your "Stream key"
5. Update config.json:
```json
{
  "enabled": true,
  "name": "YouTube",
  "url": "rtmp://a.rtmp.youtube.com/live2/YOUR_STREAM_KEY_HERE",
  "video_bitrate": "2500k",
  "audio_bitrate": "128k"
}
```

### Facebook Live

1. Go to https://www.facebook.com/live/producer
2. Copy your "Stream Key"
3. Update config.json:
```json
{
  "enabled": true,
  "name": "Facebook",
  "url": "rtmps://live-api-s.facebook.com:443/rtmp/YOUR_STREAM_KEY_HERE",
  "video_bitrate": "2500k",
  "audio_bitrate": "128k"
}
```

### Twitch

1. Go to https://dashboard.twitch.tv/settings/stream
2. Copy your "Primary Stream Key"
3. Update config.json:
```json
{
  "enabled": true,
  "name": "Twitch",
  "url": "rtmp://live.twitch.tv/app/YOUR_STREAM_KEY_HERE",
  "video_bitrate": "2500k",
  "audio_bitrate": "128k"
}
```

## Automatic Startup on Boot

### Using systemd (Linux)

Create a service file:

```bash
sudo nano /etc/systemd/system/azuracast-video-stream.service
```

Add:
```ini
[Unit]
Description=AzuraCast Video Streaming Service
After=network.target

[Service]
Type=forking
User=azuracast
WorkingDirectory=/var/azuracast/video-stream
ExecStart=/var/azuracast/video-stream/install.sh
ExecStop=/var/azuracast/video-stream/scripts/stop-all.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable azuracast-video-stream
sudo systemctl start azuracast-video-stream
```

### Using cron (Alternative)

```bash
crontab -e
```

Add:
```
@reboot /var/azuracast/video-stream/install.sh
```

## Post-Installation

### Monitor Logs

```bash
tail -f stations/mystation/stream.log
```

### Check Resource Usage

```bash
top -p $(cat stations/mystation/pids/ffmpeg.pid)
```

### Optimize Performance

If streams are choppy or using too much CPU:

1. Reduce resolution to 720p:
   ```json
   "width": 1280,
   "height": 720,
   ```

2. Lower FPS to 24 or 25:
   ```json
   "fps": 25,
   ```

3. Reduce bitrate:
   ```json
   "bitrate": "2000k",
   ```

## Troubleshooting

See the main README.md for common issues and solutions.

## Next Steps

- Configure multiple stations
- Set up RTMP streaming to YouTube/Facebook
- Customize text overlay and positioning
- Add video backgrounds
- Set up monitoring and alerting

---

Congratulations! Your AzuraCast Multi-Station Video Stream Plugin is now installed and running. 🎉

#!/bin/bash

# Cursor Web Installation Script
# This script installs Cursor Web directly on the server (not in container)

set -e

echo "🚀 Installing Cursor Web on server..."

# Update system
echo "📦 Updating system packages..."
sudo apt-get update

# Install required packages
echo "📦 Installing required packages..."
sudo apt-get install -y --no-install-recommends \
    curl \
    fuse \
    python3.11-venv \
    libfuse2 \
    python3-xdg \
    libgtk-3-0 \
    libnotify4 \
    libatspi2.0-0 \
    libsecret-1-0 \
    libnss3 \
    desktop-file-utils \
    fonts-noto-color-emoji \
    git \
    ssh-askpass \
    xvfb \
    x11vnc \
    novnc \
    websockify

# Create directories
echo "📁 Creating directories..."
sudo mkdir -p /opt/cursor-web
sudo mkdir -p /opt/cursor-web/config
sudo mkdir -p /opt/cursor-web/cursor

# Download Cursor AppImage
echo "⬇️ Downloading Cursor AppImage..."
CURSOR_VERSION="1.2.0"
CURSOR_DOWNLOAD_URL="https://downloads.cursor.com/production/3c325775412a19b2f2147eed6b33f36371f025b0/linux/x64/Cursor-1.2.0-x86_64.AppImage"

cd /opt/cursor-web
sudo curl --location --output Cursor.AppImage "$CURSOR_DOWNLOAD_URL"
sudo chmod a+x Cursor.AppImage

# Create startup script
echo "📝 Creating startup script..."
sudo tee /opt/cursor-web/start_cursor.sh > /dev/null << 'EOF'
#!/bin/bash

# Start Xvfb
Xvfb :1 -screen 0 1920x1080x24 &
export DISPLAY=:1

# Start VNC server
x11vnc -display :1 -nopw -listen localhost -xkb -ncache 10 -ncache_cr -forever &

# Start noVNC
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &

# Start Cursor
cd /opt/cursor-web
./Cursor.AppImage --appimage-extract-and-run --no-sandbox --disable-gpu --no-xshm --disable-dev-shm-usage --disable-software-rasterizer
EOF

sudo chmod +x /opt/cursor-web/start_cursor.sh

# Create systemd service
echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/cursor-web.service > /dev/null << EOF
[Unit]
Description=Cursor Web Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/cursor-web
ExecStart=/opt/cursor-web/start_cursor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
echo "🚀 Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable cursor-web.service
sudo systemctl start cursor-web.service

echo "✅ Installation complete!"
echo "🌐 Cursor Web should be available at: http://YOUR_SERVER_IP:8080"
echo "📁 Cursor files are stored in: /opt/cursor-web/cursor"
echo "⚙️ Configuration files are in: /opt/cursor-web/config"
echo ""
echo "To check status: sudo systemctl status cursor-web.service"
echo "To restart: sudo systemctl restart cursor-web.service"
echo "To stop: sudo systemctl stop cursor-web.service"
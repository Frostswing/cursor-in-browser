#!/bin/bash

# Simple Cursor Web Runner
# This script runs Cursor Web directly on the server

set -e

echo "🚀 Starting Cursor Web..."

# Check if we're in a container
if [ -f /.dockerenv ]; then
    echo "⚠️  Warning: Running inside a container"
    echo "For full server access, run this script directly on the server"
fi

# Install basic requirements if not present
if ! command -v curl &> /dev/null; then
    echo "📦 Installing curl..."
    apt-get update && apt-get install -y curl
fi

# Create directories if they don't exist
mkdir -p /opt/cursor-web
mkdir -p /opt/cursor-web/config
mkdir -p /opt/cursor-web/cursor

cd /opt/cursor-web

# Download Cursor if not present
if [ ! -f "Cursor.AppImage" ]; then
    echo "⬇️ Downloading Cursor AppImage..."
    CURSOR_DOWNLOAD_URL="https://downloads.cursor.com/production/3c325775412a19b2f2147eed6b33f36371f025b0/linux/x64/Cursor-1.2.0-x86_64.AppImage"
    curl --location --output Cursor.AppImage "$CURSOR_DOWNLOAD_URL"
    chmod a+x Cursor.AppImage
fi

# Install VNC and noVNC if not present
if ! command -v x11vnc &> /dev/null; then
    echo "📦 Installing VNC server..."
    apt-get update && apt-get install -y x11vnc novnc websockify xvfb
fi

# Start Xvfb (virtual display)
echo "🖥️ Starting virtual display..."
Xvfb :1 -screen 0 1920x1080x24 &
export DISPLAY=:1

# Start VNC server
echo "🔗 Starting VNC server..."
x11vnc -display :1 -nopw -listen localhost -xkb -ncache 10 -ncache_cr -forever &

# Start noVNC (web interface)
echo "🌐 Starting noVNC web interface..."
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &

# Wait a moment for services to start
sleep 2

echo "✅ Cursor Web is starting..."
echo "🌐 Access at: http://YOUR_SERVER_IP:8080"
echo "📁 Files location: /opt/cursor-web/cursor"
echo ""
echo "Press Ctrl+C to stop"

# Start Cursor
echo "🚀 Launching Cursor..."
./Cursor.AppImage --appimage-extract-and-run --no-sandbox --disable-gpu --no-xshm --disable-dev-shm-usage --disable-software-rasterizer
#!/bin/bash

# Multi-Instance Cursor Web Manager
# מנהל מופעים מרובים של Cursor Web ישירות על השרת

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
DEFAULT_PORT=8080
DEFAULT_USER="cursor"
DEFAULT_PASSWORD="cursor123"
DEFAULT_WORKSPACE="/workspace"
INSTANCES_DIR="/opt/cursor-instances"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check if port is available
check_port() {
    local port=$1
    if netstat -tlnp 2>/dev/null | grep -q ":$port "; then
        return 1
    fi
    return 0
}

# Function to find available port
find_available_port() {
    local start_port=$1
    local port=$start_port
    
    while ! check_port $port; do
        port=$((port + 1))
        if [ $port -gt 65535 ]; then
            print_error "No available ports found"
            exit 1
        fi
    done
    echo $port
}

# Function to create cursor instance
create_cursor_instance() {
    local port=$1
    local user=${2:-$DEFAULT_USER}
    local password=${3:-$DEFAULT_PASSWORD}
    local workspace=${4:-$DEFAULT_WORKSPACE}
    local instance_name="cursor-$port"
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    print_header "Creating Cursor instance on port $port"
    
    # Create directories
    sudo mkdir -p "$instance_dir"
    sudo mkdir -p "$instance_dir/config"
    sudo mkdir -p "$instance_dir/cursor"
    
    # Create startup script for this instance
    cat > "$instance_dir/start_cursor.sh" << EOF
#!/bin/bash

# Cursor Web Instance - Port $port
# Instance: $instance_name

set -e

# Set display for this instance
export DISPLAY=:$((port - 8000 + 1))

# Start Xvfb for this instance
Xvfb \$DISPLAY -screen 0 1920x1080x24 &
sleep 2

# Start VNC server for this instance
x11vnc -display \$DISPLAY -nopw -listen localhost -xkb -ncache 10 -ncache_cr -forever -rfbport $((port + 1000)) &

# Start noVNC for this instance
websockify --web=/usr/share/novnc/ $port localhost:$((port + 1000)) &

# Wait for services to start
sleep 3

# Start Cursor
cd "$instance_dir"
./Cursor.AppImage --appimage-extract-and-run --no-sandbox --disable-gpu --no-xshm --disable-dev-shm-usage --disable-software-rasterizer
EOF
    
    chmod +x "$instance_dir/start_cursor.sh"
    
    # Download Cursor AppImage if not exists
    if [ ! -f "$instance_dir/Cursor.AppImage" ]; then
        print_status "Downloading Cursor AppImage..."
        cd "$instance_dir"
        CURSOR_DOWNLOAD_URL="https://downloads.cursor.com/production/3c325775412a19b2f2147eed6b33f36371f025b0/linux/x64/Cursor-1.2.0-x86_64.AppImage"
        curl --location --output Cursor.AppImage "$CURSOR_DOWNLOAD_URL"
        chmod a+x Cursor.AppImage
    fi
    
    # Create systemd service
    cat > "/etc/systemd/system/$instance_name.service" << EOF
[Unit]
Description=Cursor Web Instance on Port $port
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$instance_dir
ExecStart=$instance_dir/start_cursor.sh
Restart=always
RestartSec=10
Environment=DISPLAY=:$((port - 8000 + 1))

[Install]
WantedBy=multi-user.target
EOF
    
    # Create config file
    cat > "$instance_dir/instance.conf" << EOF
# Cursor Web Instance Configuration
INSTANCE_NAME=$instance_name
PORT=$port
USER=$user
PASSWORD=$password
WORKSPACE=$workspace
VNC_PORT=$((port + 1000))
DISPLAY=:$((port - 8000 + 1))
CREATED=$(date)
EOF
    
    # Enable and start service
    sudo systemctl daemon-reload
    sudo systemctl enable "$instance_name.service"
    sudo systemctl start "$instance_name.service"
    
    print_status "Instance created successfully!"
    print_status "Access URL: http://YOUR_SERVER_IP:$port"
    print_status "Username: $user"
    print_status "Password: $password"
    print_status "Workspace: $workspace"
    print_status "Instance directory: $instance_dir"
    echo ""
}

# Function to list instances
list_instances() {
    print_header "Cursor Web Instances"
    
    if [ ! -d "$INSTANCES_DIR" ]; then
        print_warning "No instances directory found"
        return
    fi
    
    local instances=$(ls "$INSTANCES_DIR" 2>/dev/null | grep "^cursor-" || true)
    
    if [ -z "$instances" ]; then
        print_warning "No Cursor instances found"
        return
    fi
    
    echo "Instances:"
    for instance in $instances; do
        local port=$(echo $instance | sed 's/cursor-//')
        local config_file="$INSTANCES_DIR/$instance/instance.conf"
        local status="unknown"
        
        if [ -f "$config_file" ]; then
            source "$config_file"
            if sudo systemctl is-active "$instance.service" >/dev/null 2>&1; then
                status="active"
                echo -e "  ${GREEN}✓${NC} $instance (Port: $port) - http://YOUR_SERVER_IP:$port"
            else
                status="inactive"
                echo -e "  ${RED}✗${NC} $instance (Port: $port) - $status"
            fi
        else
            echo -e "  ${YELLOW}?${NC} $instance (Port: $port) - config missing"
        fi
    done
    echo ""
}

# Function to stop instance
stop_instance() {
    local port=$1
    local instance_name="cursor-$port"
    
    print_header "Stopping Cursor instance on port $port"
    
    if sudo systemctl is-active "$instance_name.service" >/dev/null 2>&1; then
        sudo systemctl stop "$instance_name.service"
        print_status "Instance stopped successfully"
    else
        print_warning "Instance is not running"
    fi
}

# Function to start instance
start_instance() {
    local port=$1
    local instance_name="cursor-$port"
    
    print_header "Starting Cursor instance on port $port"
    
    if [ -f "/etc/systemd/system/$instance_name.service" ]; then
        sudo systemctl start "$instance_name.service"
        print_status "Instance started successfully"
    else
        print_error "Instance not found. Create it first."
    fi
}

# Function to remove instance
remove_instance() {
    local port=$1
    local instance_name="cursor-$port"
    
    print_header "Removing Cursor instance on port $port"
    
    # Stop and disable service
    sudo systemctl stop "$instance_name.service" 2>/dev/null || true
    sudo systemctl disable "$instance_name.service" 2>/dev/null || true
    sudo systemctl daemon-reload
    
    # Remove service file
    sudo rm -f "/etc/systemd/system/$instance_name.service"
    
    # Remove instance directory
    sudo rm -rf "$INSTANCES_DIR/$instance_name"
    
    print_status "Instance removed successfully"
}

# Function to show instance logs
show_logs() {
    local port=$1
    local instance_name="cursor-$port"
    
    print_header "Logs for Cursor instance on port $port"
    sudo journalctl -u "$instance_name.service" -f
}

# Function to install dependencies
install_dependencies() {
    print_header "Installing Dependencies"
    
    # Update system
    sudo apt-get update
    
    # Install required packages
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
        websockify \
        net-tools
    
    # Create instances directory
    sudo mkdir -p "$INSTANCES_DIR"
    
    print_status "Dependencies installed successfully"
}

# Function to show usage
show_usage() {
    cat << EOF
Multi-Instance Cursor Web Manager - מנהל מופעי Cursor Web מרובים

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  install                                    - Install dependencies
  create [PORT] [USER] [PASSWORD] [WORKSPACE] - Create new instance
  list                                      - List all instances
  start [PORT]                             - Start instance
  stop [PORT]                              - Stop instance
  restart [PORT]                           - Restart instance
  remove [PORT]                            - Remove instance
  logs [PORT]                              - Show instance logs
  status [PORT]                            - Show instance status

Examples:
  $0 install                               # Install dependencies first
  $0 create 8080                          # Create instance on port 8080
  $0 create 8081 user1 pass1 /home/user1  # Create with custom settings
  $0 list                                 # List all instances
  $0 stop 8080                            # Stop instance on port 8080
  $0 logs 8080                            # Show logs for port 8080
  $0 remove 8080                          # Remove instance on port 8080

Environment Variables:
  DEFAULT_PORT=$DEFAULT_PORT
  DEFAULT_USER=$DEFAULT_USER
  DEFAULT_PASSWORD=$DEFAULT_PASSWORD
  DEFAULT_WORKSPACE=$DEFAULT_WORKSPACE
  INSTANCES_DIR=$INSTANCES_DIR
EOF
}

# Main script logic
case "${1:-}" in
    "install")
        install_dependencies
        ;;
    "create")
        port=${2:-$(find_available_port $DEFAULT_PORT)}
        user=${3:-$DEFAULT_USER}
        password=${4:-$DEFAULT_PASSWORD}
        workspace=${5:-$DEFAULT_WORKSPACE}
        
        if ! check_port $port; then
            print_error "Port $port is already in use"
            exit 1
        fi
        
        create_cursor_instance $port $user $password $workspace
        ;;
    "list")
        list_instances
        ;;
    "start")
        if [ -z "$2" ]; then
            print_error "Port number required"
            exit 1
        fi
        start_instance $2
        ;;
    "stop")
        if [ -z "$2" ]; then
            print_error "Port number required"
            exit 1
        fi
        stop_instance $2
        ;;
    "restart")
        if [ -z "$2" ]; then
            print_error "Port number required"
            exit 1
        fi
        stop_instance $2
        sleep 2
        start_instance $2
        ;;
    "remove")
        if [ -z "$2" ]; then
            print_error "Port number required"
            exit 1
        fi
        remove_instance $2
        ;;
    "logs")
        if [ -z "$2" ]; then
            print_error "Port number required"
            exit 1
        fi
        show_logs $2
        ;;
    "status")
        if [ -z "$2" ]; then
            print_error "Port number required"
            exit 1
        fi
        instance_name="cursor-$2"
        sudo systemctl status "$instance_name.service"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
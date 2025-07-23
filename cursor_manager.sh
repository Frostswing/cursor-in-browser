#!/bin/bash

# Cursor Web Manager
# מנהל להרצת מספר מופעים של Cursor Web על פורטים שונים

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
    
    print_header "Creating Cursor instance on port $port"
    
    # Create directories
    local instance_dir="/opt/cursor-instances/$instance_name"
    sudo mkdir -p "$instance_dir"
    sudo mkdir -p "$instance_dir/config"
    sudo mkdir -p "$instance_dir/workspace"
    
    # Create docker-compose file
    cat > "$instance_dir/docker-compose.yml" << EOF
version: '3.8'

services:
  cursor-web:
    image: arfodublo/cursor-in-browser:1.2.0
    container_name: $instance_name
    ports:
      - "$port:8080"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Jerusalem
      - CUSTOM_USER=$user
      - PASSWORD=$password
      - TITLE="Cursor Web - Port $port"
      - FM_HOME=/cursor
    volumes:
      - $workspace:/cursor
      - $instance_dir/config:/config
    restart: unless-stopped
    networks:
      - cursor-network

networks:
  cursor-network:
    driver: bridge
EOF
    
    # Create systemd service
    cat > "/etc/systemd/system/$instance_name.service" << EOF
[Unit]
Description=Cursor Web Instance on Port $port
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$instance_dir
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
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
    echo ""
}

# Function to list instances
list_instances() {
    print_header "Cursor Web Instances"
    
    local instances=$(sudo systemctl list-units --type=service --state=active | grep "cursor-" | awk '{print $1}')
    
    if [ -z "$instances" ]; then
        print_warning "No active Cursor instances found"
        return
    fi
    
    echo "Active instances:"
    for instance in $instances; do
        local port=$(echo $instance | sed 's/cursor-//')
        local status=$(sudo systemctl is-active $instance)
        local url="http://YOUR_SERVER_IP:$port"
        
        if [ "$status" = "active" ]; then
            echo -e "  ${GREEN}✓${NC} $instance (Port: $port) - $url"
        else
            echo -e "  ${RED}✗${NC} $instance (Port: $port) - $status"
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
    sudo rm -rf "/opt/cursor-instances/$instance_name"
    
    # Remove container if exists
    sudo docker rm -f "$instance_name" 2>/dev/null || true
    
    print_status "Instance removed successfully"
}

# Function to show usage
show_usage() {
    cat << EOF
Cursor Web Manager - מנהל מופעי Cursor Web

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  create [PORT] [USER] [PASSWORD] [WORKSPACE]  - Create new instance
  list                                        - List all instances
  start [PORT]                               - Start instance
  stop [PORT]                                - Stop instance
  restart [PORT]                             - Restart instance
  remove [PORT]                              - Remove instance
  status [PORT]                              - Show instance status

Examples:
  $0 create 8080                            # Create instance on port 8080
  $0 create 8081 user1 pass1 /home/user1    # Create with custom settings
  $0 list                                   # List all instances
  $0 stop 8080                              # Stop instance on port 8080
  $0 remove 8080                            # Remove instance on port 8080

Environment Variables:
  DEFAULT_PORT=$DEFAULT_PORT
  DEFAULT_USER=$DEFAULT_USER
  DEFAULT_PASSWORD=$DEFAULT_PASSWORD
  DEFAULT_WORKSPACE=$DEFAULT_WORKSPACE
EOF
}

# Main script logic
case "${1:-}" in
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
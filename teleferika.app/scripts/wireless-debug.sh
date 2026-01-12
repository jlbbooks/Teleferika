#!/bin/bash

# Wireless Debugging Setup Script for Android Devices
# This script helps you connect your Android device wirelessly for debugging in VSCode/Cursor

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Android Wireless Debugging Setup ===${NC}\n"

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo -e "${RED}Error: ADB (Android Debug Bridge) is not found in PATH${NC}"
    echo "Please install Android SDK Platform Tools:"
    echo "  - Linux: sudo apt-get install android-tools-adb"
    echo "  - macOS: brew install android-platform-tools"
    echo "  - Or download from: https://developer.android.com/studio/releases/platform-tools"
    exit 1
fi

echo -e "${GREEN}✓ ADB found${NC}\n"

# Function to list connected devices
list_devices() {
    echo -e "${BLUE}Currently connected devices:${NC}"
    adb devices -l
    echo ""
}

# Function to connect wirelessly
connect_wireless() {
    echo -e "${YELLOW}To enable wireless debugging on your Android device:${NC}"
    echo "1. Open Settings > Developer Options"
    echo "2. Enable 'Wireless debugging' (Android 11+)"
    echo "3. Tap 'Wireless debugging' to open options"
    echo "4. Tap 'Pair device with pairing code'"
    echo ""
    
    read -p "Enter the IP address and port (e.g., 192.168.1.100:12345): " ip_port
    
    if [ -z "$ip_port" ]; then
        echo -e "${RED}Error: IP address and port are required${NC}"
        exit 1
    fi
    
    # Extract IP and port
    IP=$(echo $ip_port | cut -d: -f1)
    PORT=$(echo $ip_port | cut -d: -f2)
    
    if [ -z "$IP" ] || [ -z "$PORT" ]; then
        echo -e "${RED}Error: Invalid format. Use IP:PORT (e.g., 192.168.1.100:12345)${NC}"
        exit 1
    fi
    
    echo -e "\n${BLUE}Pairing device...${NC}"
    adb pair $IP:$PORT
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}✓ Pairing successful!${NC}"
        echo -e "\n${YELLOW}Now connecting to device...${NC}"
        
        # Get the connection port (usually different from pairing port)
        echo -e "\n${YELLOW}Please check your device for the connection port:${NC}"
        echo "1. In Wireless debugging settings, note the 'IP address & port'"
        echo "2. It should show something like: 192.168.1.100:XXXXX"
        echo ""
        
        read -p "Enter the connection IP address and port: " connect_ip_port
        
        if [ -z "$connect_ip_port" ]; then
            echo -e "${RED}Error: Connection IP address and port are required${NC}"
            exit 1
        fi
        
        CONNECT_IP=$(echo $connect_ip_port | cut -d: -f1)
        CONNECT_PORT=$(echo $connect_ip_port | cut -d: -f2)
        
        adb connect $CONNECT_IP:$CONNECT_PORT
        
        if [ $? -eq 0 ]; then
            echo -e "\n${GREEN}✓ Successfully connected wirelessly!${NC}\n"
            list_devices
            echo -e "${GREEN}Your device should now appear in VSCode/Cursor's device list${NC}"
        else
            echo -e "${RED}Error: Failed to connect${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: Pairing failed${NC}"
        exit 1
    fi
}

# Function to disconnect wireless devices
disconnect_wireless() {
    echo -e "${BLUE}Disconnecting wireless devices...${NC}"
    adb disconnect
    echo -e "${GREEN}✓ Disconnected${NC}\n"
    list_devices
}

# Function to show current status
show_status() {
    echo -e "${BLUE}Current ADB Status:${NC}\n"
    list_devices
    
    # Check if any wireless devices are connected
    WIRELESS_DEVICES=$(adb devices | grep -E "^\S+\s+device$" | grep -v "emulator" | wc -l)
    if [ $WIRELESS_DEVICES -gt 0 ]; then
        echo -e "${GREEN}Wireless debugging is active${NC}"
    else
        echo -e "${YELLOW}No wireless devices connected${NC}"
    fi
}

# Main menu
case "${1:-}" in
    connect)
        connect_wireless
        ;;
    disconnect)
        disconnect_wireless
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {connect|disconnect|status}"
        echo ""
        echo "Commands:"
        echo "  connect    - Pair and connect a device wirelessly"
        echo "  disconnect - Disconnect all wireless devices"
        echo "  status     - Show current connection status"
        echo ""
        echo "Example:"
        echo "  $0 connect"
        exit 1
        ;;
esac

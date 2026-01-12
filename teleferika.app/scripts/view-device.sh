#!/bin/bash

# Android Device Screen Mirroring Script
# Uses scrcpy to mirror and control Android device screen locally
# Works with both USB and wireless ADB connections

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Android Device Screen Mirroring ===${NC}\n"

# Check if scrcpy is available
if ! command -v scrcpy &> /dev/null; then
    echo -e "${RED}Error: scrcpy is not installed${NC}"
    echo ""
    echo "Install scrcpy:"
    echo "  - Linux:"
    echo "      sudo apt-get install scrcpy"
    echo "      # or for Arch Linux:"
    echo "      sudo pacman -S scrcpy"
    echo ""
    echo "  - macOS:"
    echo "      brew install scrcpy"
    echo ""
    echo "  - Windows:"
    echo "      Download from: https://github.com/Genymobile/scrcpy/releases"
    echo ""
    echo "  - Or build from source:"
    echo "      https://github.com/Genymobile/scrcpy"
    exit 1
fi

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo -e "${RED}Error: ADB (Android Debug Bridge) is not found in PATH${NC}"
    exit 1
fi

# Check for connected devices
DEVICES=$(adb devices | grep -v "List" | grep "device$" | awk '{print $1}' | grep -v "^$")

if [ -z "$DEVICES" ]; then
    echo -e "${YELLOW}No devices connected via ADB${NC}"
    echo ""
    echo "Please connect a device first:"
    echo "  - USB: Connect via USB cable and enable USB debugging"
    echo "  - Wireless: Run './scripts/wireless-debug.sh connect'"
    exit 1
fi

# Count devices
DEVICE_COUNT=$(echo "$DEVICES" | wc -l)

if [ $DEVICE_COUNT -eq 1 ]; then
    DEVICE=$(echo "$DEVICES" | head -n1)
    echo -e "${GREEN}Found device: $DEVICE${NC}\n"
else
    echo -e "${BLUE}Multiple devices found:${NC}"
    echo "$DEVICES" | nl
    echo ""
    read -p "Enter device number (1-$DEVICE_COUNT): " DEVICE_NUM
    
    if [ -z "$DEVICE_NUM" ] || [ "$DEVICE_NUM" -lt 1 ] || [ "$DEVICE_NUM" -gt $DEVICE_COUNT ]; then
        echo -e "${RED}Invalid device number${NC}"
        exit 1
    fi
    
    DEVICE=$(echo "$DEVICES" | sed -n "${DEVICE_NUM}p")
    echo -e "${GREEN}Selected device: $DEVICE${NC}\n"
fi

# Parse command line arguments
FULLSCREEN=false
STAY_AWAKE=false
BITRATE=""
MAX_SIZE=""
RECORD=""
NO_AUDIO=false
NO_CONTROL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--fullscreen)
            FULLSCREEN=true
            shift
            ;;
        -w|--stay-awake)
            STAY_AWAKE=true
            shift
            ;;
        -b|--bitrate)
            BITRATE="$2"
            shift 2
            ;;
        -m|--max-size)
            MAX_SIZE="$2"
            shift 2
            ;;
        -r|--record)
            RECORD="$2"
            shift 2
            ;;
        -n|--no-audio)
            NO_AUDIO=true
            shift
            ;;
        -c|--no-control)
            NO_CONTROL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --fullscreen      Start in fullscreen mode"
            echo "  -w, --stay-awake      Keep device awake while mirroring"
            echo "  -b, --bitrate RATE    Set video bitrate (e.g., 8M for 8 Mbps)"
            echo "  -m, --max-size SIZE   Limit resolution (e.g., 1920)"
            echo "  -r, --record FILE     Record screen to file (e.g., recording.mp4)"
            echo "  -n, --no-audio        Disable audio mirroring"
            echo "  -c, --no-control      Disable device control (view only)"
            echo "  -h, --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Basic mirroring"
            echo "  $0 --fullscreen                      # Fullscreen mode"
            echo "  $0 --bitrate 16M --max-size 1920     # High quality, limited size"
            echo "  $0 --record screen.mp4               # Record screen"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Build scrcpy command
SCRCPY_CMD="scrcpy -s $DEVICE"

if [ "$FULLSCREEN" = true ]; then
    SCRCPY_CMD="$SCRCPY_CMD --fullscreen"
fi

if [ "$STAY_AWAKE" = true ]; then
    SCRCPY_CMD="$SCRCPY_CMD --stay-awake"
fi

if [ -n "$BITRATE" ]; then
    SCRCPY_CMD="$SCRCPY_CMD --bit-rate $BITRATE"
fi

if [ -n "$MAX_SIZE" ]; then
    SCRCPY_CMD="$SCRCPY_CMD --max-size $MAX_SIZE"
fi

if [ -n "$RECORD" ]; then
    SCRCPY_CMD="$SCRCPY_CMD --record $RECORD"
    echo -e "${BLUE}Recording to: $RECORD${NC}"
fi

if [ "$NO_AUDIO" = true ]; then
    SCRCPY_CMD="$SCRCPY_CMD --no-audio"
fi

if [ "$NO_CONTROL" = true ]; then
    SCRCPY_CMD="$SCRCPY_CMD --no-control"
fi

echo -e "${BLUE}Starting screen mirroring...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}\n"

# Execute scrcpy
eval $SCRCPY_CMD

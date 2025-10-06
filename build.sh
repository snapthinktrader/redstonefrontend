#!/bin/bash

# RedStone Flutter App Build Script
# Usage: ./build.sh [dev|prod|custom]

set -e

echo "🚀 RedStone Flutter App Builder"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default URLs
DEV_URL="http://localhost:3000/api"
PROD_URL="https://redstonebackend-qzyfnbktn-snaps-projects-656f28bb.vercel.app/api"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to build APK
build_apk() {
    local api_url="$1"
    local build_type="$2"
    
    print_status "Building $build_type APK with API URL: $api_url"
    
    # Clean previous builds
    print_status "Cleaning previous builds..."
    flutter clean
    flutter pub get
    
    # Build APK
    print_status "Building APK..."
    flutter build apk \
        --dart-define=API_BASE_URL="$api_url" \
        --target-platform android-arm64 \
        --split-per-abi \
        --release
    
    # Find and display APK location
    APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        print_success "APK built successfully!"
        print_success "Location: $APK_PATH"
        print_success "Size: $APK_SIZE"
        
        # Create renamed copy with timestamp
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        RENAMED_APK="build/redstone_${build_type}_${TIMESTAMP}.apk"
        cp "$APK_PATH" "$RENAMED_APK"
        print_success "Copy created: $RENAMED_APK"
    else
        print_error "APK build failed!"
        exit 1
    fi
}

# Function to install APK to connected device
install_apk() {
    print_status "Installing APK to connected device..."
    APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
    
    if [ -f "$APK_PATH" ]; then
        if adb devices | grep -q "device$"; then
            adb install -r "$APK_PATH"
            print_success "APK installed on device!"
        else
            print_warning "No Android device connected. Connect device and enable USB debugging."
        fi
    else
        print_error "APK not found. Build first."
    fi
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the Flutter project root directory"
    exit 1
fi

# Parse command line arguments
case "${1:-prod}" in
    "dev" | "development")
        print_status "Building DEVELOPMENT version"
        build_apk "$DEV_URL" "dev"
        ;;
    "prod" | "production")
        print_status "Building PRODUCTION version"
        build_apk "$PROD_URL" "prod"
        ;;
    "custom")
        if [ -z "$2" ]; then
            print_error "Custom URL required. Usage: ./build.sh custom https://your-backend.com/api"
            exit 1
        fi
        print_status "Building CUSTOM version with URL: $2"
        build_apk "$2" "custom"
        ;;
    "install")
        install_apk
        exit 0
        ;;
    "help" | "-h" | "--help")
        echo ""
        echo "Usage: $0 [COMMAND] [OPTIONS]"
        echo ""
        echo "Commands:"
        echo "  dev          Build development APK (localhost backend)"
        echo "  prod         Build production APK (Vercel backend) [default]"
        echo "  custom URL   Build with custom backend URL"
        echo "  install      Install last built APK to connected device"
        echo "  help         Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 prod                                    # Build production APK"
        echo "  $0 dev                                     # Build development APK"
        echo "  $0 custom https://api.example.com/api     # Build with custom URL"
        echo "  $0 install                                # Install APK to device"
        echo ""
        exit 0
        ;;
    *)
        print_error "Unknown command: $1"
        print_status "Use '$0 help' for usage information"
        exit 1
        ;;
esac

# Ask if user wants to install
echo ""
read -p "Install APK to connected device? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    install_apk
fi

print_success "Build complete! 🎉"
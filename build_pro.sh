#!/bin/bash

# RedStone Professional Build Script
# Solves the "backend URL changes every deployment" problem

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 RedStone Professional Builder${NC}"
echo "================================="

# Get latest backend URL from Vercel
get_latest_backend_url() {
    echo -e "${BLUE}📡 Getting latest backend URL...${NC}"
    
    # Get latest deployment URL
    cd ../backend
    LATEST_URL=$(vercel ls --format json | jq -r '.[0].url' 2>/dev/null || echo "")
    
    if [ -n "$LATEST_URL" ] && [ "$LATEST_URL" != "null" ]; then
        BACKEND_URL="https://$LATEST_URL/api"
        echo -e "${GREEN}✅ Latest backend URL: $BACKEND_URL${NC}"
    else
        # Fallback to current known URL
        # Default URLs - NOW USING STABLE DOMAIN!
DEV_URL="http://localhost:3000/api"
PROD_URL="https://red-stone-backend.vercel.app/api"
        echo -e "${YELLOW}⚠️  Using fallback URL: $BACKEND_URL${NC}"
    fi
    
    cd ../frontend
}

# Build APK with latest URL
build_production_apk() {
    echo -e "${BLUE}🔨 Building production APK...${NC}"
    
    # Clean and prepare
    flutter clean
    flutter pub get
    
    # Build with latest backend URL
    flutter build apk \
        --dart-define=API_BASE_URL="$BACKEND_URL" \
        --target-platform android-arm64 \
        --split-per-abi \
        --release
    
    # Check if build succeeded
    APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        
        # Create versioned copy
        VERSIONED_APK="build/redstone_prod_${TIMESTAMP}.apk"
        cp "$APK_PATH" "$VERSIONED_APK"
        
        echo -e "${GREEN}✅ APK built successfully!${NC}"
        echo -e "   📦 Size: $APK_SIZE"
        echo -e "   📱 Location: $APK_PATH"
        echo -e "   💾 Backup: $VERSIONED_APK"
        echo -e "   🌐 Backend: $BACKEND_URL"
        
        return 0
    else
        echo -e "${RED}❌ APK build failed!${NC}"
        return 1
    fi
}

# Install APK to device
install_to_device() {
    echo -e "${BLUE}📲 Installing to device...${NC}"
    
    APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
    
    if [ ! -f "$APK_PATH" ]; then
        echo -e "${RED}❌ APK not found. Build first.${NC}"
        return 1
    fi
    
    # Check for connected devices
    DEVICES=$(adb devices | grep -c "device$" || echo "0")
    
    if [ "$DEVICES" -eq "0" ]; then
        echo -e "${YELLOW}⚠️  No Android devices connected${NC}"
        echo "   Connect device and enable USB debugging"
        return 1
    fi
    
    # Install APK
    echo -e "${BLUE}Installing APK...${NC}"
    if adb install -r "$APK_PATH"; then
        echo -e "${GREEN}✅ APK installed successfully!${NC}"
        return 0
    else
        echo -e "${RED}❌ Installation failed${NC}"
        return 1
    fi
}

# Update backend and rebuild
update_and_rebuild() {
    echo -e "${BLUE}🔄 Professional Update Process${NC}"
    echo "1. Getting latest backend URL..."
    get_latest_backend_url
    
    echo "2. Building production APK..."
    if build_production_apk; then
        echo "3. Installation?"
        read -p "Install to connected device? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_to_device
        fi
    fi
}

# Main execution
case "${1:-auto}" in
    "auto"|"")
        echo -e "${BLUE}🤖 Auto mode: Get latest URL and build${NC}"
        update_and_rebuild
        ;;
    "install")
        install_to_device
        ;;
    "url")
        get_latest_backend_url
        echo "Backend URL: $BACKEND_URL"
        ;;
    "build")
        if [ -n "$2" ]; then
            BACKEND_URL="$2"
            echo -e "${BLUE}🔧 Building with custom URL: $BACKEND_URL${NC}"
        else
            get_latest_backend_url
        fi
        build_production_apk
        ;;
    "help"|"-h"|"--help")
        echo "RedStone Professional Builder"
        echo ""
        echo "Commands:"
        echo "  auto     Get latest backend URL and build APK (default)"
        echo "  build    Build APK with latest/custom URL"
        echo "  install  Install last built APK to device"
        echo "  url      Show current backend URL"
        echo "  help     Show this help"
        echo ""
        echo "Examples:"
        echo "  ./build_pro.sh                              # Auto build with latest URL"
        echo "  ./build_pro.sh build                        # Build with latest URL"
        echo "  ./build_pro.sh build https://custom.com/api # Build with custom URL"
        echo "  ./build_pro.sh install                      # Install to device"
        echo ""
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo "Use './build_pro.sh help' for usage"
        exit 1
        ;;
esac

echo -e "${GREEN}🎉 Professional build complete!${NC}"
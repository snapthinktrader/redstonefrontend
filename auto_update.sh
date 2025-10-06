#!/bin/bash

# RedStone Auto-Update Script
# Automatically updates backend URL in Flutter config when Vercel deploys

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CONFIG_FILE="lib/config/config.dart"
BACKEND_DIR="../backend"

echo -e "${BLUE}🔄 RedStone Auto-Updater${NC}"
echo "=========================="

# Function to get latest Vercel deployment URL
get_latest_vercel_url() {
    echo -e "${BLUE}📡 Fetching latest deployment...${NC}"
    
    cd "$BACKEND_DIR"
    
    # Get latest deployment URL using Vercel CLI
    LATEST_DEPLOYMENT=$(vercel ls --format json 2>/dev/null | jq -r '.[0].url' 2>/dev/null || echo "")
    
    if [ -n "$LATEST_DEPLOYMENT" ] && [ "$LATEST_DEPLOYMENT" != "null" ] && [ "$LATEST_DEPLOYMENT" != "" ]; then
        NEW_URL="https://$LATEST_DEPLOYMENT/api"
        echo -e "${GREEN}✅ Latest deployment: $NEW_URL${NC}"
        cd - > /dev/null
        return 0
    else
        echo -e "${RED}❌ Could not fetch latest deployment${NC}"
        cd - > /dev/null
        return 1
    fi
}

# Function to get current URL from config
get_current_url() {
    if [ -f "$CONFIG_FILE" ]; then
        CURRENT_URL=$(grep -o 'defaultValue: [^,]*' "$CONFIG_FILE" | sed "s/defaultValue: '//g" | sed "s/',//g" | tr -d "'\"")
        echo "$CURRENT_URL"
    else
        echo ""
    fi
}

# Function to update config file
update_config() {
    local new_url="$1"
    
    echo -e "${BLUE}📝 Updating config file...${NC}"
    
    # Create backup
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Update the config file
    sed -i.tmp "s|defaultValue: '[^']*'|defaultValue: '$new_url'|g" "$CONFIG_FILE"
    rm "${CONFIG_FILE}.tmp" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Config updated to: $new_url${NC}"
}

# Function to verify update
verify_update() {
    local expected_url="$1"
    local actual_url=$(get_current_url)
    
    if [ "$actual_url" = "$expected_url" ]; then
        echo -e "${GREEN}✅ Update verified successfully${NC}"
        return 0
    else
        echo -e "${RED}❌ Update verification failed${NC}"
        echo "Expected: $expected_url"
        echo "Actual: $actual_url"
        return 1
    fi
}

# Main execution
case "${1:-check}" in
    "check")
        echo -e "${BLUE}🔍 Checking for updates...${NC}"
        
        CURRENT_URL=$(get_current_url)
        echo "Current URL: $CURRENT_URL"
        
        if get_latest_vercel_url; then
            if [ "$CURRENT_URL" != "$NEW_URL" ]; then
                echo -e "${YELLOW}🆕 New deployment detected!${NC}"
                echo "Current: $CURRENT_URL"
                echo "Latest:  $NEW_URL"
                
                read -p "Update config? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    update_config "$NEW_URL"
                    verify_update "$NEW_URL"
                fi
            else
                echo -e "${GREEN}✅ Config is up to date${NC}"
            fi
        fi
        ;;
    "update")
        echo -e "${BLUE}🔄 Force updating...${NC}"
        
        if get_latest_vercel_url; then
            update_config "$NEW_URL"
            verify_update "$NEW_URL"
        else
            echo -e "${RED}❌ Could not get latest URL${NC}"
            exit 1
        fi
        ;;
    "auto")
        echo -e "${BLUE}🤖 Auto mode (silent update)${NC}"
        
        if get_latest_vercel_url; then
            CURRENT_URL=$(get_current_url)
            if [ "$CURRENT_URL" != "$NEW_URL" ]; then
                update_config "$NEW_URL"
                verify_update "$NEW_URL"
                echo -e "${GREEN}🎉 Auto-updated to latest deployment${NC}"
            fi
        fi
        ;;
    "status")
        echo -e "${BLUE}📊 Current status:${NC}"
        echo "Config file: $CONFIG_FILE"
        echo "Current URL: $(get_current_url)"
        
        if get_latest_vercel_url; then
            echo "Latest URL:  $NEW_URL"
            
            if [ "$(get_current_url)" = "$NEW_URL" ]; then
                echo -e "${GREEN}Status: ✅ Up to date${NC}"
            else
                echo -e "${YELLOW}Status: 🆕 Update available${NC}"
            fi
        fi
        ;;
    "help"|"-h"|"--help")
        echo "RedStone Auto-Updater"
        echo ""
        echo "Commands:"
        echo "  check    Check for updates and prompt (default)"
        echo "  update   Force update to latest deployment"
        echo "  auto     Silent auto-update if needed"
        echo "  status   Show current status"
        echo "  help     Show this help"
        echo ""
        echo "Examples:"
        echo "  ./auto_update.sh            # Check and prompt for update"
        echo "  ./auto_update.sh update     # Force update"
        echo "  ./auto_update.sh auto       # Silent auto-update"
        echo ""
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo "Use './auto_update.sh help' for usage"
        exit 1
        ;;
esac
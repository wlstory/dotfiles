#!/usr/bin/env zsh

xcode-select --install

echo "Complete the installation of Xcode Command Line Tools before proceeding."
echo "Press enter to continue..."
read

# Set scroll as natural vs traditional
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true && killall Finder

# THINGS TO DO:
# - Turn off password saving and auto-fill in browsers (Chrome, Safari, Brave, DuckDuckGo)
# - Set HotCorners
# - Set-up the Dock app order and icons on the Dock to include Applications
# - Set Dock to Hide and Show with animation
# - Check for OS Updates FIRST before any installations
# - Learn and apply the Logitech Optiions Plus feature flags
# - Check on ability to set/install Chrome browser extensions
# - Establishing settings on Notifications
# - Logitech Mouse settings? 

# Get the absolute path to the image
# *** REPLACE WITH MY IDEAL DESKTOP IMAGE ***
#IMAGE_PATH="${HOME}/dotfiles/settings/Desktop.png"

# AppleScript command to set the desktop background
#osascript <<EOF
#tell application "System Events"
#    set desktopCount to count of desktops
#    repeat with desktopNumber from 1 to desktopCount
#        tell desktop desktopNumber
#            set picture to "$IMAGE_PATH"
#        end tell
#    end repeat
#end tell
EOF

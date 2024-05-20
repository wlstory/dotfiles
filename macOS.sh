#!/usr/bin/env zsh

xcode-select --install

echo "Complete the installation of Xcode Command Line Tools before proceeding."
echo "Press enter to continue..."
read

# Set scroll as traditional instead of natural
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false && killall Finder

# THINGS TO DO
# - Turn off password saving and auto-fill in browsers (Chrome, Safari, Brave, DuckDuckGo)
# - Set HotCorners

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

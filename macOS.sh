#!/usr/bin/env zsh

xcode-select --install

echo "Complete the installation of Xcode Command Line Tools before proceeding."
echo "Press enter to continue..."
read

# Set scroll as natural vs traditional - check if commenting reverts
# defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true && killall Finder

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


# Hot Corners - https://dev.to/darrinndeal/setting-mac-hot-corners-in-the-terminal-3de
#echo "♨️  Hot Corners"
#defaults write com.apple.dock wvous-tl-corner -int 5 # Top Right    - Start Screen Saver
#defaults write com.apple.dock wvous-tr-corner -int 2 # Top Right    - Mission Control
#defaults write com.apple.dock wvous-bl-corner -int 4 # Bottom Left  - Desktop
#defaults write com.apple.dock wvous-br-corner -int 0 # Bottom Right - No option

EOF

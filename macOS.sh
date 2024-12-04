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

#defaults write com.apple.finder QLInlinePreviewMinimumSupportedSize -int 512 # Disable in-icon previews

# Adding items to the doc and setting hot corners requires a Dock restart
killall Dock
killall Finder

#EOF

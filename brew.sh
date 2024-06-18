#!/usr/bin/env zsh

# GitHub References
# Forked source
# https://github.com/packetmonkey/dotfiles/blob/313d4cef9ff3dbc70ca897442a16a9c503da13ee/Bin/setup-new-mac
# https://github.com/thoughtbot/rcm
# ...

# Install Homebrew if it isn't already installed
if ! command -v brew &>/dev/null; then
    echo "Homebrew not installed. Installing Homebrew."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Attempt to set up Homebrew PATH automatically for this session
    if [ -x "/opt/homebrew/bin/brew" ]; then
        # For Apple Silicon Macs
        echo "✅ Configuring Homebrew in PATH for Apple Silicon Mac..."
        export PATH="/opt/homebrew/bin:$PATH"
    fi
else
    echo "✅ Homebrew is already installed."
fi

# Verify brew is now accessible
if ! command -v brew &>/dev/null; then
    echo "Failed to configure Homebrew in PATH. Please add Homebrew to your PATH manually."
    exit 1
fi

# Update Homebrew and Upgrade any already-installed formulae
brew update
brew upgrade
brew upgrade --cask
brew cleanup

# Define an array of packages to install using Homebrew.
packages=(
    "python"
    "bash"
    "zsh"
    "git"
    "tree"
    "pylint"
    "black"
    "node"
    "mas"
    "gh"
    "shellcheck"
    "dashlane/tap/dashlane-cli"
    "ruby-install"
    "chruby"
    "starship"
    "obsidian"
    "whatsapp"
    "tree"
    "raspberry-pi-imager"
    "grammarly-desktop"
    "little-snitch"
    "dockutil"

)

echo "🍺 Installing Homebrew Packages ----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
# Loop over the array to install each application.
for package in "${packages[@]}"; do
    if brew list --formula | grep -q "^$package\$"; then
        echo "✅ $package is already installed. Skipping..."
    else
        echo "Installing $package..."
        brew install "$package"
    fi
done
echo ">>>>>>>>>>>>>>>>>>>---- Homebrew Packages Completed"

# Add the Homebrew zsh to allowed shells
echo "Changing default shell to Homebrew zsh"
echo "$(brew --prefix)/bin/zsh" | sudo tee -a /etc/shells >/dev/null
# Set the Homebrew zsh as default shell
chsh -s "$(brew --prefix)/bin/zsh"

# Git config name
echo "Please enter your FULL NAME for Git configuration:"
read git_user_name

# Git config email
echo "Please enter your EMAIL for Git configuration:"
read git_user_email

# Set my git credentials
$(brew --prefix)/bin/git config --global user.name "$git_user_name"
$(brew --prefix)/bin/git config --global user.email "$git_user_email"

# Install Prettier - used in both VS Code and Sublime Text
$(brew --prefix)/bin/npm install --global prettier

# Define an array of applications to install using Homebrew Cask.
apps=(
    "google-chrome"
    "microsoft-edge"
    "firefox"
    "brave-browser"
    "duckduckgo"
    "sublime-text"
    "visual-studio-code"
    "spotify"
    "discord"
    "box-drive"
    "google-drive"
    "dropbox"
    "gimp"
    "postman"
    "microsoft-teams"
    "microsoft-office"
    "adobe-acrobat-reader"
    "evernote"
    "github"
    "logi-options-plus"
    "sonos"
    "nordvpn"
    "elgato-stream-deck"
    "engine-dj"
    "chatgpt"
    "zoom"
    "warp"
)

# Loop over the array to install each application.
for app in "${apps[@]}"; do
    if brew list --cask | grep -q "^$app\$"; then
        echo "✅ $app is already installed. Skipping..."
    else
        echo "Installing $app..."
        brew install --cask "$app"
    fi
done

# Install Source Code Pro Font
# Tap the Homebrew font cask repository if not already tapped
# *** This tap is deprecated. Find replacement. ***
# *** Turn this into an array and implement in loop
brew tap | grep -q "^homebrew/cask-fonts$" || brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono
brew install --cask font-fira-code

# Define the font name
font_name="font-source-code-pro"

# Check if the font is already installed
if brew list --cask | grep -q "^$font_name\$"; then
    echo "✅ $font_name is already installed. Skipping..."
else
    echo "Installing $font_name..."
    brew install --cask "$font_name"
fi

# Define array for Apple Store Installs
app_store=(
    "517914548" # Dashlane
    "302584613" # Amazon Kindle Reader
    "1462114288" # Grammarly Safari
    "497799835" # Xcode
    "545519333" # Amazon Prime Video
    "441258766" # Magnet
)

# Mac App Store Installs
echo "Installing Mac App Store apps ----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
# Loop over the array to install each application from Apple Store.
for app in "${app_store[@]}"; do
    if mas list | grep -q "^$app\$"; then
        echo "✅ $app is already installed. Skipping..."
    else
        echo "Installing $app..."
        mas install "$app"
    fi
 done

echo ">>>>>>>>>>>>>>>>>>>---- Mac App Store apps installed"

# Programming Languages
echo ""
echo "🧑‍💻 Installing Programming Languages ----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"

if [[ -d "$HOME/.rubies" ]]; then
  echo "💎 Ruby already installed"
else
  ruby-install --update
  ruby-install --cleanup ruby
fi
echo ">>>>>>>>>>>>>>>>>>>---- Programming Languages installed."

# Once font is installed, Import your Terminal Profile
echo "Import your terminal settings..."
echo "Terminal -> Settings -> Profiles -> Import..."
echo "Import from ${HOME}/dotfiles/settings/Pro.terminal"
echo "Press enter to continue..."
read

# Update and clean up again for safe measure
brew update
brew upgrade
brew upgrade --cask
brew cleanup

#####################
# Reference
# https://lupin3000.github.io/macOS/defaults/
#####################

# Configure Finder
echo "Configuring Finder ----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
#defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true
defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool true
defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool false
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool false
defaults write com.apple.finder OpenWindowForNewRemovableDisk    -bool false
# Restart Finder
killall Finder
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>---- Finder Configuration Complete"

# Configure Safari
echo "Configuring Safari ----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
# Safari opens with: last session
defaults write com.apple.Safari AlwaysRestoreSessionAtLaunch -bool true
# disable safari auto open files
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
# Disable saving passwords - avoid issues with external password managers)
defaults write com.apple.Safari AutoFillPasswords -bool false            
# Disable auto filling Credit Cards
defaults write com.apple.Safari AutoFillCreditCardData -bool false 
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true      
killall Safari
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>---- Safari Configuration Complete"

# Configure Passwords
#defaults write com.apple.keychainaccess ShowKeychainStatusInMenuBar -bool false

# Configure Internet Accounts
#defaults write com.apple.systempreferences EnableBundles -bool true

# Configure Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 36

# Remove specified apps from the Dock
dockutil --remove 'Maps'
dockutil --remove 'Calendar'
dockutil --remove 'Notes'
dockutil --remove 'Freeform'

# Restart Dock
killall Dock

# Add specified apps to the Dock
dockutil --add /Applications/Evernote.app --no-restart
dockutil --add '/Applications/Google Chrome.app' --after Safari --no-restart
dockutil --add '/Applications/Microsoft Edge.app' --after 'Google Chrome' --no-restart
dockutil --add '/Applications/Microsoft Excel.app' --no-restart
dockutil --add '/Applications/Microsoft PowerPoint.app' --no-restart
dockutil --add '/Applications/Microsoft Word.app' --no-restart
dockutil --add '/Applications/Microsoft Teams.app' --no-restart
dockutil --add '/Applications/Visual Studio Code.app' --no-restart
dockutil --add /Applications/Spotify.app --after Music --no-restart

# Restart Dock
killall Dock

# Add Applications folder to the dock
# defaults write com.apple.dock persistent-others -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Applications/</string><key>_CFURLStringType</key><integer>15</integer></dict></dict></dict>"
dockutil --add '/Applications' --view grid --display folder --allhomes --no-restart

# Re-arrange Dock
dockutil --move 'System Settings' --position 2 --no-restart
dockutil --move 'App Store' --position 3 --no-restart
dockutil --move 'Calendar' --after 'Mail' --no-restart

# Restart Dock to ensure all changes are reflected
killall Dock

# Hot Corners - https://dev.to/darrinndeal/setting-mac-hot-corners-in-the-terminal-3de
#================================================
# *                 HOT CORNERS
#================================================
# Hot corners
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
echo "♨️  Setting Hot Corners"
defaults write com.apple.dock wvous-tl-corner -int 3 # Top Right    - Show Application Windows
defaults write com.apple.dock wvous-tr-corner -int 2 # Top Right    - Mission Control
defaults write com.apple.dock wvous-bl-corner -int 4 # Bottom Left  - Desktop
defaults write com.apple.dock wvous-br-corner -int 5 # Bottom Right - Start Screen Saver

# FINAL Restart Finder and Dock
killall Finder
killall Dock

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
    "fantastical"
    "tree"
    "raspberry-pi-imager"
    "grammarly-desktop"
    "little-snitch"
    "util"
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

# Remove this section eventually... Not needed. 
# Create the tutorial virtual environment I use frequently
# $(brew --prefix)/bin/python3 -m venv "${HOME}/tutorial"

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

# Code needs to be moved to after the install.sh file executes or near the end. Works in test.sh. 
# Define array for Dock updates
#dock_apps=(
#	"Fantastical.app"
#	"Evernote.app"
# 	"Google Chrome.app"
#  	"Microsoft Edge.app"
#   	"Microsoft Excel.app"
#    	"Microsoft PowerPoint.app"
#     	"Microsoft Word.app"
#     	"Microsoft Teams.app"
#      	"Visual Studio Code.app"
#       	"Spotify.app"
#)

# Add applications to dock
#echo ""
#echo "🖥️ Adding applications to the dock ----<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
#for appname in "${dock_apps[@]}"; do
#  if defaults read com.apple.dock persistent-apps | grep -q "${appname}"; then
#    echo "📲 ${appname} already on the dock"
#  else
#    defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/${appname}</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
#  fi
#done
#echo ">>>>>>>>>>>>>>>>>>>---- Dock updated."

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

# Adding items to the doc and setting hot corners requires a Dock restart
#killall 

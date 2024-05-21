#!/usr/bin/env zsh
############################
# This script creates symlinks from the home directory to any desired dotfiles in $HOME/dotfiles
# And also installs MacOS Software
# And also installs Homebrew Packages and Casks (Apps)
# And also sets up VS Code
# And also sets up Sublime Text
############################

############################
# THINGS TO DO / NOT YET AUTOMATED:
# - Turn off password saving and auto-fill in browsers (Chrome, Safari, Brave, DuckDuckGo)
# - Set HotCorners
# - Set-up the Dock app order and icons on the Dock to include Applications
# - Set Dock to Hide and Show with animation
# - Check for OS Updates FIRST before any installations
# - Learn and apply the Logitech Optiions Plus feature flags
# - Check on ability to set/install Chrome browser extensions
# - Establishing settings on Notifications
# - Logitech Mouse settings? 

# dotfiles directory 
dotfiledir="${HOME}/dotfiles"

# list of files/folders to symlink in ${homedir}
files=(zshrc zprofile zprompt bashrc bash_profile bash_prompt aliases private)

# change to the dotfiles directory
echo "Changing to the ${dotfiledir} directory"
cd "${dotfiledir}" || exit

# create symlinks (will overwrite old dotfiles)
for file in "${files[@]}"; do
    echo "Creating symlink to $file in home directory."
    ln -sf "${dotfiledir}/.${file}" "${HOME}/.${file}"
done

# Run the MacOS Script
./macOS.sh

# Run the Homebrew Script
./brew.sh

# Run VS Code Script
./vscode.sh

# Run the Sublime Script
./sublime.sh

echo "Installation Complete!"

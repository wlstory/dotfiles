# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

This is a **macOS development environment setup repository** containing shell scripts and configuration files to automate the installation and configuration of a complete development environment. The setup is highly personalized and includes dotfiles, Homebrew packages, application settings, and macOS system preferences.

## Repository Structure

- **Shell Scripts**: Executable setup scripts (`install.sh`, `brew.sh`, `macOS.sh`, `vscode.sh`, `baseline_prefs.sh`)
- **Dotfiles**: Shell configuration files (`.zshrc`, `.bashrc`, `.aliases`, `.bash_prompt`, `.zprompt`, `.shared_prompt`)
- **Settings Directory**: Editor configurations and application settings (Sublime Text, VS Code, Terminal themes)

## Primary Commands

### Initial Setup
```bash
# Clone and run full installation
git clone https://github.com/wlstory/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The `install.sh` script orchestrates the entire setup process:
1. Creates symlinks for dotfiles in `$HOME`
2. Runs macOS system configurations
3. Installs Homebrew packages and applications
4. Configures VS Code extensions and settings
5. Prompts for manual sign-ins to various applications

### Individual Script Usage
```bash
# Install/update Homebrew packages only
./brew.sh

# Apply macOS system preferences only
./macOS.sh
./baseline_prefs.sh

# Configure VS Code only
./vscode.sh
```

### Useful Aliases
After installation, these aliases are available (from `.aliases`):

```bash
# System updates
update_system    # Update macOS
update_brew      # Update Homebrew and packages

# File viewing
la               # List all files including hidden
show/hide        # Toggle hidden files in Finder

# History search
hg <query>       # Search command history

# Cleanup
clean            # Empty Trash and Downloads

# Screencasting mode
screenshare_mode # Hide dock, desktop icons, use analog clock
reg_mode         # Restore normal mode
```

## Architecture

### Multi-Shell Support

The repository supports both **Bash** and **Zsh** with shared configuration:

- **Zsh**: Primary shell (`.zshrc`, `.zprompt`, `.zprofile`)
- **Bash**: Secondary support (`.bashrc`, `.bash_prompt`, `.bash_profile`)
- **Shared**: `.shared_prompt` contains common prompt logic used by both shells
- **Aliases**: `.aliases` loaded by both shells for consistent command shortcuts

The installation automatically sets Homebrew's Zsh as the default shell.

### Installation Flow

1. **Symlink Creation**: Dotfiles are symlinked (not copied) from `~/dotfiles` to `$HOME`
2. **macOS Configuration**: System preferences, Finder, Safari, Dock settings
3. **Package Installation**: Homebrew formulae, casks, Mac App Store apps
4. **Editor Setup**: VS Code extensions and settings
5. **Manual Sign-ins**: User prompted to authenticate various applications

### Dotfile Symlinks

The `install.sh` script creates symlinks for:
- `.zshrc`, `.zprofile`, `.zprompt`
- `.bashrc`, `.bash_profile`, `.bash_prompt`
- `.aliases`
- `.private` (if exists - for local-only configuration)

**Note**: `.private` is excluded from version control and should contain machine-specific or sensitive configuration.

### Homebrew Packages

The `brew.sh` script installs:

**Development Tools**:
- Languages: Python, Ruby (via ruby-install/chruby), Node.js
- Version Control: Git, GitHub CLI (`gh`)
- Database: PostgreSQL
- Linters: pylint, eslint
- Tools: tree, mas (Mac App Store CLI), dockutil

**Applications** (Casks):
- Browsers: Chrome, Firefox, Edge, DuckDuckGo
- Editors: VS Code, Zed, Windsurf
- Terminals: Warp, iTerm2
- Productivity: 1Password, Obsidian, Craft, Capacities, Linear, Notion
- Development: GitHub Desktop, Beekeeper Studio, Bruno (API client)
- Communication: Slack, Zoom, Microsoft Teams, Claude, ChatGPT
- Cloud Storage: Box Drive, Google Drive, Dropbox
- Other: Spotify, NordVPN, Little Snitch, Tailscale

**Mac App Store Apps** (via `mas`):
- Amazon Kindle
- Grammarly Safari Extension
- Xcode
- Amazon Prime Video
- Magnet (window management)

### macOS System Preferences

The `baseline_prefs.sh` and `macOS.sh` scripts configure:

**Finder**:
- Show hidden files, status bar, path bar
- Show all file extensions
- Sort folders first
- Disable volume auto-opening

**Safari**:
- Enable developer menu and debug menu
- Restore last session on launch
- Disable auto-open downloads
- Disable password/credit card autofill

**Dock**:
- Enable auto-hide
- Hide recent applications
- Set tile size to 36
- Add/remove specific applications
- Configure custom arrangement

**Hot Corners**:
- Top Left: Show Application Windows
- Top Right: Mission Control
- Bottom Left: Desktop
- Bottom Right: Start Screen Saver

### VS Code Configuration

The `vscode.sh` script:
- Installs essential extensions (Python, Pylint, Copilot, Prettier, Ruby LSP, themes)
- Backs up existing settings to `.backup` files
- Copies custom settings and keybindings from `settings/` directory
- Opens VS Code for extension sign-in

## Development Guidelines

### Modifying the Setup

1. **Adding Homebrew Packages**: Edit the `packages=()` array in `brew.sh`
2. **Adding Applications**: Edit the `apps=()` array in `brew.sh`
3. **Adding Mac App Store Apps**: Add app ID to `app_store=()` array in `brew.sh`
4. **Shell Customization**: Modify `.aliases`, `.shared_prompt`, or shell-specific prompt files
5. **macOS Preferences**: Add `defaults write` commands to `baseline_prefs.sh`

### Testing Changes

```bash
# Test specific scripts individually
./brew.sh        # Safe - checks if packages already installed
./vscode.sh      # Safe - backs up existing settings
./baseline_prefs.sh  # Caution - modifies system preferences

# Full installation (destructive)
./install.sh     # Only run on fresh systems or when prepared for changes
```

### Safety Considerations

**⚠️ IMPORTANT**: These scripts make significant system changes:
- Symlinks **overwrite** existing dotfiles in `$HOME`
- System preferences are **modified** (some irreversible without fresh OS install)
- Backups are created **once** - re-running scripts overwrites backups
- Desktop background may be changed (currently commented out)

**Best Practice**: Fork the repository and customize before running on your system.

## Key Files Reference

### Shell Configuration
- `.zshrc` / `.bashrc` - Main shell configuration files
- `.shared_prompt` - Common prompt logic for both shells
- `.aliases` - Command shortcuts and color configurations
- `.bash_profile` / `.zprofile` - Environment variables

### Installation Scripts
- `install.sh` - Master orchestration script
- `brew.sh` - Homebrew packages, casks, and Mac App Store apps
- `macOS.sh` - Initial macOS setup (Xcode Command Line Tools)
- `baseline_prefs.sh` - System preferences configuration
- `vscode.sh` - VS Code extensions and settings

### Settings
- `settings/VSCode-Settings.json` - VS Code editor preferences
- `settings/VSCode-Keybindings.json` - VS Code keyboard shortcuts
- `settings/CMS.terminal` - Terminal theme profile
- `settings/Preferences.sublime-settings` - Sublime Text configuration
- `settings/RectangleConfig.json` - Window management settings

## Common Tasks

### Update Everything
```bash
update_brew      # Updates Homebrew, formulae, and casks
update_system    # Updates macOS system software
```

### Reset Dock Configuration
```bash
# Dock configuration is in baseline_prefs.sh
./baseline_prefs.sh  # Re-run to reset Dock to configured state
```

### Add New Application to Dock
```bash
# Use dockutil (installed via brew)
dockutil --add '/Applications/MyApp.app' --no-restart
killall Dock
```

### Restore Original Settings
Settings are backed up with `.backup` extension. To restore:
```bash
# VS Code settings
cp "${HOME}/Library/Application Support/Code/User/settings.json.backup" \
   "${HOME}/Library/Application Support/Code/User/settings.json"
```

## Git Configuration

The `brew.sh` script prompts for and configures:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

This is done interactively during installation.

## Font Installation

Fonts are installed via Homebrew Cask Fonts:
- JetBrains Mono
- Fira Code
- Source Code Pro

These fonts support programming ligatures and are optimized for code editors.

## Important Notes

1. **Private Configuration**: Create `.private` file in your home directory for machine-specific or sensitive settings
2. **Backup First**: The scripts backup some files but not comprehensively
3. **Idempotency**: Scripts generally check if items are already installed before reinstalling
4. **Manual Steps**: Some applications require manual sign-in after installation
5. **Personalization**: This setup is highly personalized - review and modify before use
6. **Shell Restart**: After installation, restart your terminal or run `exec zsh` to load new configuration

## License

MIT License - See `LICENSE-MIT.txt`

## Credits

Originally forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles)

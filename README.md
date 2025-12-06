# Development Environment Setup

This repository contains scripts and configuration files to set up a development environment for macOS. It's tailored for software development, focusing on a clean, minimal, and efficient setup.

## YouTube Video Walkthrough

Click on the image below to watch the video on YouTube:

[![Watch the video](https://img.youtube.com/vi/ra5kMCXO-6I/0.jpg)](https://youtu.be/ra5kMCXO-6I)

## Overview

The setup includes automated scripts for installing essential software, configuring Bash and Zsh shells, and setting up Visual Studio Code. This guide will help you replicate my development environment on your machine if you desire to do so.

### Key Features

- **Declarative package management** via Homebrew Brewfile
- **Cross-shell prompt** with Starship
- **Polyglot version management** with mise (Ruby, Node, Python, etc.)
- **Optional 1Password CLI integration** for automated git configuration
- **macOS system preferences** automation (Finder, Dock, Safari, etc.)

## Important Note Before Installation

**WARNING:** The configurations and scripts in this repository are **HIGHLY PERSONALIZED** to my own preferences and workflows. If you decide to use them, please be aware that they will **MODIFY** your current system, potentially making some changes that are **IRREVERSIBLE** without a fresh installation of your operating system.

If you would like a development environment similar to mine, I highly encourage you to fork this repository and make your own personalized changes to these scripts instead of running them exactly as I have them written for myself.

If you choose to run these scripts, please do so with **EXTREME CAUTION**. It's recommended to review the scripts and understand the changes they will make to your system before proceeding.

By using these scripts, you acknowledge and accept the risk of potential data loss or system alteration. Proceed at your own risk.

## Getting Started

### Prerequisites

- macOS (The scripts are tailored for macOS)
- Admin access (for Homebrew and system preference changes)

### Installation

1. Clone the repository to your local machine:
   ```sh
   git clone https://github.com/wlstory/dotfiles.git ~/dotfiles
   ```

2. Navigate to the `dotfiles` directory:
   ```sh
   cd ~/dotfiles
   ```

3. Run the installation script:
   ```sh
   ./install.sh
   ```

This script will:

- Create symlinks for dotfiles (`.bashrc`, `.zshrc`, `.aliases`, etc.)
- Symlink Starship configuration to `~/.config/starship.toml`
- Install Xcode Command Line Tools
- Install all packages from the `Brewfile` (formulae, casks, fonts, Mac App Store apps)
- Configure Git (via 1Password CLI if available, or interactive prompts)
- Install Ruby via mise
- Configure macOS system preferences (Finder, Dock, Safari, Hot Corners)
- Set up Visual Studio Code extensions and settings

## Package Management

### Brewfile

All Homebrew dependencies are declared in the `Brewfile`. This includes:

- **Formulae**: CLI tools (git, node, python, mise, starship, etc.)
- **Casks**: GUI applications (browsers, editors, productivity apps)
- **Fonts**: Development fonts (JetBrains Mono, Fira Code, Source Code Pro)
- **Mac App Store**: Apps installed via `mas` (Xcode, Magnet, etc.)

### Common Commands

```sh
# Install everything in Brewfile
brew bundle install --file=Brewfile

# Check what's missing from your system
brew bundle check --file=Brewfile

# Find installed packages not in Brewfile
brew bundle cleanup --file=Brewfile

# Generate Brewfile from currently installed packages
brew bundle dump --file=Brewfile

# Update all packages
brew update && brew upgrade && brew upgrade --cask
```

### Adding/Removing Packages

Edit the `Brewfile` directly, then run:
```sh
brew bundle install --file=Brewfile
```

## Version Management with mise

[mise](https://mise.jdx.dev/) is a polyglot version manager that handles Ruby, Node, Python, and many other languages. It replaces tools like rbenv, nvm, pyenv, and chruby.

### Common Commands

```sh
# Install and set global Ruby
mise use --global ruby@latest

# Install and set global Node
mise use --global node@20

# Install project-specific version (creates .mise.toml)
mise use ruby@3.2

# List installed versions
mise list

# Show active versions
mise current
```

### Project Configuration

Create a `.mise.toml` in your project root:
```toml
[tools]
ruby = "3.2"
node = "20"
python = "3.12"
```

## Shell Prompt with Starship

[Starship](https://starship.rs/) provides a fast, customizable prompt that works across Bash and Zsh.

### Configuration

The Starship config is at `config/starship.toml` and symlinked to `~/.config/starship.toml`.

Features:
- Username and hostname display
- Current directory with git repo truncation
- Git branch and status
- Language version indicators (Python, Node, Ruby)
- Error status indication

### Customization

Edit `config/starship.toml` to customize. See [Starship documentation](https://starship.rs/config/) for options.

## 1Password CLI Integration (Optional)

The setup script can automatically configure Git credentials from 1Password if:
1. 1Password CLI (`op`) is installed (included in Brewfile)
2. You're signed in (`op signin`)
3. You have a vault item with your Git credentials

### Setup

Create an item in 1Password:
- **Vault**: Personal
- **Item Name**: Git Config
- **Fields**:
  - `name`: Your Full Name
  - `email`: your.email@example.com

If 1Password CLI is unavailable or the item doesn't exist, the script falls back to interactive prompts.

## Configuration Files

| File | Purpose |
|------|---------|
| `.zshrc` | Zsh shell configuration (loads mise, Starship, aliases) |
| `.bashrc` | Bash shell configuration (loads mise, Starship, aliases) |
| `.aliases` | Command aliases shared between shells |
| `.private` | Local file for private settings (not in version control) |
| `.zprompt` | Legacy Zsh prompt (fallback if Starship unavailable) |
| `.bash_prompt` | Legacy Bash prompt (fallback if Starship unavailable) |
| `.shared_prompt` | Shared prompt logic for legacy prompts |
| `config/starship.toml` | Starship prompt configuration |
| `Brewfile` | Declarative Homebrew dependencies |
| `settings/` | Editor settings (VS Code, Sublime Text) |

## Scripts

| Script | Purpose |
|--------|---------|
| `install.sh` | Main entry point - runs all setup scripts |
| `brew.sh` | Installs packages, configures Git, sets up mise, configures macOS |
| `macOS.sh` | Installs Xcode Command Line Tools |
| `vscode.sh` | Installs VS Code extensions and settings |
| `audit_apps.sh` | (Deprecated) Use `brew bundle` commands instead |

## macOS Preferences Configured

The `brew.sh` script configures:

### Finder
- Show hidden files, status bar, path bar
- Show file extensions
- Sort folders first (including on Desktop)

### Dock
- Auto-hide enabled
- Hide recent apps
- Custom app arrangement

### Safari
- Developer menu enabled
- Restore session on launch
- Disable auto-fill for passwords and credit cards

### Hot Corners
- Top Left: Application Windows
- Top Right: Mission Control
- Bottom Left: Desktop
- Bottom Right: Screen Saver

### Stage Manager
- Disabled by default (can be enabled in `brew.sh`)

## Customizing Your Setup

You're encouraged to modify the scripts and configuration files to suit your preferences:

- **Packages**: Edit `Brewfile` to add/remove applications
- **Shell**: Modify `.zshrc` or `.bashrc` for shell customizations
- **Prompt**: Edit `config/starship.toml` to customize your prompt
- **Aliases**: Add your own aliases to `.aliases`
- **Private settings**: Create `.private` for machine-specific or sensitive settings
- **VS Code**: Adjust settings in `settings/` directory

## Contributing

Feel free to fork this repository and customize it for your setup. Pull requests for improvements and bug fixes are welcome, but I likely won't accept pull requests that simply add additional brew installations or change settings unless they align with my personal preferences.

## License

This project is licensed under the MIT License - see the [LICENSE-MIT.txt](LICENSE-MIT.txt) file for details.

## Acknowledgments

- Originally forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles)
- Thanks to all the open-source projects used in this setup

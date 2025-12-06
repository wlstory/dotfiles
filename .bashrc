# Bash configuration

# If not running interactively, exit script
[[ $- != *i* ]] && return

# Load dotfiles (aliases, private settings)
for file in ~/.{aliases,private}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Initialize mise (polyglot version manager for Ruby, Node, Python, etc.)
# Documentation: https://mise.jdx.dev/
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi

# Initialize Starship prompt (cross-shell, fast, customizable)
# Config location: ~/.config/starship.toml
# Documentation: https://starship.rs
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
else
    # Fallback to legacy prompt if Starship not installed
    [ -f ~/.bash_prompt ] && source ~/.bash_prompt
fi
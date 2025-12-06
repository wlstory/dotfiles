# Zsh configuration

autoload -Uz colors && colors
setopt PROMPT_SUBST

# Load dotfiles (aliases, private settings)
for file in ~/.{aliases,private}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Initialize Starship prompt (cross-shell, fast, customizable)
# Config location: ~/.config/starship.toml
# Documentation: https://starship.rs
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
else
    # Fallback to legacy prompt if Starship not installed
    [ -f ~/.zprompt ] && source ~/.zprompt
fi

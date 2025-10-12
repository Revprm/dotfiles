#!/bin/bash
# Installation script for HyDE dotfiles

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$HOME/dotfiles"

echo -e "${BLUE}Installing HyDE dotfiles...${NC}\n"

# Create necessary directories
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/lib"
mkdir -p "$HOME/.local/share"

# Backup existing configs
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up existing configs to $BACKUP_DIR"

# Function to backup and link
backup_and_link() {
    local source="$1"
    local target="$2"
    
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mv "$target" "$BACKUP_DIR/"
    elif [ -L "$target" ]; then
        rm "$target"
    fi
    
    ln -sf "$source" "$target"
}

# Link .config directories
for dir in "$DOTFILES_DIR/.config"/*; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        backup_and_link "$dir" "$HOME/.config/$dirname"
        echo -e "${GREEN}✓${NC} Linked .config/$dirname"
    fi
done

# Link .config files
for file in "$DOTFILES_DIR/.config"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        backup_and_link "$file" "$HOME/.config/$filename"
        echo -e "${GREEN}✓${NC} Linked .config/$filename"
    fi
done

# Copy .local files (not symlink, as they may be modified by HyDE)
if [ -d "$DOTFILES_DIR/.local/lib/hyde" ]; then
    mkdir -p "$HOME/.local/lib"
    cp -r "$DOTFILES_DIR/.local/lib/hyde" "$HOME/.local/lib/"
    echo -e "${GREEN}✓${NC} Copied .local/lib/hyde"
fi

if [ -d "$DOTFILES_DIR/.local/share" ]; then
    cp -r "$DOTFILES_DIR/.local/share"/* "$HOME/.local/share/"
    echo -e "${GREEN}✓${NC} Copied .local/share files"
fi

# Link home directory files
for file in "$DOTFILES_DIR/home"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        backup_and_link "$file" "$HOME/$filename"
        echo -e "${GREEN}✓${NC} Linked ~/$filename"
    fi
done

echo -e "\n${GREEN}Installation complete!${NC}"
echo "Backup created at: $BACKUP_DIR"
echo "Please log out and log back in for all changes to take effect."

#!/bin/bash
# Backup current configs before installation

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="$HOME/config_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}Backing up configs to $BACKUP_DIR${NC}\n"

# List of directories to backup
DIRS=(
    ".config/hypr"
    ".config/hyde"
    ".config/waybar"
    ".config/kitty"
    ".config/rofi"
    ".config/dunst"
    ".config/wlogout"
    ".config/uwsm"
    ".config/gtk-3.0"
    ".config/qt5ct"
    ".config/qt6ct"
    ".config/Kvantum"
    ".config/fastfetch"
    ".config/zsh"
    ".config/vim"
    ".config/btop"
)

# List of files to backup
FILES=(
    ".zshrc"
    ".zshenv"
    ".gitconfig"
    ".vimrc"
)

for dir in "${DIRS[@]}"; do
    if [ -d "$HOME/$dir" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname $dir)"
        cp -r "$HOME/$dir" "$BACKUP_DIR/$dir"
        echo -e "${GREEN}✓${NC} Backed up $dir"
    fi
done

for file in "${FILES[@]}"; do
    if [ -f "$HOME/$file" ]; then
        cp "$HOME/$file" "$BACKUP_DIR/"
        echo -e "${GREEN}✓${NC} Backed up ~/$file"
    fi
done

echo -e "\n${GREEN}Backup complete!${NC}"
echo "Location: $BACKUP_DIR"

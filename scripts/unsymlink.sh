#!/bin/bash
# Remove symlinks created by symlink.sh and restore from backup

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$HOME/dotfiles"

echo -e "${BLUE}Removing dotfiles symlinks...${NC}\n"

# Find the most recent backup
BACKUP_DIR=$(ls -td $HOME/config_backup_* 2>/dev/null | head -1)

if [ -n "$BACKUP_DIR" ]; then
    echo -e "${GREEN}Found backup: $BACKUP_DIR${NC}"
    read -p "Do you want to restore from this backup? (y/N): " -n 1 -r
    echo
    RESTORE_BACKUP=$REPLY
else
    echo -e "${YELLOW}No backup found${NC}"
    RESTORE_BACKUP="n"
fi

# Function to remove symlink
remove_link() {
    local target="$1"
    local name="$2"
    
    if [ -L "$target" ]; then
        rm "$target"
        echo -e "${GREEN}✓${NC} Removed symlink: $name"
        return 0
    elif [ -e "$target" ]; then
        echo -e "${YELLOW}⚠${NC} Not a symlink, skipping: $name"
        return 1
    fi
}

# Remove config directory symlinks
for dir in "$DOTFILES_DIR/.config"/*; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        remove_link "$HOME/.config/$dirname" ".config/$dirname"
    fi
done

# Remove config file symlinks
for file in "$DOTFILES_DIR/.config"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        remove_link "$HOME/.config/$filename" ".config/$filename"
    fi
done

# Remove home file symlinks
for file in "$DOTFILES_DIR/home"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        remove_link "$HOME/$filename" "~/$filename"
    fi
done

# Restore from backup if requested
if [[ $RESTORE_BACKUP =~ ^[Yy]$ ]]; then
    echo -e "\n${BLUE}Restoring from backup...${NC}"
    
    if [ -d "$BACKUP_DIR/.config" ]; then
        cp -r "$BACKUP_DIR/.config"/* "$HOME/.config/" 2>/dev/null
        echo -e "${GREEN}✓${NC} Restored .config files"
    fi
    
    # Restore home files
    for file in "$BACKUP_DIR"/*; do
        if [ -f "$file" ] && [[ "$(basename $file)" != .config ]]; then
            cp "$file" "$HOME/"
            echo -e "${GREEN}✓${NC} Restored ~/$(basename $file)"
        fi
    done
fi

echo -e "\n${GREEN}Done!${NC}"
echo "Symlinks have been removed."
if [[ $RESTORE_BACKUP =~ ^[Yy]$ ]]; then
    echo "Original configs have been restored from: $BACKUP_DIR"
fi

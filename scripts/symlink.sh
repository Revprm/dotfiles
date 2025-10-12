#!/bin/bash
# Create symlinks for dotfiles

DOTFILES_DIR="$HOME/dotfiles"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Creating symlinks...${NC}\n"

# Ask for confirmation if targets exist
TARGETS_EXIST=false
for dir in "$DOTFILES_DIR/.config"/*; do
    if [ -d "$dir" ] || [ -f "$dir" ]; then
        target="$HOME/.config/$(basename "$dir")"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            TARGETS_EXIST=true
            break
        fi
    fi
done

if [ "$TARGETS_EXIST" = true ]; then
    echo -e "${YELLOW}⚠ Warning: Existing config files/directories will be replaced with symlinks${NC}"
    read -p "Continue? This will move existing configs to a backup. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborted by user${NC}"
        exit 1
    fi
    
    # Create backup
    BACKUP_DIR="$HOME/.config_symlink_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo -e "${BLUE}Creating backup at: $BACKUP_DIR${NC}\n"
fi

# Function to create symlink
create_link() {
    local source="$1"
    local target="$2"
    local name="$3"
    
    # Backup existing file/directory if it's not a symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        if [ -n "$BACKUP_DIR" ]; then
            mv "$target" "$BACKUP_DIR/$(basename "$target")"
            echo -e "${YELLOW}↻${NC} Backed up $name"
        fi
    fi
    
    # Remove existing symlink
    if [ -L "$target" ]; then
        rm "$target"
    fi
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$target")"
    
    # Create the symlink
    ln -sf "$source" "$target"
    echo -e "${GREEN}✓${NC} Linked $name"
}

# Link config directories
echo -e "${BLUE}Linking .config directories...${NC}"
for dir in "$DOTFILES_DIR/.config"/*; do
    if [ -d "$dir" ]; then
        dirname=$(basename "$dir")
        create_link "$dir" "$HOME/.config/$dirname" ".config/$dirname"
    fi
done

# Link config files
echo -e "\n${BLUE}Linking .config files...${NC}"
for file in "$DOTFILES_DIR/.config"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        create_link "$file" "$HOME/.config/$filename" ".config/$filename"
    fi
done

# Link home files
if [ -d "$DOTFILES_DIR/home" ] && [ "$(ls -A $DOTFILES_DIR/home 2>/dev/null)" ]; then
    echo -e "\n${BLUE}Linking home directory files...${NC}"
    for file in "$DOTFILES_DIR/home"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            create_link "$file" "$HOME/$filename" "~/$filename"
        fi
    done
fi

echo -e "\n${GREEN}✓ Symlinks created successfully!${NC}"

if [ -n "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}Backup location: $BACKUP_DIR${NC}"
fi

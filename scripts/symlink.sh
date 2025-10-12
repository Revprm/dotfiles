#!/bin/bash
# Create symlinks for dotfiles (.config and .local/share)

DOTFILES_DIR="$HOME/dotfiles"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Creating symlinks...${NC}\n"

# Check for existing targets in both .config and .local/share
TARGETS_EXIST=false
for dir in "$DOTFILES_DIR/.config"/* "$DOTFILES_DIR/.local/share"/*; do
    [ -e "$dir" ] || continue
    target_path=""
    case "$dir" in
        *".config"/*) target_path="$HOME/.config/$(basename "$dir")" ;;
        *".local/share"/*) target_path="$HOME/.local/share/$(basename "$dir")" ;;
    esac
    if [ -e "$target_path" ] && [ ! -L "$target_path" ]; then
        TARGETS_EXIST=true
        break
    fi
done

if [ "$TARGETS_EXIST" = true ]; then
    echo -e "${YELLOW}⚠ Warning: Existing config or share files/directories will be replaced with symlinks${NC}"
    read -p "Continue? This will move existing ones to a backup. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Aborted by user${NC}"
        exit 1
    fi
    
    BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo -e "${BLUE}Creating backup at: $BACKUP_DIR${NC}\n"
fi

# Function to create symlink safely
create_link() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        if [ -n "$BACKUP_DIR" ]; then
            mv "$target" "$BACKUP_DIR/$(basename "$target")"
            echo -e "${YELLOW}↻${NC} Backed up $name"
        fi
    fi

    if [ -L "$target" ]; then
        rm "$target"
    fi

    mkdir -p "$(dirname "$target")"
    ln -sf "$source" "$target"
    echo -e "${GREEN}✓${NC} Linked $name"
}

# ---------- LINKING SECTIONS ---------- #

# .config directories
echo -e "${BLUE}Linking .config directories...${NC}"
for dir in "$DOTFILES_DIR/.config"/*; do
    [ -d "$dir" ] || continue
    dirname=$(basename "$dir")
    create_link "$dir" "$HOME/.config/$dirname" ".config/$dirname"
done

# .config files
echo -e "\n${BLUE}Linking .config files...${NC}"
for file in "$DOTFILES_DIR/.config"/*; do
    [ -f "$file" ] || continue
    filename=$(basename "$file")
    create_link "$file" "$HOME/.config/$filename" ".config/$filename"
done

# home directory files
if [ -d "$DOTFILES_DIR/home" ] && [ "$(ls -A "$DOTFILES_DIR/home" 2>/dev/null)" ]; then
    echo -e "\n${BLUE}Linking home directory files...${NC}"
    for file in "$DOTFILES_DIR/home"/*; do
        [ -f "$file" ] || continue
        filename=$(basename "$file")
        create_link "$file" "$HOME/$filename" "~/$filename"
    done
fi

# ---------- NEW SECTION: .local/share ---------- #
if [ -d "$DOTFILES_DIR/.local/share" ]; then
    echo -e "\n${BLUE}Linking .local/share directories and files...${NC}"
    for item in "$DOTFILES_DIR/.local/share"/*; do
        [ -e "$item" ] || continue
        name=$(basename "$item")
        create_link "$item" "$HOME/.local/share/$name" ".local/share/$name"
    done
fi

# ---------------------------------------------- #

echo -e "\n${GREEN}✓ All symlinks created successfully!${NC}"

if [ -n "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}Backup location: $BACKUP_DIR${NC}"
fi

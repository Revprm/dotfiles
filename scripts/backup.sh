#!/bin/bash
# Backup current configs before installation

BACKUP_DIR="$HOME/config_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Backing up configs to $BACKUP_DIR"

# List of directories to backup
DIRS=(
    ".config/hypr"
    ".config/hyde"
    ".config/waybar"
    ".config/kitty"
    ".config/rofi"
    ".config/dunst"
)

for dir in "${DIRS[@]}"; do
    if [ -d "$HOME/$dir" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname $dir)"
        cp -r "$HOME/$dir" "$BACKUP_DIR/$dir"
        echo "✓ Backed up $dir"
    fi
done

echo "Backup complete: $BACKUP_DIR"

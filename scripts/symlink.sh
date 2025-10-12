#!/bin/bash
# Create symlinks for dotfiles

DOTFILES_DIR="$HOME/dotfiles"

echo "Creating symlinks..."

# Function to create symlink
create_link() {
    local source="$1"
    local target="$2"
    
    if [ -L "$target" ]; then
        rm "$target"
    fi
    
    ln -sf "$source" "$target"
    echo "✓ Linked $(basename $target)"
}

# Link config directories
for dir in "$DOTFILES_DIR/.config"/*; do
    if [ -d "$dir" ]; then
        create_link "$dir" "$HOME/.config/$(basename $dir)"
    fi
done

# Link home files
for file in "$DOTFILES_DIR/home"/*; do
    if [ -f "$file" ]; then
        create_link "$file" "$HOME/$(basename $file)"
    fi
done

echo "Symlinks created!"

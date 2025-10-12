# HyDE Dotfiles

My personal dotfiles for HyDE (Hyprland Desktop Environment)

## 🖥️ Setup Info

- **OS**: Arch Linux
- **WM**: Hyprland
- **Theme Engine**: HyDE
- **Terminal**: Kitty
- **Shell**: Zsh
- **Bar**: Waybar
- **Launcher**: Rofi
- **Notifications**: Dunst

## 📦 Installation

### Prerequisites

Make sure you have HyDE installed. If not, install it first:
```bash
# Install HyDE
# Follow instructions from: https://github.com/prasanthrangan/hyprdots
```

### Quick Install

```bash
# Clone this repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run installation script
chmod +x scripts/install.sh
./scripts/install.sh
```

### Manual Install

```bash
# Backup your current configs
./scripts/backup.sh

# Create symlinks
./scripts/symlink.sh
```

## 📁 Structure

```
dotfiles/
├── .config/          # Configuration files
├── .local/           # Local data and libraries
├── home/             # Home directory files
├── scripts/          # Helper scripts
└── docs/             # Documentation
```

## 🎨 Customization

- Edit Hyprland config: `.config/hypr/`
- Change theme: Use HyDE theme selector or edit `.config/hyde/`
- Modify Waybar: `.config/waybar/`
- Terminal colors: `.config/kitty/`

## 📸 Screenshots

Add your screenshots here!

## 🙏 Credits

- [HyDE](https://github.com/prasanthrangan/hyprdots) by Prasanth Rangan
- [Hyprland](https://hyprland.org/)

## 📝 License

MIT License - Feel free to use and modify!

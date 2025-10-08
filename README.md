# dotfiles

Personal dotfiles for Arch Linux with Sway (Wayland) and Catppuccin Mocha theme.

## Preview

- **Window Manager**: Sway (i3-compatible Wayland compositor)
- **Status Bar**: Waybar with custom Catppuccin styling
- **Application Launcher**: Wofi
- **Terminal**: Alacritty with JetBrainsMono Nerd Font
- **Shell**: Zsh with Starship prompt
- **Editor**: Neovim (LazyVim distribution)
- **Color Scheme**: Catppuccin Mocha throughout

## Contents

```
.
├── .config/
│   ├── alacritty/      # Terminal emulator config
│   ├── nvim/           # Neovim (LazyVim) configuration
│   ├── sway/           # Sway window manager config
│   ├── waybar/         # Status bar config and styling
│   ├── wofi/           # Application launcher config
│   └── starship.toml   # Starship prompt config
├── .zshrc              # Zsh shell configuration
└── wallpapers/         # Desktop wallpaper
```

## Prerequisites

Install the required packages on Arch Linux:

```bash
# Core components
sudo pacman -S sway waybar wofi alacritty zsh neovim git

# Fonts
sudo pacman -S ttf-jetbrains-mono-nerd

# Additional utilities
sudo pacman -S starship fzf bat nnn grim slurp wl-clipboard
sudo pacman -S pipewire pipewire-pulse pamixer pulsemixer
sudo pacman -S chromium dunst bluez bluez-utils
sudo pacman -S btop cmus

# Zsh plugins
sudo pacman -S zsh-autosuggestions zsh-syntax-highlighting
```

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/windseekers/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Backup existing configs** (if any):
   ```bash
   mkdir -p ~/.config-backup
   cp -r ~/.config/sway ~/.config-backup/ 2>/dev/null
   cp -r ~/.config/waybar ~/.config-backup/ 2>/dev/null
   cp -r ~/.config/wofi ~/.config-backup/ 2>/dev/null
   cp -r ~/.config/alacritty ~/.config-backup/ 2>/dev/null
   cp -r ~/.config/nvim ~/.config-backup/ 2>/dev/null
   cp ~/.zshrc ~/.config-backup/ 2>/dev/null
   ```

3. **Create symlinks**:
   ```bash
   # Config directories
   ln -sf ~/dotfiles/.config/sway ~/.config/sway
   ln -sf ~/dotfiles/.config/waybar ~/.config/waybar
   ln -sf ~/dotfiles/.config/wofi ~/.config/wofi
   ln -sf ~/dotfiles/.config/alacritty ~/.config/alacritty
   ln -sf ~/dotfiles/.config/nvim ~/.config/nvim
   ln -sf ~/dotfiles/.config/starship.toml ~/.config/starship.toml

   # Shell config
   ln -sf ~/dotfiles/.zshrc ~/.zshrc

   # Wallpaper
   mkdir -p ~/Pictures/Wallpapers
   cp ~/dotfiles/wallpapers/a_landscape_of_mountains_and_a_sunset_01.png ~/Pictures/Wallpapers/
   ```

4. **Set Zsh as default shell** (if not already):
   ```bash
   chsh -s $(which zsh)
   ```

5. **Enable Bluetooth** (if needed):
   ```bash
   sudo systemctl enable bluetooth.service
   sudo systemctl start bluetooth.service
   ```

6. **Log out and log back into Sway**

## Post-Installation

### First Launch

- On first launch, Neovim will automatically install plugins via lazy.nvim
- Zsh will use the Starship prompt automatically
- Waybar should display all modules including Bluetooth and network

### Key Bindings (Sway)

- `Mod` (Super/Windows) + `Return`: Launch terminal (Alacritty)
- `Mod` + `d`: Application launcher (Wofi)
- `Mod` + `n`: File manager (nnn)
- `Mod` + `m`: Music player (cmus)
- `Mod` + `a`: Audio mixer (pulsemixer)
- `Mod` + `c`: Browser (Chromium)
- `Mod` + `Shift` + `q`: Kill window
- `Mod` + `Shift` + `c`: Reload Sway config
- `Print`: Screenshot tool (grim + slurp)

### Customization

- **Sway**: Edit `~/.config/sway/config`
- **Waybar**: Edit `~/.config/waybar/config` and `~/.config/waybar/style.css`
- **Colors**: All configs use Catppuccin Mocha. To change, update color values in each config file.

## Color Scheme

Using Catppuccin Mocha palette:

- **Base**: `#1e1e2e` (background)
- **Text**: `#cdd6f4` (foreground)
- **Blue**: `#89b4fa` (accents/focused)
- **Cyan**: `#89dceb` (network)
- **Purple**: `#cba6f7` (audio)
- **Green**: `#a6e3a1` (CPU)
- **Yellow**: `#f9e2af` (memory)

## Troubleshooting

### Waybar icons not showing
Ensure JetBrainsMono Nerd Font is installed:
```bash
fc-list | grep -i "jetbrains.*nerd"
```

### Cursor issues in Sway
The `.zshrc` includes `WLR_NO_HARDWARE_CURSORS=1` which fixes cursor rendering on some systems.

### Network/Bluetooth modules not working
Ensure NetworkManager and Bluetooth services are running:
```bash
systemctl status NetworkManager
systemctl status bluetooth
```

## License

MIT License - feel free to use and modify as needed.

## Credits

- [Catppuccin](https://github.com/catppuccin/catppuccin) - Color scheme
- [LazyVim](https://github.com/LazyVim/LazyVim) - Neovim distribution
- [Starship](https://starship.rs/) - Shell prompt

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
├── scripts/
│   ├── deploy/         # Modular deployment scripts
│   │   ├── docker.sh      # Docker installer
│   │   ├── lazydocker.sh  # lazydocker installer
│   │   └── dotfiles.sh    # Dotfiles deployer
│   ├── lib/
│   │   ├── colors.sh   # ANSI color variables
│   │   └── utils.sh    # Shared helper functions
│   ├── rpi4/
│   │   └── flash.sh    # Flash Arch ARM image to SD card (run on host)
│   ├── bootstrap/
│   │   ├── minimal.sh  # Bootstrap terminal environment (run on Pi)
│   │   └── desktop.sh  # Install Sway desktop (run on Pi, optional)
│   ├── pkg-install.sh  # FZF-based package installer
│   └── pkg-remove.sh   # FZF-based package remover
├── deploy.sh           # Modular TUI deployment tool
├── install-full.sh     # Full automated installer for fresh systems
├── .zshrc              # Zsh shell configuration
└── wallpapers/         # Desktop wallpapers
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

### Option 1: Full Automated Installation (Fresh Systems)

**Use this for:** Fresh/minimal Arch Linux installations (Raspberry Pi or x86_64) that need the complete Sway desktop environment.

Run the one-liner full installer — it handles everything automatically:

```bash
git clone https://github.com/windseekers/dotfiles.git ~/.dotfiles && bash ~/.dotfiles/install-full.sh
```

Or, if you prefer to run it without cloning first:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/windseekers/dotfiles/main/install-full.sh)
```

The full installer will:

1. Install all required packages via `pacman` (Sway, Waybar, Alacritty, etc.)
2. Back up any existing configs to `~/.config-backup/<timestamp>/`
3. Symlink dotfiles into `~/.config/`
4. Set Zsh as your default shell
5. Optionally enable the Bluetooth service
6. Print next steps

After it finishes, log out and log back in (or reboot). Sway starts automatically on tty1.

### Option 2: Modular Deployment (Existing Systems)

**Use this for:** Existing Arch systems (e.g., Manjaro/Archi) or when you only want specific components.

Clone the repo first:

```bash
git clone https://github.com/windseekers/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Then run the interactive deployment tool:

```bash
bash deploy.sh
```

The modular installer provides a checklist menu where you can select:

1. **Install Docker** - Minimal Docker Engine setup
2. **Install lazydocker** - Docker management TUI
3. **Deploy dotfiles** - Backup and symlink all configs (.zshrc + .config/*)
4. **Interactive package installer** - FZF-based package search/install
5. **Interactive package remover** - FZF-based package removal

Use SPACE to select/deselect options, ENTER to confirm, ESC to cancel.

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

## Raspberry Pi 4 Setup

Deploy these dotfiles to a fresh Arch Linux ARM installation on a Raspberry Pi 4.

### Prerequisites (host machine)

Install the required tools on your Arch Linux host before running the flash script:

```bash
sudo pacman -S parted dosfstools e2fsprogs libarchive wget
```

You also need the Arch Linux ARM tarball. Download it or place it at:
`~/Downloads/ArchLinuxARM-rpi-aarch64-latest.tar.gz`

The flash script will offer to download it automatically if not found.

### Step 1: Flash the SD card (on host)

Insert the SD card and run:

```bash
sudo bash scripts/rpi4/flash.sh
```

The script will:
- List available block devices so you can identify the SD card
- Require you to type `yes` explicitly before writing anything
- Partition, format, and extract Arch Linux ARM to the card
- Fix the `fstab` for the RPi4 aarch64 layout

### Step 2: First boot and minimal bootstrap (on Pi)

1. Insert the SD card into the Raspberry Pi 4, connect Ethernet, and power on
2. Find the Pi's IP address (check your router or run `arp -a` on the host)
3. SSH in as the default user:
   ```bash
   ssh alarm@<PI_IP>   # password: alarm
   su -                # switch to root, password: root
   ```
4. Run the bootstrap script (either from the cloned dotfiles or curl it):
   ```bash
   bash scripts/bootstrap/minimal.sh
   ```

The script will:
- Initialize the pacman keyring
- Update the system and install the RPi4-specific kernel
- Install base packages: `zsh`, `neovim`, `git`, `fzf`, `bat`, `btop`, etc.
- Create a new user with sudo access
- Set the hostname
- Clone this dotfiles repo and symlink `~/.zshrc`, `~/.config/nvim`, `~/.config/starship.toml`
- Fix DNS (`systemd-resolved`) and enable SSH

### Step 3: Install Sway desktop (optional, on Pi)

Log in as your new user, then run:

```bash
bash ~/.dotfiles/scripts/bootstrap/desktop.sh
```

The script will:
- Install the full Sway/Wayland stack: `sway`, `waybar`, `wofi`, `alacritty`, `dunst`, `pipewire`, etc.
- Install JetBrainsMono Nerd Font
- Symlink all desktop configs from `~/.dotfiles/.config/`
- Enable pipewire user services
- Configure Sway to auto-start when logging in on tty1

Reboot and log in on tty1 — Sway will launch automatically.

---

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

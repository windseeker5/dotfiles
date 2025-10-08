# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

This is a personal dotfiles repository for an Arch Linux system with a Wayland-based desktop environment. The configuration uses Sway (i3-compatible Wayland compositor) as the window manager with Catppuccin Mocha color scheme throughout.

## Architecture

### Window Manager & Desktop Environment
- **Sway**: Main window manager configuration at `.config/sway/config`
  - Mod key: Super/Windows key (Mod4)
  - Terminal: Alacritty
  - Application launcher: Wofi
  - Catppuccin Mocha color scheme with #89b4fa (blue) for focused windows
  - 8px inner gaps, 4px outer gaps, 2px borders

### Status Bar & UI
- **Waybar**: Top bar configuration at `.config/waybar/config` and `.config/waybar/style.css`
  - Modules: workspaces, window title, pulseaudio, CPU, memory, temperature, clock
  - Uses Nerd Font icons for visual elements

- **Wofi**: Application launcher at `.config/wofi/config`
  - 600x400 centered window with dark theme

### Terminal & Shell
- **Alacritty**: Terminal emulator configured at `.config/alacritty/alacritty.toml`
  - JetBrainsMono Nerd Font at size 11
  - Catppuccin Mocha colors (#1e1e2e background, #cdd6f4 foreground)
  - 95% opacity with 10px padding

- **Zsh**: Primary shell (`.zshrc`)
  - Plugins: zsh-autosuggestions, zsh-syntax-highlighting
  - FZF integration with Catppuccin colors
  - Starship prompt (configured at `.config/starship.toml`)
  - Key aliases: `vim`→`nvim`, `cat`→`bat`, `v`→`nvim`, `n`→`nnn`

### Text Editor
- **Neovim**: LazyVim distribution at `.config/nvim/`
  - Entry point: `init.lua` (bootstraps lazy.nvim)
  - Configuration structure:
    - `lua/config/`: Core config (keymaps, autocmds, options, lazy.lua)
    - `lua/plugins/`: Plugin specifications
  - Formatter: stylua configured at `stylua.toml`

### File Management & Utilities
- **nnn**: Terminal file manager
  - Configured with plugins (preview-tui, fzopen)
  - Trash support enabled
  - Custom color scheme

- **cmus**: Terminal music player
- **pulsemixer/pamixer**: Audio control
- **btop**: System monitor

## Key Sway Keybindings

- `Mod+Return`: Launch terminal (Alacritty)
- `Mod+d`: Application launcher (Wofi)
- `Mod+n`: nnn file manager
- `Mod+m`: cmus music player
- `Mod+a`: pulsemixer audio control
- `Mod+c`: Chromium browser
- `Mod+Shift+q`: Kill window
- `Print`: Screenshot with grim/slurp

## System Services

Auto-started via Sway config:
- pipewire & pipewire-pulse (audio)
- dunst (notifications)
- chromium (browser with Wayland support)
- swayidle (screen lock/power management: 5min lock, 10min screen off)

## Environment Variables

Key environment variables (`.zshrc`):
- `WLR_NO_HARDWARE_CURSORS=1`: Required for proper cursor rendering
- `WLR_RENDERER=pixman`: Software rendering fallback
- `PATH=~/.npm-global/bin:$PATH`: npm global packages

## Color Scheme

Catppuccin Mocha is consistently applied across all tools:
- Base: #1e1e2e (background)
- Text: #cdd6f4 (foreground)
- Blue: #89b4fa (accents/focused)
- Mantle: #313244 (surfaces)
- Surface: #45475a (inactive elements)

## Modifying Configurations

When editing configuration files:
1. Sway config changes: Reload with `Mod+Shift+c` or run `swaymsg reload`
2. Waybar changes: Restart waybar process (`pkill waybar && waybar &`)
3. Alacritty config: Auto-reloaded on save
4. Neovim config: Use `:Lazy` command for plugin management
5. Shell config: Source with `source ~/.zshrc`

## Font Requirements

All configurations use **JetBrainsMono Nerd Font**. Ensure this is installed system-wide for consistent rendering across all applications.

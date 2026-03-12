# Installing Ubuntu Server on iMac 2008

> Ubuntu Server 22.04 LTS is the recommended choice for iMac 2008.
> It handles 32-bit EFI and old Apple hardware automatically — no manual bootloader setup needed.

## 1. Flash the USB
```bash
sudo bash scripts/imac2008/flash.sh
```

## 2. Boot from USB
- Plug in the USB, power on the iMac
- Immediately hold **Option (⌥)** until the boot picker appears
- Select the USB drive

## 3. Follow the installer
- The Ubuntu installer is menu-driven — just follow the prompts
- It handles partitioning and bootloader (GRUB) automatically
- When asked for packages, select **OpenSSH server** if you want to SSH into the machine

## 4. Reboot
Remove the USB when the installer finishes and the machine reboots.
You'll land at a terminal login prompt — that's it, you're in.

## 5. First login
Default credentials are whatever you set during install.

Install git (needed to clone dotfiles):
```bash
sudo apt update && sudo apt install -y git
```

## 6. Bootstrap everything
This single script installs the full terminal + Sway desktop environment
(same setup as the Raspberry Pi 4):
```bash
git clone git@github.com:windseeker5/dotfiles.git
cd dotfiles
bash scripts/imac2008/bootstrap.sh
```

What it sets up:
- **Terminal**: zsh, neovim, tmux, fzf, ripgrep, bat, fd, nnn, btop, lsd, lazygit, fastfetch
- **Desktop**: sway, waybar, wofi, alacritty, pipewire, dunst, grim/slurp
- **Fonts**: JetBrainsMono Nerd Font, Noto
- **Dotfiles**: symlinks for zsh, nvim, starship, sway, waybar, wofi, alacritty
- **Sway**: Start manually by typing `sway` from the TTY

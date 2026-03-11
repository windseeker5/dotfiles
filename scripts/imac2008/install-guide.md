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

Install your essentials:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git zsh neovim tmux curl
```

## 6. Deploy dotfiles
```bash
git clone <your-dotfiles-repo>
cd dotfiles
bash scripts/bootstrap/desktop.sh
```

# Raspberry Pi Quick Setup Guide

Step-by-step setup for a fresh Arch Linux ARM install on the Pi.
No experience needed — just type what's in the code blocks.

---

## What you will need

- Pi connected to a screen and keyboard
- Ethernet cable plugged in
- This guide open on another screen

---

## Step 1 — First login

At the login prompt, type:

```
Username: alarm
Password: alarm
```

> The cursor won't move when you type a password — that's normal.

---

## Step 2 — Switch to root

```bash
su -
```

When it asks for a password, type:

```
root
```

You are now root (the administrator). Your prompt will end with `#`.

---

## Step 3 — Run the bootstrap script

This script sets up everything: updates the system, creates your user account,
sets a hostname, and clones this dotfiles repo.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/windseeker5/dotfiles/main/scripts/bootstrap/minimal.sh)
```

The script will ask you three questions — answer them one at a time:

| Question | What to type |
|----------|-------------|
| **Enter new username** | Your desired username (e.g. `kdresdell`) |
| **Set password for \<user\>** | A password you will remember |
| **Enter hostname** | A name for the Pi (e.g. `raspberrypi`) |
| **Enter dotfiles repo URL** | `https://github.com/windseeker5/dotfiles.git` |

Wait for it to finish. It will print `Bootstrap complete!` when done.

---

## Step 4 — Log out and log back in as your new user

```bash
exit    # leave root
exit    # leave alarm session
```

At the login prompt, log in with your new username and the password you just set.

---

## Step 5 — Install the Sway desktop

```bash
bash ~/.dotfiles/scripts/bootstrap/desktop.sh
```

This installs Sway, Waybar, Alacritty, fonts, audio, bluetooth, wi-fi tools,
and wires up all the configs. It takes a few minutes.

When it finishes you will see `Desktop setup complete!`.

---

## Step 6 — Reboot

```bash
sudo reboot
```

Log back in on tty1 with your username. **Sway starts automatically.**

---

## You are done

The desktop is running. Here are the first keybinds to know:

| Keys | Action |
|------|--------|
| `Super + Return` | Open terminal |
| `Super + d` | App launcher |
| `Super + a` | Audio mixer (wiremix) |
| `Super + b` | Bluetooth manager (bluetui) |
| `Super + w` | Wi-Fi manager (impala) |
| `Super + Shift + q` | Close window |
| `Super + Shift + c` | Reload Sway config |

---

## Troubleshooting

**`curl: command not found`** — try git instead:
```bash
git clone https://github.com/windseeker5/dotfiles.git /tmp/df
bash /tmp/df/scripts/bootstrap/minimal.sh
```

**No network / DNS not working after step 3** — the script fixes this automatically.
If you still have issues after reboot:
```bash
sudo systemctl restart systemd-resolved
```

**Waybar icons are squares** — the Nerd Font is still being installed.
Give it a minute or run `fc-cache -fv`.

**Wi-Fi not connecting** — `impala` requires `iwd`. Check it is running:
```bash
sudo systemctl status iwd
```

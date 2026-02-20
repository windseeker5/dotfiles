#!/usr/bin/env bash
# Pick a random wallpaper from the dotfiles wallpapers folder
wallpaper=$(find ~/.dotfiles/wallpapers -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | shuf -n1)
swaybg -o '*' -i "$wallpaper" -m fill &

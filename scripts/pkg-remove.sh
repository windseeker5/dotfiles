#!/usr/bin/env bash
# Show a fuzzy-finder TUI for picking installed packages to remove.

fzf_args=(
  --multi
  --preview 'pacman -Qi {1}'
  --preview-label='alt-p: toggle description, alt-j/k: scroll, tab: multi-select'
  --preview-label-pos='bottom'
  --preview-window 'down:65%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --color 'pointer:red,marker:red'
)

pkg_names=$(pacman -Qqe | fzf "${fzf_args[@]}")

if [[ -n "$pkg_names" ]]; then
  echo "$pkg_names" | tr '\n' ' ' | xargs sudo pacman -Rns --noconfirm
fi

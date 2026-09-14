#!/bin/bash
# Installs oh-my-zsh and the cobalt2 theme, once, if they are absent.
#
# `run_once_` (not `run_onchange_`): oh-my-zsh is a self-updating git checkout,
# so chezmoi should stand it up and then never touch it again. It is not in the
# Brewfile because there is no formula for it, and it is not chezmoi source
# because chezmoi would fight its self-updates on every apply.
#
# .zshrc degrades gracefully without it (bare compinit, no prompt), so a failure
# here is inconvenient rather than fatal.
set -euo pipefail

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "==> oh-my-zsh already present, skipping"
else
  echo "==> installing oh-my-zsh"
  # RUNZSH=no / --unattended: without them the installer execs an interactive zsh
  # at the end and `chezmoi apply` hangs here forever. CHSH=no leaves the login
  # shell alone — set it yourself with `chsh -s /bin/zsh` if needed.
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended
fi

# cobalt2 (ZSH_THEME in .zshrc) does NOT ship with oh-my-zsh — it lives in
# wesbos/Cobalt2-iterm. Without this, every shell prints
# "[oh-my-zsh] theme 'cobalt2' not found" and you get the default prompt.
# custom/themes/ survives oh-my-zsh's self-updates, so this stays put.
theme="$HOME/.oh-my-zsh/custom/themes/cobalt2.zsh-theme"
if [ -f "$theme" ]; then
  echo "==> cobalt2 theme already present, skipping"
else
  echo "==> installing cobalt2 theme"
  # Non-fatal: a missing theme is a cosmetic prompt problem, not worth aborting
  # the whole apply (and with it every file write queued after this script).
  mkdir -p "$(dirname "$theme")"
  if ! curl -fsSL -o "$theme" \
    https://raw.githubusercontent.com/wesbos/Cobalt2-iterm/master/cobalt2.zsh-theme; then
    rm -f "$theme"
    echo "warning: could not fetch cobalt2 theme — prompt falls back to default" >&2
  fi
fi

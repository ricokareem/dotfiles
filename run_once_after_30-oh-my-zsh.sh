#!/bin/bash
# Installs oh-my-zsh, once, if it is absent.
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
  exit 0
fi

echo "==> installing oh-my-zsh"
# RUNZSH=no / --unattended: without them the installer execs an interactive zsh
# at the end and `chezmoi apply` hangs here forever. CHSH=no leaves the login
# shell alone — set it yourself with `chsh -s /bin/zsh` if needed.
RUNZSH=no CHSH=no sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  "" --unattended

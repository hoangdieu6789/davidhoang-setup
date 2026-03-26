#!/usr/bin/env bash
# Copyright (c) 2025 Polara Enterprises, LLC. All rights reserved. This software is the proprietary property of Polara Enterprises, LLC and may not be copied, modified, distributed, or used without express written permission.

# Install zsh, Oh My Zsh, then apply bundled dotfiles from ./files/ on a new machine.
#
# Usage:
#   ./install.sh              # install packages, Oh My Zsh, copy files/zshrc and optional files/oh-my-zsh
#   ./install.sh --skip-chsh  # do not change the login shell to zsh
#
# Before first run, copy your backups into this directory:
#   files/zshrc          -> installed as ~/.zshrc
#   files/oh-my-zsh/     -> installed as ~/.oh-my-zsh/ (optional; replaces the fresh install)

set -euo pipefail

SKIP_CHSH=false
for arg in "$@"; do
  case "$arg" in
    --skip-chsh) SKIP_CHSH=true ;;
    -h|--help)
      echo "Usage: $0 [--skip-chsh]"
      exit 0
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES_DIR="${SCRIPT_DIR}/files"
ZSH_RC_SRC="${FILES_DIR}/zshrc"
OH_MY_ZSH_SRC="${FILES_DIR}/oh-my-zsh"

die() {
  echo "Error: $*" >&2
  exit 1
}

install_packages() {
  if ! command -v curl >/dev/null 2>&1; then
    die "curl is required but not found. Install curl and re-run."
  fi

  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
  else
    die "Cannot detect OS (missing /etc/os-release)."
  fi

  local id_like="${ID_LIKE:-}"
  case "${ID:-}" in
    debian|ubuntu|linuxmint|pop)
      sudo apt-get update
      sudo apt-get install -y zsh git
      ;;
    fedora|rhel|centos)
      if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y zsh git
      else
        sudo yum install -y zsh git
      fi
      ;;
    arch|manjaro)
      sudo pacman -S --needed --noconfirm zsh git
      ;;
    opensuse*|sles)
      sudo zypper install -y zsh git
      ;;
    *)
      if echo "$id_like" | grep -q debian; then
        sudo apt-get update
        sudo apt-get install -y zsh git
      elif echo "$id_like" | grep -q rhel; then
        sudo dnf install -y zsh git 2>/dev/null || sudo yum install -y zsh git
      else
        die "Unsupported distro ID=${ID:-unknown}. Install zsh and git manually, then re-run."
      fi
      ;;
  esac
}

install_oh_my_zsh() {
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    echo "Oh My Zsh already present at ${HOME}/.oh-my-zsh; skipping installer."
    return 0
  fi
  echo "Installing Oh My Zsh (unattended)..."
  export RUNZSH=no
  export CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

apply_dotfiles() {
  if [[ -f "${ZSH_RC_SRC}" ]]; then
    echo "Installing ${ZSH_RC_SRC} -> ${HOME}/.zshrc"
    cp -f "${ZSH_RC_SRC}" "${HOME}/.zshrc"
  else
    echo "No ${ZSH_RC_SRC} found; leaving ~/.zshrc as installed by Oh My Zsh."
  fi

  # Only replace ~/.oh-my-zsh if this looks like a full Oh My Zsh tree (avoids empty placeholder dirs).
  if [[ -f "${OH_MY_ZSH_SRC}/oh-my-zsh.sh" ]]; then
    echo "Replacing ~/.oh-my-zsh with contents of ${OH_MY_ZSH_SRC}"
    rm -rf "${HOME}/.oh-my-zsh"
    cp -a "${OH_MY_ZSH_SRC}" "${HOME}/.oh-my-zsh"
  else
    echo "No optional ${OH_MY_ZSH_SRC}/ backup (need oh-my-zsh.sh inside); keeping Oh My Zsh from installer."
  fi
}

set_login_shell() {
  if [[ "${SKIP_CHSH}" == true ]]; then
    echo "Skipping chsh (--skip-chsh). Run: chsh -s \"\$(command -v zsh)\""
    return 0
  fi
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ -z "${zsh_path}" ]]; then
    die "zsh not found in PATH after install."
  fi
  if [[ "${SHELL}" == "${zsh_path}" ]]; then
    echo "Login shell is already zsh."
    return 0
  fi
  echo "Setting login shell to ${zsh_path} (sudo required)..."
  sudo chsh -s "${zsh_path}" "${USER}"
}

main() {
  install_packages
  install_oh_my_zsh
  apply_dotfiles
  set_login_shell
  echo "Done. Open a new terminal or run: exec zsh -l"
}

main "$@"

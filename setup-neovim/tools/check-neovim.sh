#!/usr/bin/env bash
# Quick sanity checks after install (or on any machine).
# Usage: ./tools/check-neovim.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ok() { printf "ok  %s\n" "$*"; }
fail() { printf "ERR %s\n" "$*" >&2; exit 1; }

# Full semver-ish string after "v", e.g. 0.9.5 or 0.11.0
nvim_display_version() {
  local line="$1"
  if [[ "$line" =~ NVIM\ v([^[:space:]]+) ]]; then
    printf "%s" "${BASH_REMATCH[1]}"
  else
    printf "?"
  fi
}

# True if line is NVIM v... and version is >= 0.11 (or major > 0).
nvim_line_meets_policy() {
  local line="$1"
  [[ "$line" =~ NVIM\ v([0-9]+)\.([0-9]+) ]] || return 1
  local major="${BASH_REMATCH[1]}"
  local minor="${BASH_REMATCH[2]}"
  [[ "$major" -gt 0 ]] || [[ "$minor" -ge 11 ]]
}

first_version_line() {
  "$1" --version 2>/dev/null | head -1
}

command -v nvim >/dev/null 2>&1 || fail "nvim not in PATH"

path_line="$(first_version_line nvim)"
path_ver="$(nvim_display_version "$path_line")"
ok "nvim on PATH: $path_line"

LOCAL_NVIM="${HOME}/.local/bin/nvim"
NVIM_CMD=(nvim)

if nvim_line_meets_policy "$path_line"; then
  ok "version policy: 0.11+ (nvim-lspconfig)"
elif [[ -x "${LOCAL_NVIM}" ]]; then
  local_line="$(first_version_line "${LOCAL_NVIM}")"
  if nvim_line_meets_policy "$local_line"; then
    ok "version policy: 0.11+ via ${LOCAL_NVIM}"
    printf "\nNOTE: PATH still points at older Neovim (v%s).\n" "${path_ver}" >&2
    printf "      Put local build first, then re-run this script:\n" >&2
    printf "        export PATH=\"%s/.local/bin:\$PATH\"\n" "${HOME}" >&2
    printf "      Or run:  %s/.local/bin/nvim\n\n" "${HOME}" >&2
    NVIM_CMD=("${LOCAL_NVIM}")
  else
    fail "Neovim must be 0.11+ for current nvim-lspconfig (PATH has v${path_ver}, ~/.local/bin has v$(nvim_display_version "$local_line")). From setup-neovim run: ./install.sh"
  fi
else
  fail "Neovim must be 0.11+ for current nvim-lspconfig (you have v${path_ver}). From this directory run: ./install.sh   (do not use --skip-packages unless Neovim 0.11+ is already installed)."
fi

CFG="${XDG_CONFIG_HOME:-${HOME}/.config}/nvim"
[[ -f "${CFG}/init.lua" ]] || fail "missing ${CFG}/init.lua"
ok "config: ${CFG}/init.lua"

if [[ -d "${ROOT}/files/nvim" ]]; then
  ok "repo templates present: ${ROOT}/files/nvim"
fi

if "${NVIM_CMD[@]}" -u NONE --headless "+qa" >/dev/null 2>&1; then
  ok "nvim runs headless (-u NONE)"
else
  fail "nvim failed headless (try: ${NVIM_CMD[*]} -u NONE --headless +qa)"
fi

printf "\nOptional: open nvim and run :Mason for LSP packages (see lua/config/mason.lua).\n"

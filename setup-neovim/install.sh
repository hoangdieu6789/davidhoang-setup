#!/usr/bin/env bash
# Install Neovim (0.11+), Go toolchain, tools (ripgrep, fd, lazygit, node), ~/.config/nvim,
# plugins (headless :Lazy restore) and language servers (Mason); then print a check list.
#
# Usage:
#   ./install.sh                 # packages + Go 1.24.3 + config + Lazy sync
#   ./install.sh --skip-packages # config + Lazy sync only (Neovim 0.11+ and tooling on you)
#   ./install.sh --link          # symlink ~/.config/nvim to files/nvim (edits go to git; sync with git pull)
#   ./install.sh --help

set -euo pipefail

SKIP_PACKAGES=false
LINK_CONFIG=false
for arg in "$@"; do
  case "$arg" in
    --skip-packages|--config-only) SKIP_PACKAGES=true ;;
    --link) LINK_CONFIG=true ;;
    -h|--help)
      echo "Usage: $0 [--skip-packages|--config-only] [--link]"
      exit 0
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILES_DIR="${SCRIPT_DIR}/files"
NVIM_SRC="${FILES_DIR}/nvim"
GO_VERSION="1.24.3"
GO_INSTALL_DIR="${HOME}/.local/go"

die() {
  echo "Error: $*" >&2
  exit 1
}

# GO_PLATFORM (go.dev tarball) and NVIM_DIST (extracted directory name under ~/.local).
resolve_platform() {
  case "$(uname -s):$(uname -m)" in
    Linux:x86_64)
      GO_PLATFORM=linux-amd64
      NVIM_DIST=nvim-linux-x86_64
      ;;
    Linux:aarch64 | Linux:arm64)
      GO_PLATFORM=linux-arm64
      NVIM_DIST=nvim-linux-arm64
      ;;
    Darwin:arm64)
      GO_PLATFORM=darwin-arm64
      NVIM_DIST=nvim-macos-arm64
      ;;
    Darwin:x86_64)
      GO_PLATFORM=darwin-amd64
      NVIM_DIST=nvim-macos-x86_64
      ;;
    *)
      return 1
      ;;
  esac
}

nvim_meets_min_version() {
  command -v nvim >/dev/null 2>&1 || return 1
  local line major minor
  line="$(nvim --version 2>/dev/null | head -1)"
  [[ "$line" =~ NVIM\ v([0-9]+)\.([0-9]+) ]] || return 1
  major="${BASH_REMATCH[1]}"
  minor="${BASH_REMATCH[2]}"
  [[ "$major" -gt 0 ]] || [[ "$minor" -ge 11 ]]
}

install_neovim_from_github_release() {
  resolve_platform || return 1
  echo "Neovim on PATH is older than 0.11; installing from GitHub into ~/.local ..."
  local url tmp
  url="https://github.com/neovim/neovim/releases/latest/download/${NVIM_DIST}.tar.gz"
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' EXIT
  curl -kfsSL "${url}" -o "${tmp}/nvim.tgz"
  mkdir -p "${HOME}/.local"
  tar xzf "${tmp}/nvim.tgz" -C "${HOME}/.local"
  rm -rf "${tmp}"
  trap - EXIT
  mkdir -p "${HOME}/.local/bin"
  ln -sf "${HOME}/.local/${NVIM_DIST}/bin/nvim" "${HOME}/.local/bin/nvim"
  echo "Installed ${NVIM_DIST} -> ${HOME}/.local/bin/nvim"
}

install_go_toolchain() {
  resolve_platform || die "Go auto-install supports Linux and macOS only (install Go ${GO_VERSION} from https://go.dev/dl/ manually)."

  local tarball url tmp expected actual
  tarball="go${GO_VERSION}.${GO_PLATFORM}.tar.gz"
  if [[ -x "${GO_INSTALL_DIR}/bin/go" ]] && "${GO_INSTALL_DIR}/bin/go" version 2>/dev/null | grep -q "go${GO_VERSION} "; then
    echo "Go ${GO_VERSION} already at ${GO_INSTALL_DIR}/bin/go"
    return 0
  fi
  [[ -d "${GO_INSTALL_DIR}" ]] && echo "Replacing Go under ${GO_INSTALL_DIR} with ${GO_VERSION} ..."

  # Tarballs redirect here from go.dev; go.dev/*.sha256 returns HTML — use dl.google.com for checksums.
  url="https://dl.google.com/go/${tarball}"
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' EXIT
  curl -kfsSL "${url}" -o "${tmp}/${tarball}"
  curl -kfsSL "${url}.sha256" -o "${tmp}/${tarball}.sha256"
  expected="$(awk '{print $1}' "${tmp}/${tarball}.sha256")"
  [[ "${expected}" =~ ^[0-9a-f]{64}$ ]] || die "Invalid Go checksum download (got non-hex content). Check network and URL ${url}.sha256"
  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "${tmp}/${tarball}" | awk '{print $1}')"
  else
    actual="$(shasum -a 256 "${tmp}/${tarball}" | awk '{print $1}')"
  fi
  [[ "${actual}" == "${expected}" ]] || die "Go tarball SHA256 mismatch (got ${actual}, expected ${expected})."

  mkdir -p "${HOME}/.local"
  rm -rf "${GO_INSTALL_DIR}"
  tar -C "${HOME}/.local" -xzf "${tmp}/${tarball}"
  rm -rf "${tmp}"
  trap - EXIT

  [[ -x "${GO_INSTALL_DIR}/bin/go" ]] || die "Go install failed: missing ${GO_INSTALL_DIR}/bin/go"
  echo "Installed Go ${GO_VERSION} -> ${GO_INSTALL_DIR}/bin/go"
}

# nvim-treesitter 1.x runs `tree-sitter build`; the CLI must be on PATH (0.26.1+).
tree_sitter_cli_zip_name() {
  case "$(uname -s):$(uname -m)" in
    Linux:x86_64)
      echo "tree-sitter-cli-linux-x64.zip"
      ;;
    Linux:aarch64 | Linux:arm64)
      echo "tree-sitter-cli-linux-arm64.zip"
      ;;
    Darwin:arm64)
      echo "tree-sitter-cli-macos-arm64.zip"
      ;;
    Darwin:x86_64)
      echo "tree-sitter-cli-macos-x64.zip"
      ;;
    *)
      echo ""
      ;;
  esac
}

install_tree_sitter_cli() {
  if command -v tree-sitter >/dev/null 2>&1; then
    echo "tree-sitter CLI already on PATH ($(tree-sitter --version 2>/dev/null | head -1))"
    return 0
  fi

  if [[ "$(uname -s)" == Darwin ]] && command -v brew >/dev/null 2>&1; then
    echo "Installing tree-sitter CLI via Homebrew..."
    # The `tree-sitter` formula is only the library; the CLI is `tree-sitter-cli`.
    brew install tree-sitter-cli
    command -v tree-sitter >/dev/null 2>&1 || die "brew install tree-sitter-cli did not provide a tree-sitter binary on PATH."
    return 0
  fi

  local zipn url tmp found
  zipn="$(tree_sitter_cli_zip_name)"
  [[ -n "${zipn}" ]] || die "tree-sitter CLI: unsupported OS/arch $(uname -s) $(uname -m). Install from https://github.com/tree-sitter/tree-sitter/releases"

  command -v unzip >/dev/null 2>&1 || die "unzip is required to install tree-sitter CLI. Install unzip and re-run."

  url="https://github.com/tree-sitter/tree-sitter/releases/latest/download/${zipn}"
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' EXIT
  curl -kfsSL "${url}" -o "${tmp}/tree-sitter-cli.zip"
  mkdir -p "${tmp}/x"
  unzip -q "${tmp}/tree-sitter-cli.zip" -d "${tmp}/x"
  found="$(find "${tmp}/x" -type f -name tree-sitter | head -1)"
  [[ -n "${found}" ]] || die "Could not find tree-sitter executable inside ${zipn}"
  mkdir -p "${HOME}/.local/bin"
  install -m755 "${found}" "${HOME}/.local/bin/tree-sitter"
  rm -rf "${tmp}"
  trap - EXIT
  echo "Installed tree-sitter CLI -> ${HOME}/.local/bin/tree-sitter ($("${HOME}/.local/bin/tree-sitter" --version 2>/dev/null | head -1))"
}

export_user_local_path() {
  if [[ -x "${GO_INSTALL_DIR}/bin/go" ]] && [[ ":${PATH}:" != *":${GO_INSTALL_DIR}/bin:"* ]]; then
    export PATH="${GO_INSTALL_DIR}/bin:${PATH}"
  fi
  if [[ -d "${HOME}/.local/bin" ]] && [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
    export PATH="${HOME}/.local/bin:${PATH}"
  fi
}

apt_install_core() {
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update -qq
  sudo apt-get install -y -qq neovim git curl ca-certificates build-essential pkg-config ripgrep unzip
  if apt-cache show fd-find >/dev/null 2>&1; then
    sudo apt-get install -y -qq fd-find || true
  fi
}

# Homebrew formula:command pairs. A formula is installed only when its command is missing.
MACOS_BREW_TOOLS=(
  "git:git"
  "curl:curl"
  "ripgrep:rg"
  "fd:fd"
  "lazygit:lazygit"
  "node:node"
)

install_packages_macos() {
  command -v cc >/dev/null 2>&1 || die "macOS: a C compiler is required (plugins and parsers are compiled). Run: xcode-select --install"
  if ! command -v brew >/dev/null 2>&1; then
    echo "Warning: Homebrew not found (https://brew.sh). ripgrep, fd, lazygit and node will not be installed." >&2
    echo "         If Neovim is below 0.11, it will be installed from GitHub releases next." >&2
    command -v git >/dev/null 2>&1 || die "macOS: git is required. Run: xcode-select --install"
    return 0
  fi
  local formulas=() entry
  nvim_meets_min_version || formulas+=(neovim)
  for entry in "${MACOS_BREW_TOOLS[@]}"; do
    command -v "${entry#*:}" >/dev/null 2>&1 || formulas+=("${entry%%:*}")
  done
  if [[ ${#formulas[@]} -eq 0 ]]; then
    echo "macOS: Neovim and all Homebrew tools are already installed."
  else
    echo "macOS: installing with Homebrew: ${formulas[*]}"
    brew install "${formulas[@]}" || echo "Warning: brew install failed for some of: ${formulas[*]} (see the check at the end)." >&2
  fi
}

install_packages_linux() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
  else
    die "Linux: missing /etc/os-release; install Neovim 0.11+, git, curl, gcc, ripgrep manually."
  fi

  local id_like="${ID_LIKE:-}"
  case "${ID:-}" in
    debian | ubuntu | linuxmint | pop)
      apt_install_core
      ;;
    fedora | rhel | centos)
      if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y -q neovim git curl gcc gcc-c++ make pkgconf-pkg-config ripgrep unzip fd-find \
          || sudo dnf install -y -q neovim git curl gcc gcc-c++ make pkgconf-pkg-config ripgrep unzip
      else
        sudo yum install -y -q neovim git curl gcc gcc-c++ make pkgconfig ripgrep unzip || true
      fi
      ;;
    arch | manjaro)
      sudo pacman -S --needed --noconfirm neovim git curl base-devel pkgconf ripgrep unzip fd
      ;;
    opensuse* | sles)
      sudo zypper install -y neovim git curl gcc gcc-c++ make pkg-config ripgrep unzip fd || true
      ;;
    *)
      if echo "$id_like" | grep -q debian; then
        apt_install_core
      elif echo "$id_like" | grep -q rhel; then
        sudo dnf install -y -q neovim git curl gcc gcc-c++ make pkgconf-pkg-config ripgrep unzip || true
      else
        die "Unsupported distro ID=${ID:-unknown}. Install Neovim 0.11+, git, curl, gcc, ripgrep, then: $0 --skip-packages"
      fi
      ;;
  esac
  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo "Linux: installing Node.js and npm (language servers for TypeScript, Angular, JSON, Bash, YAML)..."
    command -v node >/dev/null 2>&1 || linux_try_install nodejs || true
    command -v npm >/dev/null 2>&1 || linux_try_install npm || true
  fi
  if ! command -v lazygit >/dev/null 2>&1; then
    linux_try_install lazygit || true
    command -v lazygit >/dev/null 2>&1 \
      || echo "Note: lazygit is not in your package manager (needed for Space gg). See https://github.com/jesseduffield/lazygit#installation" >&2
  fi
}

# Best effort: install one package with the distro package manager. Returns non-zero on failure.
linux_try_install() {
  local pkg="$1"
  if command -v apt-get >/dev/null 2>&1; then
    apt-cache show "${pkg}" >/dev/null 2>&1 && sudo apt-get install -y -qq "${pkg}"
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y -q "${pkg}"
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm "${pkg}"
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y "${pkg}"
  else
    return 1
  fi
}

install_packages() {
  if [[ "${SKIP_PACKAGES}" == true ]]; then
    echo "Skipping system packages (--skip-packages)."
    return 0
  fi

  case "$(uname -s)" in
    Darwin)
      install_packages_macos
      ;;
    Linux)
      install_packages_linux
      ;;
    *)
      die "Unsupported OS: $(uname -s). Install Neovim 0.11+ manually, then: $0 --skip-packages"
      ;;
  esac

  command -v curl >/dev/null 2>&1 || die "curl is required but not found."
  command -v git >/dev/null 2>&1 || die "git is required but not found."
}

require_neovim() {
  if nvim_meets_min_version; then
    echo "Neovim OK: $(nvim --version | head -1)"
    return 0
  fi
  die "Neovim 0.11+ required. Install from https://github.com/neovim/neovim/releases or run $0 without --skip-packages."
}

apply_config() {
  [[ -d "${NVIM_SRC}" ]] || die "Missing bundled config: ${NVIM_SRC}"
  local cfg_root="${XDG_CONFIG_HOME:-${HOME}/.config}"
  local dest="${cfg_root}/nvim"
  mkdir -p "${cfg_root}"
  if [[ "${LINK_CONFIG}" == true ]]; then
    if [[ -L "${dest}" ]]; then
      rm "${dest}"
    elif [[ -e "${dest}" ]]; then
      local backup
      backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
      echo "Moving existing ${dest} -> ${backup}"
      mv "${dest}" "${backup}"
    fi
    echo "Linking ${dest} -> ${NVIM_SRC}"
    ln -s "${NVIM_SRC}" "${dest}"
    return 0
  fi
  echo "Installing ${NVIM_SRC} -> ${dest}"
  rm -rf "${dest}"
  cp -a "${NVIM_SRC}" "${dest}"
}

bootstrap_lazy() {
  echo "Running headless :Lazy sync/restore (first run may take a few minutes)..."
  local git_ssl="${GIT_SSL_NO_VERIFY:-}"
  export GIT_SSL_NO_VERIFY="${GIT_SSL_NO_VERIFY:-1}"
  # nvim-treesitter shells out to `tree-sitter`; put user toolchain first (matches export_user_local_path).
  export PATH="${HOME}/.local/bin:${GO_INSTALL_DIR}/bin:${PATH}"
  if [[ "${SKIP_PACKAGES}" != true ]] && ! command -v tree-sitter >/dev/null 2>&1; then
    die "tree-sitter CLI not on PATH after install. Expected ${HOME}/.local/bin/tree-sitter. Re-run without --skip-packages or install tree-sitter (see README)."
  fi
  if [[ "${SKIP_PACKAGES}" == true ]] && ! command -v tree-sitter >/dev/null 2>&1; then
    echo "Warning: tree-sitter not on PATH; parser compile may fail. Install CLI or run $0 without --skip-packages." >&2
  fi
  # With a lockfile, install the pinned plugin versions instead of updating them (keeps machines in sync).
  local lazy_cmd="sync"
  local lock="${XDG_CONFIG_HOME:-${HOME}/.config}/nvim/lazy-lock.json" saved_lock=""
  if [[ -f "${lock}" ]]; then
    lazy_cmd="restore"
    saved_lock="$(mktemp)"
    cp "${lock}" "${saved_lock}"
  fi
  if ! nvim --headless "+Lazy! ${lazy_cmd}" "+qa"; then
    export GIT_SSL_NO_VERIFY="${git_ssl}"
    die "Lazy sync failed. Open nvim and run :Lazy sync manually."
  fi
  # init.lua clones the newest stable lazy.nvim, and the first restore writes that commit into the
  # lockfile. Put the committed lockfile back and restore again so lazy.nvim is pinned too.
  if [[ "${lazy_cmd}" == restore ]]; then
    cp "${saved_lock}" "${lock}"
    rm -f "${saved_lock}"
    if ! nvim --headless "+Lazy! restore" "+qa"; then
      export GIT_SSL_NO_VERIFY="${git_ssl}"
      die "Lazy sync failed. Open nvim and run :Lazy sync manually."
    fi
  fi
  export GIT_SSL_NO_VERIFY="${git_ssl}"
  echo "Lazy sync finished."
}

install_language_servers() {
  echo "Installing language servers with Mason (gopls, ts_ls, angularls, jsonls, bashls, yamlls)..."
  command -v npm >/dev/null 2>&1 \
    || echo "Warning: npm not found; the TypeScript, Angular, JSON, Bash and YAML servers need Node.js and npm." >&2
  if nvim --headless -c "luafile ${SCRIPT_DIR}/tools/mason-install.lua"; then
    MASON_OK=true
  else
    MASON_OK=false
    echo "Warning: some language servers did not install. Fix the cause above, then open nvim and run :Mason." >&2
  fi
}

SHELL_PATH_LINE='export PATH="$HOME/.local/bin:$HOME/.local/go/bin:$PATH"'

# Add ~/.local/bin and ~/.local/go/bin to the shell profile once (Go and tree-sitter live there).
ensure_shell_path() {
  local rc
  case "$(basename "${SHELL:-}")" in
    zsh) rc="${HOME}/.zshrc" ;;
    bash)
      if [[ "$(uname -s)" == Darwin ]]; then rc="${HOME}/.bash_profile"; else rc="${HOME}/.bashrc"; fi
      ;;
    *)
      echo "Note: add this line to your shell profile: ${SHELL_PATH_LINE}"
      return 0
      ;;
  esac
  if [[ -f "${rc}" ]] && grep -q '\.local/go/bin' "${rc}"; then
    echo "PATH: ${rc} already has ~/.local/go/bin"
    return 0
  fi
  printf '\n# Added by davidhoang-setup/setup-neovim: Go, tree-sitter and nvim in ~/.local\n%s\n' "${SHELL_PATH_LINE}" >>"${rc}"
  echo "PATH: added ~/.local/bin and ~/.local/go/bin to ${rc} (open a new terminal to use it)"
}

SUMMARY_MISSING=0

# check_tool <label> <what needs it> <command> [other command names...]
check_tool() {
  local label="$1" purpose="$2" c
  shift 2
  for c in "$@"; do
    if command -v "${c}" >/dev/null 2>&1; then
      printf "  ok       %-12s %s\n" "${label}" "${purpose}"
      return 0
    fi
  done
  printf "  MISSING  %-12s %s\n" "${label}" "${purpose}"
  SUMMARY_MISSING=$((SUMMARY_MISSING + 1))
}

print_summary() {
  echo
  echo "Check:"
  check_tool nvim "Neovim" nvim
  check_tool git "plugins, gitsigns, Space g" git
  check_tool cc "build plugins and parsers" cc gcc clang
  check_tool make "telescope-fzf-native" make
  check_tool tree-sitter "syntax parsers" tree-sitter
  check_tool ripgrep "Space fg / fw / fG (search text)" rg
  check_tool fd "Space fd (find folder), faster Space ff" fd fdfind
  check_tool go "gopls (Go language server)" go
  check_tool node "TS / Angular / JSON / Bash / YAML servers" node
  check_tool npm "installs those servers" npm
  check_tool lazygit "Space gg" lazygit
  if command -v node >/dev/null 2>&1; then
    local node_major
    node_major="$(node --version | sed 's/^v//; s/\..*//')"
    if [[ "${node_major}" =~ ^[0-9]+$ ]] && [[ "${node_major}" -lt 18 ]]; then
      printf "  OLD      %-12s %s\n" "node" "v${node_major} is too old for the language servers; install Node 18+"
      SUMMARY_MISSING=$((SUMMARY_MISSING + 1))
    fi
  fi
  if [[ "${MASON_OK:-false}" == true ]]; then
    printf "  ok       %-12s %s\n" "Mason" "all language servers installed"
  else
    printf "  MISSING  %-12s %s\n" "Mason" "some language servers failed (open nvim, run :Mason)"
    SUMMARY_MISSING=$((SUMMARY_MISSING + 1))
  fi
  if [[ "${SUMMARY_MISSING}" -gt 0 ]]; then
    echo "${SUMMARY_MISSING} item(s) missing: the features next to them will not work until you install them."
  else
    echo "Everything is installed."
  fi
}

main() {
  install_packages
  if [[ "${SKIP_PACKAGES}" != true ]]; then
    install_go_toolchain
    install_tree_sitter_cli
  fi
  export_user_local_path
  if [[ "${SKIP_PACKAGES}" != true ]] && ! nvim_meets_min_version; then
    install_neovim_from_github_release || die "Could not install Neovim from GitHub releases."
    export_user_local_path
  fi
  require_neovim
  apply_config
  export GIT_SSL_NO_VERIFY="${GIT_SSL_NO_VERIFY:-1}"
  bootstrap_lazy
  install_language_servers
  if [[ "${SKIP_PACKAGES}" != true ]]; then
    ensure_shell_path
  fi
  print_summary
  echo "Done. Start with: nvim"
}

main "$@"
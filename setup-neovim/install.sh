#!/usr/bin/env bash
# Install Neovim (0.11+), Go toolchain, deps, and ~/.config/nvim; headless :Lazy sync.
#
# Usage:
#   ./install.sh                 # packages + Go 1.24.3 + config + Lazy sync
#   ./install.sh --skip-packages # config + Lazy sync only (Neovim 0.11+ and tooling on you)
#   ./install.sh --help

set -euo pipefail

SKIP_PACKAGES=false
for arg in "$@"; do
  case "$arg" in
    --skip-packages|--config-only) SKIP_PACKAGES=true ;;
    -h|--help)
      echo "Usage: $0 [--skip-packages|--config-only]"
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
    brew install tree-sitter
    command -v tree-sitter >/dev/null 2>&1 || die "brew install tree-sitter did not provide a tree-sitter binary on PATH."
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

install_packages_macos() {
  if nvim_meets_min_version; then
    echo "macOS: Neovim $(nvim --version | head -1) is sufficient."
  elif command -v brew >/dev/null 2>&1; then
    echo "macOS: installing Neovim and dependencies with Homebrew..."
    brew install neovim git curl ripgrep fd tree-sitter
    brew install gcc || true
  else
    echo "macOS: Homebrew not found; if Neovim is below 0.11, it will be installed from GitHub releases next."
  fi
  if ! command -v git >/dev/null 2>&1; then
    die "macOS: git is required. Install Xcode CLT or Homebrew, then re-run."
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
  echo "Installing ${NVIM_SRC} -> ${dest}"
  mkdir -p "${cfg_root}"
  rm -rf "${dest}"
  cp -a "${NVIM_SRC}" "${dest}"
}

bootstrap_lazy() {
  echo "Running headless :Lazy sync (first run may take a few minutes)..."
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
  if ! nvim --headless "+Lazy! sync" "+qa"; then
    export GIT_SSL_NO_VERIFY="${git_ssl}"
    die "Lazy sync failed. Open nvim and run :Lazy sync manually."
  fi
  export GIT_SSL_NO_VERIFY="${git_ssl}"
  echo "Lazy sync finished."
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
  echo "Done. Start with: nvim"
  echo "Tip: :Mason for LSP. Go: ${GO_INSTALL_DIR}/bin/go. tree-sitter: ~/.local/bin/tree-sitter (or Homebrew). Put ~/.local/bin on PATH for GUI Neovim."
}

main "$@"
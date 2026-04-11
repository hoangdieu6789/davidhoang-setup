# setup-zsh

Install **zsh**, **[Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)**, and the dotfiles in `files/` on a new machine. One script handles package installation (where supported), the Oh My Zsh unattended installer, copying `~/.zshrc`, optionally replacing `~/.oh-my-zsh` from a backup, and setting zsh as the login shell.

## What you get

- **`files/zshrc`** — Installed as `~/.zshrc` (robbyrussell-based prompt, git autosuggestions/syntax-highlighting plugins in the list, host banner on interactive login). Edit this file in the repo before running the installer, or after install at `~/.zshrc`.
- **`files/oh-my-zsh/`** (optional) — If this directory contains a full Oh My Zsh tree (must include `oh-my-zsh.sh`), it **replaces** `~/.oh-my-zsh` after the fresh installer run. Use this to restore a backed-up `~/.oh-my-zsh`. If the folder is missing or incomplete, the script keeps the version from the official installer.

## Requirements

- **curl** (required).
- **sudo** for: installing packages on Linux, `chsh` to set the login shell (unless you use `--skip-chsh`).
- On **macOS**: zsh and git are usually already present; if not, install [Homebrew](https://brew.sh) or Xcode Command Line Tools (`xcode-select --install`) as described by the script if it exits with an error.

## Before you run

1. **Customize dotfiles** (optional): put your `~/.zshrc` at `files/zshrc`. Optionally copy your entire `~/.oh-my-zsh` into `files/oh-my-zsh/` if you want that tree restored verbatim.
2. **Extra plugins**: The bundled `files/zshrc` lists `zsh-autosuggestions` and `zsh-syntax-highlighting`. Those are not part of the default Oh My Zsh distribution. After install, add them under the custom plugins directory (typical one-time setup):

   ```bash
   git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
   git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
   ```

   Then open a new shell or run `exec zsh -l`. If you prefer not to use them, remove those entries from the `plugins=(...)` array in `files/zshrc` before installing.

## Install

From this directory:

```bash
chmod +x install.sh
./install.sh
```

- **`./install.sh --skip-chsh`** — Do not change the login shell. Set it later with: `chsh -s "$(command -v zsh)"`.
- **`./install.sh --help`** — Short usage summary.

## Supported environments

- **Linux**: Detects common distros via `/etc/os-release` and uses **apt**, **dnf**/**yum**, **pacman**, or **zypper** for `zsh`, `git`, and `ca-certificates` where applicable. Unknown IDs that declare `ID_LIKE=debian` or `rhel` get a best-effort install; others need manual `zsh` + `git` then a re-run.
- **macOS**: Uses existing zsh/git or installs via Homebrew if needed.

## Security note (TLS)

During install only, the script sets **`GIT_SSL_NO_VERIFY=1`** and uses **`curl -k`** when fetching Oh My Zsh so clones/downloads can succeed on networks with TLS inspection. Prefer a trusted network; remove or avoid relying on this if you do not need it.

## After install

Open a new terminal or run:

```bash
exec zsh -l
```

If login shell was skipped, start zsh manually or run `chsh` as above when you are ready.

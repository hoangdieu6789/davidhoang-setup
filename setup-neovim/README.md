# setup-neovim

One-shot **Neovim 0.11+** setup for **Go** and **Angular** (TypeScript/HTML) work: copies a small [lazy.nvim](https://github.com/folke/lazy.nvim) config, then runs a headless **`:Lazy sync`** so plugins are ready on first launch. **0.11+** matches current **nvim-lspconfig** expectations (support for Nvim 0.10 and older is deprecated and will be removed in nvim-lspconfig v3).

## How to use

### Quick start (full install)

From **`setup-neovim/`** on a machine where you can install packages (**`sudo`** on Linux, or **Homebrew** on macOS):

```bash
cd setup-neovim
chmod +x install.sh tools/check-neovim.sh
./install.sh
```

This **replaces** **`~/.config/nvim`** with the bundled **`files/nvim`** tree and runs **`:Lazy sync`** in headless mode. First run can take several minutes (plugin clone + Tree-sitter parser compiles).

### Set `PATH` for terminals and GUI apps

The installer puts binaries under your home directory. Add them to **`PATH`** in **`~/.profile`**, **`~/.zshrc`**, or your desktop session environment so **terminals, IDEs, and GUI-launched Neovim** all see the same tools:

```bash
export PATH="$HOME/.local/bin:$HOME/.local/go/bin:$PATH"
```

| Location | Contents (after full install) |
| --- | --- |
| **`~/.local/bin`** | **`tree-sitter`** (Linux: GitHub CLI zip; macOS: often **Homebrew**), **`nvim`** symlink when the script installs Neovim from [GitHub releases](https://github.com/neovim/neovim/releases) |
| **`~/.local/go/bin`** | **`go`** when the script installs **Go 1.24.3** |

The bundled **`init.lua`** prepends **`~/.local/bin`** and **`~/.local/go/bin`** to **`vim.env.PATH`** *before* **lazy.nvim** runs. That way **`:TSUpdate`** / nvim-treesitter can find **`tree-sitter`** during **`:Lazy sync`**, even when the parent shell had a minimal **`PATH`**. You should still export **`PATH`** in your shell profile for **Mason**, **terminals**, and **GUI** parity.

### Config only (no packages / no downloads)

When you already have Neovim **0.11+**, a C compiler, **`tree-sitter`**, **`go`**, **`git`**, and **`curl`**:

```bash
./install.sh --skip-packages
```

**`--config-only`** is the same flag. This mode only copies config and runs **`:Lazy sync`**; it does **not** run **`apt`/`brew`**, does **not** install Go or the tree-sitter CLI, and does **not** upgrade Neovim from GitHub.

### After installation

1. Run **`nvim`**.
2. Open **`:Mason`** and let **`gopls`**, **`typescript-language-server`**, and **`angular-language-server`** finish if you use those stacks (**`go`** must be on **`PATH`** for Go-related Mason packages).
3. If highlights or parsers fail: **`:checkhealth nvim-treesitter`** and confirm **`:!which tree-sitter`** inside Neovim.

### Verify with `check-neovim.sh`

```bash
./tools/check-neovim.sh
```

Checks that **`nvim`** is on **`PATH`**, satisfies the **0.11+** policy, that **`init.lua`** exists under **`$XDG_CONFIG_HOME/nvim`**, and that Neovim can start headlessly.

### Updating the config from this repo

Change **`files/nvim`** in git, then re-run **`./install.sh`** or **`./install.sh --skip-packages`**. The script deletes the previous **`~/.config/nvim`** and copies **`files/nvim`** again—keep a backup if you have local edits you need to merge.

## What you get

- **Plugin manager**: `lazy.nvim`
- **LSP**: [Mason](https://github.com/mason-org/mason.nvim) + [mason-lspconfig](https://github.com/mason-org/mason-lspconfig.nvim) + [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), with **gopls**, **ts_ls** (TypeScript, Mason package `typescript-language-server`), and **angularls** queued for install
- **Completion**: `nvim-cmp` + `LuaSnip`
- **Syntax**: Tree-sitter (Go modules, TypeScript/TSX, HTML, CSS, JSON, …)
- **UI**: Tokyo Night, Telescope, Which Key
- **Quality-of-life**: LSP format on save when the active server supports formatting, diagnostics shortcuts, common LSP keymaps

## Requirements

- **sudo** (Linux) or **Homebrew** (macOS) for installing Neovim and build tools unless you use **`--skip-packages`**
- **git** and **curl** (the installer clones lazy.nvim and plugins; Mason uses **curl** for the registry)
- **A C compiler** (`build-essential` / Xcode CLT / `gcc`) for nvim-treesitter **1.x** (`tree-sitter build` compiles parsers)
- **tree-sitter CLI** (0.26.1+) on **`PATH`** for parser installs. With a **full** **`./install.sh`**: macOS + Homebrew installs **`tree-sitter`** via **Homebrew**; Linux downloads the official [tree-sitter releases](https://github.com/tree-sitter/tree-sitter/releases) zip into **`~/.local/bin`**. **`unzip`** is installed where the script manages OS packages.
- **Go [1.24.3](https://go.dev/dl/)** on **`PATH`** if you use Mason for **gopls**, **gotests**, **golines**, etc. A full **`./install.sh`** downloads **`go1.24.3.<platform>.tar.gz`** from **`https://dl.google.com/go/`** and the matching **`.sha256`** file from the same host (checksums are verified; **`go.dev/dl/*.sha256`** URLs are HTML, so they are not used).

## Install commands (reference)

| Command | When to use |
| --- | --- |
| **`./install.sh`** | Default: OS packages, **Go** into **`~/.local/go`**, **tree-sitter** into **`~/.local/bin`** (or Homebrew on macOS), **Neovim 0.11+** from GitHub if the system **`nvim`** is too old, then config + headless **`:Lazy sync`**. |
| **`./install.sh --skip-packages`** | Same as **`--config-only`**: copy **`files/nvim`** → **`~/.config/nvim`** and **`:Lazy sync`** only. |

Config is installed to **`${XDG_CONFIG_HOME:-$HOME/.config}/nvim`**.

Implementation notes: **`lua/config/mason.lua`** centralizes Mason package names and LSP server ids. **`install.sh`** uses **`resolve_platform()`** for Go and Neovim artifacts, **`DEBIAN_FRONTEND=noninteractive`** and quiet **`apt`** where applicable, **`trap`**-cleaned temp directories, and **`export_user_local_path()`** to avoid duplicating **`PATH`** entries. **`bootstrap_lazy()`** exports **`~/.local/bin`** and **`~/.local/go/bin`** before headless **`nvim`** and fails a full install if **`tree-sitter`** is still missing.

## After install (projects)

1. In a **Go** repo, ensure **`go mod`** is initialized so **gopls** can attach.
2. In an **Angular** workspace, open the project root so **angularls** / **ts_ls** find **`tsconfig`** / **`angular.json`**.

### Mason registry (LSP packages will not install)

This config **does not** use mason-lspconfig’s **`ensure_installed`** (that list depends on a registry-derived map that can be empty and wrongly reject **`gopls`**). It installs **Mason packages by name**: `gopls`, `typescript-language-server`, `angular-language-server`, which map to LSP configs **`gopls`**, **`ts_ls`**, **`angularls`**.

If installs still fail, run **`:MasonUpdate`**, check **`:checkhealth mason`**, and ensure **`curl`** works. As a last resort, remove **`~/.local/share/nvim/mason/registries`** and restart Neovim so the registry is downloaded again.

#### “Failed to download registry archive” (GitHubRegistrySource …)

Mason pulls **`mason-org/mason-registry`** from GitHub: it calls the **GitHub API** to resolve the latest release tag, then **`curl`** downloads **`registry.json.zip`** (and checksums) from **GitHub Releases**. If any step fails, you see this error.

Work through these **from the same environment you use to run Neovim** (e.g. WSL, not only Windows):

1. **Test downloads** (should create a non-empty file):

   ```bash
   curl -fL --connect-timeout 30 \
     -o /tmp/mason-registry.json.zip \
     "https://github.com/mason-org/mason-registry/releases/latest/download/registry.json.zip"
   ls -l /tmp/mason-registry.json.zip
   ```

   If this fails, fix **network / DNS / firewall / VPN** before Mason can work.

2. **HTTP proxy** — if you need a proxy, set it for the shell that launches Neovim, e.g. `export https_proxy=...` and `export http_proxy=...` (Mason’s `curl` picks these up).

3. **TLS inspection** — Mason uses **`curl -fsSL`** (no insecure mode). Install your corporate **root CA** into the system trust store (or point **`SSL_CERT_FILE`** at a bundle `curl` trusts). This repo’s install script uses relaxed Git **TLS** for plugins only; Mason does not.

4. **GitHub API limits** — install **[GitHub CLI](https://cli.github.com/)** and run **`gh auth login`**. Mason’s provider stack can use **`gh api`** for GitHub, which avoids anonymous API throttling.

5. **Pin a registry tag** — avoids the “fetch latest release” API call. Open [mason-registry releases](https://github.com/mason-org/mason-registry/releases), copy the **tag** name (e.g. `2026-04-11-witty-school`), then in **`lua/plugins/lsp.lua`** pass **`registries`** into **`mason.setup`**:

   ```lua
   require("mason").setup({
     ui = { border = "rounded" },
     registries = { "github:mason-org/mason-registry@YOUR_TAG_HERE" },
   })
   ```

   Replace **`YOUR_TAG_HERE`** with the tag you copied (no extra `v` unless the tag includes it).

6. **Offline / file registry** — advanced: clone [mason-registry](https://github.com/mason-org/mason-registry), install **`yq`**, and use a **`file:`** registry; see **`:h mason-registries`** in Neovim.

### TLS note

Like `setup-zsh`, the installer sets **`GIT_SSL_NO_VERIFY=1`** during the headless **`:Lazy sync`** step so clones can succeed on networks with TLS inspection. Prefer a trusted network.

## Supported environments

- **Linux**: Same distro families as `setup-zsh` (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE) via `apt` / `dnf` / `pacman` / `zypper`
- **macOS**: Homebrew when Neovim is missing or too old

If your distro ships Neovim **older than 0.11**, you can either:

- Run **`./install.sh`** without **`--skip-packages`**: the script installs distro packages first, then **downloads the latest stable Neovim** from [GitHub releases](https://github.com/neovim/neovim/releases) into **`~/.local/`** and symlinks **`~/.local/bin/nvim`**. Put **`~/.local/bin`** early on your **`PATH`** (many distros already do for login shells).
- **Ubuntu**: use the [Neovim PPA](https://launchpad.net/~neovim-ppa/+archive/ubuntu/stable) so **`apt`** upgrades the system **`nvim`** (no `PATH` juggling). Example (you used **unstable**; **`stable`** is an option if it meets 0.11+ on your release):

  ```bash
  sudo add-apt-repository ppa:neovim-ppa/unstable
  sudo apt update
  sudo apt install neovim
  ```

On macOS, **Homebrew** is preferred when available.

## Keymaps (reference)

| Key | Action |
| --- | --- |
| `<leader>ff` | Telescope find files |
| `<leader>fg` | Telescope live grep |
| `<leader>fb` | Telescope buffers |
| `gd` / `gr` / `K` | LSP definition / references / hover |
| `<leader>rn` | LSP rename |
| `<leader>ca` | LSP code action |
| `<leader>f` | Format buffer (LSP) |
| `[d` / `]d` | Previous / next diagnostic |

Leader is **space** (`<leader>`).

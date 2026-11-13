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

On a new machine, install these first (the script cannot do it for you): **Homebrew** ([brew.sh](https://brew.sh)) and **Xcode Command Line Tools** (`xcode-select --install`) on macOS, or **`sudo`** rights on Linux. Then one run of the script does the rest:

| Step | What it does |
| --- | --- |
| Tools | Installs what is missing: Neovim 0.11+, git, curl, ripgrep, fd, lazygit, Node.js + npm (Homebrew on macOS; apt / dnf / pacman / zypper on Linux, best effort for lazygit and Node) |
| Go + tree-sitter | Go 1.24.3 into **`~/.local/go`**, tree-sitter CLI (Homebrew **`tree-sitter-cli`** or **`~/.local/bin`**) |
| Config | Copies or links (**`--link`**) **`files/nvim`** to **`~/.config/nvim`** |
| Plugins | Installs the plugin versions from **`lazy-lock.json`** and compiles the Tree-sitter parsers |
| Language servers | Installs all Mason packages from **`lua/config/mason.lua`** (language servers + **markdownlint-cli2**) and waits until they are done (**`tools/mason-install.lua`**), so **`gd`** / **`gr`** and Markdown lint work on first launch |
| PATH | Adds **`export PATH="$HOME/.local/bin:$HOME/.local/go/bin:$PATH"`** to **`~/.zshrc`** (or **`~/.bashrc`** / **`~/.bash_profile`**) once |
| Check | Prints **ok** / **MISSING** for every tool, with the feature that needs it |

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

**`--config-only`** is the same flag. This mode copies or links the config, installs plugins and language servers, and prints the check list. It does **not** run **`apt`/`brew`**, does **not** install Go or the tree-sitter CLI, does **not** upgrade Neovim from GitHub, and does **not** change your shell profile.

### After installation

1. Read the check list at the end of the script output and install anything marked **MISSING**, then re-run the script.
2. Open a new terminal (so the new **`PATH`** is used) and run **`nvim`**. Language servers are already installed; **`:Mason`** shows them.
3. If highlights or parsers fail: **`:checkhealth nvim-treesitter`** and confirm **`:!which tree-sitter`** inside Neovim.

### Keep several machines in sync (`--link`)

Add **`--link`** to make **`~/.config/nvim`** a symlink to **`files/nvim`** in this repo instead of a copy:

```bash
git clone git@github.com:hoangdieu6789/davidhoang-setup.git ~/WorkSpace/davidhoang-setup
cd ~/WorkSpace/davidhoang-setup/setup-neovim
./install.sh --skip-packages --link
```

An existing **`~/.config/nvim`** folder is moved to **`~/.config/nvim.bak.<timestamp>`** first. After that:

- Edits to the config (and **`lazy-lock.json`**, which Lazy updates on **`:Lazy update`**) land in the repo. Commit and push them.
- On the other machines run **`git pull`**, then **`:Lazy restore`** in Neovim to install the plugin versions from **`lazy-lock.json`**.

### Verify with `check-neovim.sh`

```bash
./tools/check-neovim.sh
```

Checks that **`nvim`** is on **`PATH`**, satisfies the **0.11+** policy, that **`init.lua`** exists under **`$XDG_CONFIG_HOME/nvim`**, and that Neovim can start headlessly.

### Updating the config from this repo

Change **`files/nvim`** in git, then re-run **`./install.sh`** or **`./install.sh --skip-packages`**. The script deletes the previous **`~/.config/nvim`** and copies **`files/nvim`** again—keep a backup if you have local edits you need to merge. With **`--link`** there is nothing to re-run: **`git pull`** is enough.

## What you get

- **Plugin manager**: `lazy.nvim`
- **LSP**: [Mason](https://github.com/mason-org/mason.nvim) + [mason-lspconfig](https://github.com/mason-org/mason-lspconfig.nvim) + [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), with **gopls**, **ts_ls**, **angularls**, **jsonls**, **bashls**, and **yamlls** queued for install (see **`lua/config/mason.lua`** for Mason package names)
- **Completion**: `nvim-cmp` + `LuaSnip`
- **Syntax**: Tree-sitter (Go modules, TypeScript/TSX, HTML, CSS, JSON/JSONC, YAML, Bash, …)
- **UI**: Tokyo Night, Telescope, [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua), Which Key
- **Quality-of-life**: LSP format on save when the active server supports formatting, diagnostics shortcuts, common LSP keymaps
- **Git**: gitsigns (hunks, blame), git-conflict, [lazygit.nvim](https://github.com/kdheepak/lazygit.nvim) (needs the `lazygit` program), [diffview.nvim](https://github.com/sindrets/diffview.nvim)
- **Lint**: [nvim-lint](https://github.com/mfussenegger/nvim-lint) runs [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) on Markdown files when you open, save, or leave insert mode (`<leader>l` runs it now). Problems show as normal diagnostics. To change the rules, add a **`.markdownlint-cli2.yaml`** (or **`.markdownlint.json`**) to the project, e.g. `config: { MD013: false }` to turn off the line-length rule
- **Terminal**: [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) (`Ctrl-\`, `<leader>T`)
- **Tests**: [Neotest](https://github.com/nvim-neotest/neotest) + [neotest-go](https://github.com/nvim-neotest/neotest-go) (`go test` from the editor; Tree-sitter **go** parser + **`go`** on **PATH**)

## Requirements

- **sudo** (Linux) or **Homebrew** + **Xcode Command Line Tools** (macOS) for installing Neovim and tools unless you use **`--skip-packages`**
- **Node.js 18+** and **npm** for the TypeScript, Angular, JSON, Bash and YAML language servers (a full install adds them when missing)
- **git** and **curl** (the installer clones lazy.nvim and plugins; Mason uses **curl** for the registry)
- **A C compiler** (`build-essential` / Xcode CLT / `gcc`) for nvim-treesitter **1.x** (`tree-sitter build` compiles parsers)
- **tree-sitter CLI** (0.26.1+) on **`PATH`** for parser installs. With a **full** **`./install.sh`**: macOS + Homebrew installs the **`tree-sitter-cli`** formula (the **`tree-sitter`** formula is only the library); Linux downloads the official [tree-sitter releases](https://github.com/tree-sitter/tree-sitter/releases) zip into **`~/.local/bin`**. **`unzip`** is installed where the script manages OS packages.
- **Go [1.24.3](https://go.dev/dl/)** on **`PATH`** if you use Mason for **gopls**, **gotests**, **golines**, etc. A full **`./install.sh`** downloads **`go1.24.3.<platform>.tar.gz`** from **`https://dl.google.com/go/`** and the matching **`.sha256`** file from the same host (checksums are verified; **`go.dev/dl/*.sha256`** URLs are HTML, so they are not used).

## Install commands (reference)

| Command | When to use |
| --- | --- |
| **`./install.sh`** | Default: missing tools (ripgrep, fd, lazygit, Node.js, …), **Go** into **`~/.local/go`**, **tree-sitter** CLI, **Neovim 0.11+** if the system **`nvim`** is too old, config, plugins, language servers, **`PATH`** in your shell profile, then the check list. |
| **`./install.sh --skip-packages`** | Same as **`--config-only`**: config, plugins, language servers and the check list only. |
| **`--link`** | Add to either command: symlink **`~/.config/nvim`** to this repo instead of copying (see above). |

Config is installed to **`${XDG_CONFIG_HOME:-$HOME/.config}/nvim`**.

Implementation notes: **`lua/config/mason.lua`** centralizes Mason package names and LSP server ids. **`install.sh`** uses **`resolve_platform()`** for Go and Neovim artifacts, **`DEBIAN_FRONTEND=noninteractive`** and quiet **`apt`** where applicable, **`trap`**-cleaned temp directories, and **`export_user_local_path()`** to avoid duplicating **`PATH`** entries. **`bootstrap_lazy()`** exports **`~/.local/bin`** and **`~/.local/go/bin`** before headless **`nvim`** and fails a full install if **`tree-sitter`** is still missing.

## After install (projects)

1. In a **Go** repo, ensure **`go mod`** is initialized so **gopls** can attach.
2. In an **Angular** workspace, open the project root so **angularls** / **ts_ls** find **`tsconfig`** / **`angular.json`**.

### Mason registry (LSP packages will not install)

This config **does not** use mason-lspconfig’s **`ensure_installed`** (that list depends on a registry-derived map that can be empty and wrongly reject **`gopls`**). It installs **Mason packages by name** (see **`lua/config/mason.lua`**), e.g. **`gopls`**, **`typescript-language-server`**, **`angular-language-server`**, **`json-lsp`**, **`bash-language-server`**, **`yaml-language-server`**, mapped to **`gopls`**, **`ts_ls`**, **`angularls`**, **`jsonls`**, **`bashls`**, **`yamlls`**.

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

## Practice games (vim-be-good)

[vim-be-good](https://github.com/ThePrimeagen/vim-be-good) is included (`lua/plugins/games.lua`). It loads only when you run it.

1. Open Neovim and run **`:VimBeGood`**.
2. Pick a game and a difficulty by **deleting** its line with `dd` (that is the first exercise).
3. Games: `words`, `ci{`, `relative`, `hjkl`, `whackamole`, `snake`, `random`. Quit with `:q`.

Tip: 10 minutes a day. Start with `hjkl` and `relative` on **easy**, then `words` and `ci{`.
New to Vim? Run **`:Tutor`** first (built in, about 30 minutes).

## Keymaps (reference)

| Key | Action |
| --- | --- |
| `<leader>ff` | Telescope find files |
| `<leader>fg` | Telescope live grep |
| `<leader>fb` | Telescope buffers |
| `<leader>fw` | Search the project for the word under the cursor |
| `<leader>fr` | Reopen the last Telescope search |
| `<leader>fo` | Recent files |
| `<leader>/` | Search inside the current file |
| `<leader>fd` | Find a folder by name and show it in nvim-tree |
| `<leader>fG` | Live grep inside one folder (asks for the folder first) |
| `Ctrl-\` | Toggle a terminal at the bottom (works in normal, insert and terminal mode) |
| `<leader>Tf` / `<leader>Tv` / `<leader>Th` | Terminal: floating / right / bottom |
| `Esc Esc`, `Ctrl-h/j/k/l` (in a toggleterm terminal) | Leave typing mode, move to another window |
| `<leader>gg` | LazyGit (status, stage, commit, push, pull, branches) |
| `<leader>gs` / `<leader>gc` / `<leader>gf` / `<leader>gb` | Telescope git status / commits / commits of this file / branches |
| `<leader>gd` / `<leader>gh` / `<leader>gq` | Diffview: all changes / history of this file / close |
| `]c` / `[c`, `<leader>hp` / `hs` / `hS` / `hr` / `hb` | Gitsigns: next / previous hunk, preview / stage / stage file / reset / blame |
| `co` / `ct` / `cb` / `c0`, `]x` / `[x` | git-conflict: ours / theirs / both / none, next / previous conflict |
| `<leader>e` | Toggle nvim-tree file explorer |
| `Ctrl-h` / `Ctrl-j` / `Ctrl-k` / `Ctrl-l` | Go to the window left / below / above / right |
| `<leader>sv` / `<leader>sh` | Split vertical / horizontal |
| `<leader>sx` / `<leader>so` | Close this split / close other splits |
| `<leader>se` / `<leader>sm` | Make splits equal size / maximize this split |
| `<leader>tn` | Neotest: run nearest test |
| `<leader>tf` | Neotest: run tests in file |
| `<leader>ta` | Neotest: run suite (`go test` from cwd) |
| `<leader>ts` | Neotest: toggle summary |
| `<leader>to` | Neotest: open output |
| `<leader>tS` | Neotest: stop run |
| `gd` / `gr` / `K` | LSP definition / references (Telescope list with preview) / hover |
| `<leader>rn` | LSP rename |
| `<leader>ca` | LSP code action |
| `<leader>f` | Format buffer (LSP) |
| `<leader>l` | Lint this file now (markdownlint-cli2 for Markdown) |
| `[d` / `]d` | Previous / next diagnostic |

Leader is **space** (`<leader>`).

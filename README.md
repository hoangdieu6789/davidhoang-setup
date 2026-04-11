# davidhoang-setup

Personal setup scripts and notes for tools I use on more than one machine. The aim is to keep installs **repeatable across macOS and Linux**, and to add **Windows** support where it is practical (often via WSL or the same tools’ native Windows installers).

## Goals

- **Cross-OS setup** — Automate or document installation so a new Mac, Linux box, or (when possible) Windows environment gets the same baseline.
- **Light guidance per tool** — Each major piece lives in its own folder with a short `README.md`: what it does, prerequisites, how to run it, and anything OS-specific.

## What is here now

| Folder       | What it sets up | Guidance |
| ------------ | --------------- | -------- |
| [`setup-zsh/`](setup-zsh/) | zsh, Oh My Zsh, and bundled `~/.zshrc` (plus optional `~/.oh-my-zsh` backup) | [setup-zsh/README.md](setup-zsh/README.md) |

## Adding another tool

Create a directory (for example `setup-foo/`), put install scripts or config templates there, and add a `README.md` with usage and platform notes. Link it from the table above so this file stays the map of the repo.

## Platform notes

- **macOS / Linux** — Most shell- and package-manager-based setups target these first.
- **Windows** — Native Windows may use different paths or package managers (winget, Chocolatey, Scoop). **WSL** often lets you reuse Linux-style scripts; call that out in each tool’s README when it applies.

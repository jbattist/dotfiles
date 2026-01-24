# Dotfiles

My personal dotfiles for Arch Linux, managed with GNU Stow and custom installation scripts.

## Overview

This repository contains my configuration files for various tools and the scripts to set up a fresh Arch Linux installation. It is built around a workflow using `yay` for package management and `stow` for symlinking configurations.

## Prerequisites

- **OS**: Arch Linux (or an Arch-based distribution).
- **Core Tools**: `git`, `base-devel`.

## Installation

The installation process is split into three steps:

### 1. Shell Setup
Sets up Zsh as the default shell and installs shell-related tools (Starship, fzf, etc.).
```bash
./1-install-shell.sh
```
*Note: This script handles installing `yay` if it's missing.*

### 2. Package Installation
Installs the bulk of the user software stack, including GUI applications and fonts.
```bash
./2-install-pkgs.sh
```

### 3. Dotfiles Linking
Links the remaining configuration files (Niri, Plasma, etc.) to their appropriate locations using GNU Stow.
```bash
./3-install-dots.sh
```

## Structure

- **Scripts**:
  - `1-install-shell.sh`: Core shell environment setup (Zsh, Starship).
  - `2-install-pkgs.sh`: Main package installation script (browsers, editors, GUI tools).
  - `3-install-dots.sh`: Links config files for desktop environments and apps.

- **Configurations**:
  - `zshrc/`: Zsh configuration.
  - `starship/`: Starship prompt config.
  - `fastfetch/`: System information fetcher config.
  - `ghostty/`: Terminal emulator config.
  - `niri/`: Scrollable-tiling Wayland compositor config.
  - `noctalia/`: Custom shell/UI components.
  - `fuzzel/`: Application launcher config.
  - `plasma/`: KDE Plasma specific configurations.
  - `wallpapers/`: Collection of wallpapers.

## Software Stack

Key components of this setup include:

- **Shell**: Zsh + Starship
- **Terminal**: Ghostty
- **Window Manager**: Niri (Wayland) / KDE Plasma
- **Launcher**: Fuzzel
- **Editor**: Obsidian, Visual Studio Code (optional)
- **Browser**: Firefox

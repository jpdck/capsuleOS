# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a macOS development environment bootstrap repository that automates the setup from a bare macOS system to a fully configured development environment using Homebrew.

## Key Components

### Core Files

- `Brewfile` - Comprehensive package definitions for CLI tools, development languages, GUI apps, and fonts
- `install.sh` - Automated bootstrap script that handles the complete setup process
- `dotfiles/` - Configuration files managed with GNU Stow, organized by package (zsh, git, helix, etc.)

### Installation Process

The `install.sh` script runs through 8 phases:

1. System Prerequisites (Xcode tools, Homebrew)
2. Package Installation (from Brewfile)
3. 1Password Integration (SSH key management)
4. Repository Setup (clones capsuleOS repo)
5. Dotfiles Setup (GNU Stow deployment)
6. macOS Configuration (system preferences)
7. App Store Installation (using `mas`)
8. Language-Specific Tools (Rust, Python packages)

## Common Development Commands

### Package Management

```bash
# Install all packages from Brewfile
brew bundle install

# Update packages
brew update && brew upgrade

# Check for issues
brew doctor

# Clean up old versions
brew cleanup
```

### Dotfiles Management

```bash
# From dotfiles/ directory
stow package-name    # Install/update dotfiles for a specific package
stow -D package-name # Remove dotfiles for a package
stow -R package-name # Restow (remove and install)
```

### Initial Setup

```bash
# Run complete bootstrap (from repository root)
./install.sh

# Manual package installation only
brew bundle install
```

## Architecture Notes

### Package Organization in Brewfile

- **CLI Tools & Development Environment** - Core command-line utilities, shell enhancements
- **Language Toolchains** - Rust, Go, Python, Java with associated tools
- **Container & DevOps Tools** - Docker, Colima for macOS
- **Security & Password Management** - 1Password CLI integration
- **GUI Applications (Casks)** - Development tools, productivity apps, media tools

### Dotfiles Structure

Each package in `dotfiles/` contains configuration files that are symlinked using GNU Stow:

- `zsh/` - Shell configuration with autosuggestions and syntax highlighting
- `git/` - Git configuration and aliases
- `helix/` - Modern editor configuration
- `starship/` - Cross-shell prompt configuration
- `bash/`, `gitkraken/` - Additional tool configurations

### 1Password Integration

The setup script integrates with 1Password for SSH key management:

- Fetches SSH keys from "ZettoSenshi" vault
- Adds keys to local system and SSH agent
- Stores service token in shell configuration

## Development Environment Features

### Installed Languages & Tools

- **Rust** - Full toolchain with cargo, rust-analyzer, additional cargo tools
- **Go** - Compiler, language server (gopls), debugger (delve), linter, live reload
- **Python** - Python 3.14, ruff (linter/formatter), mypy (type checking)
- **Java** - OpenJDK 17, Gradle, Maven
- **Language Servers** - For YAML, Bash, Markdown, Dockerfile

### Key Development Tools

- **Editors** - Helix (primary), VS Code
- **Terminal** - Warp, enhanced with starship prompt
- **Git** - CLI, delta diff viewer, lazygit TUI, GitKraken GUI
- **Containers** - Docker, docker-compose, Colima (macOS Docker runtime)

## Maintenance Notes

- The repository logs installation progress to `install.log`
- System preferences are applied automatically but can be skipped
- Failed package installations don't stop the overall process
- SSH keys are managed through 1Password vault integration
- All configurations use modern alternatives (eza vs ls, bat vs cat, ripgrep vs grep)

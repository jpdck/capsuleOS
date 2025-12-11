# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Critical Instructions

### Amber Language Files

Amber file extensions: *.amber, *.ab

When working with ANY Amber language files in this repository, you must follow these requirements:

- **Documentation Reference**: Always reference the [Amber Language Documentation](https://github.com/amber-lang/amber-docs) when editing `.amber` or `.ab` files
- **Validation**: The amber script must pass `amber check` without errors before committing
- **Compilation**: Use `amber build` to compile Amber scripts to Bash when needed

#### Available Amber Commands

```text
Usage: amber [OPTIONS] [INPUT] [ARGS]... [COMMAND]

Commands:
  eval        Execute Amber code fragment
  run         Execute Amber script
  check       Check Amber script for errors
  build       Compile Amber script to Bash
  docs        Generate Amber script documentation
  completion  Generate Bash completion script
  help        Print this message or the help of the given subcommand(s)
```

#### Development Workflow for Amber Files

1. **Edit**: Modify the `.amber` or `.ab` source files in `Scripts/`
2. **Check**: Run `amber check <file.amber>` or `amber check <file.ab>` to validate syntax and logic
3. **Test**: Use `amber test <file.amber>` or `amber test <file.ab>` to test functionality
4. **Build**: Compile with `amber build <file.amber>` or `amber build <file.ab>` to generate Bash scripts
5. **Deploy**: The compiled Bash scripts are used in the installation process

## Repository Overview

This is a macOS development environment bootstrap repository that automates the setup from a bare macOS system to a fully configured development environment using Homebrew.

## Key Components

### Core Files

- `Brewfile` - Comprehensive package definitions for CLI tools, development languages, GUI apps, and fonts
- `Cargofile` - Rust crate definitions for development tools and utilities (installed via `cargo install`)
- `install.sh` - Legacy automated bootstrap script
- `installer.amber` - New installer source code written in Amber language
- `installer.sh` - Compiled Bash script generated from `installer.amber`
- `dotfiles/` - Configuration files managed with GNU Stow, organized by package

### Installation Process

The repository is transitioning to an Amber-based installer (`installer.amber` -> `installer.sh`).

The legacy `install.sh` script runs through 8 phases:

1. System Prerequisites (Xcode tools, Homebrew)
2. Package Installation (from Brewfile)
3. 1Password Integration (SSH key management)
4. Repository Setup (clones capsuleOS repo)
5. Dotfiles Setup (GNU Stow deployment)
6. macOS Configuration (system preferences)
7. App Store Installation (using `mas`)
8. Language-Specific Tools (Rust, Python packages)

The new `installer.sh` (compiled from `installer.amber`) provides a more structured approach with better logging and error handling. It currently covers:
1. macOS Environment Setup
2. Homebrew Package Installation
3. 1Password Integration

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

- **Shell & Terminal**: `zsh`, `bash`, `starship`, `conda`
- **Development Tools**: `git`, `gh` (GitHub CLI), `gitkraken`, `docker`
- **Editors**: `helix`
- **System & Security**: `ssh`, `claude`

### 1Password Integration

The setup script integrates with 1Password for SSH key management:

- Fetches SSH keys from "ZettoSenshi" vault
- Adds keys to local system and SSH agent
- Stores service token in shell configuration

## Development Environment Features

### Installed Languages & Tools

- **Rust** - Full toolchain with cargo, rust-analyzer. Additional tools defined in `Cargofile` (e.g., `cargo-edit`, `bacon`, `clippy`).
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

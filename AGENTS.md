# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Critical Instructions

### Amber Language Files

Amber file extensions: .amber, .ab

When working with ANY Amber language files in this repository, you must follow these requirements:

- **Documentation Reference**: Always reference the [Amber Language Documentation](https://github.com/amber-lang/amber-docs) when editing `.amber` or `.ab` files
- **Validation**: The amber script must pass `amber check` without errors before committing
- **Compilation**: `install.sh` is auto-built by CI/CD; local builds are for testing only (output is gitignored)
- **Warning**: Running Amber files or compiled scripts directly affects your system. This installer is designed for fresh macOS setups.

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

1. **Edit**: Modify the `.ab` source files in `Scripts/` directory
   - `Scripts/installer.ab` - Main installer logic
   - `Scripts/installer_utils.ab` - Shared utility functions
2. **Check**: Run `amber check Scripts/installer.ab` to validate syntax and logic
3. **Commit**: Commit only the `.ab` source files (installer.sh is gitignored)
4. **CI/CD**: GitHub Actions automatically builds `install.sh` on:
   - Pull requests to `main` - validates and creates artifact
   - Release tags (`v*.*`) - builds and attaches to GitHub release
5. **Distribution**: Users download `install.sh` from GitHub releases, not from the repository

**Local Development**: You can build locally with `cd Scripts && amber build installer.ab` for testing, but the output is gitignored and not committed.

### Development Notes

- **Logging Philosophy**: Terminal output is the source of truth for installation progress. No separate log file is created. Users who need logs can use `bash install.sh 2>&1 | tee install.log`.
- **Error Handling**: Uses inline `failed(code) { error(msg); exit code }` pattern for clarity in an alpha language.
- **UX Elements**: Sleep delays in stage headers are intentional - they give users time to read warnings before terminal scrolls.
- **Directory Operations**: Uses `dir_exists` + `dir_create` (Amber idiom) rather than `mkdir -p` for explicit intent and better debugging.
- **Silent vs Trust**: Commands with `silent` still have `failed` blocks with meaningful warnings. Commands with `trust` truly don't care about failure (e.g., deleting non-existent keychain entries).

## Repository Overview

This is a macOS development environment bootstrap repository that automates the setup from a bare macOS system to a fully configured development environment using Homebrew.

## Key Components

### Core Files

- `Brewfile` - Comprehensive package definitions for CLI tools, development languages, GUI apps, and fonts
- `Cargofile` - Rust crate definitions for development tools and utilities (installed via `cargo install`)
- `Scripts/installer.ab` - Main installer source code written in Amber language
- `Scripts/installer_utils.ab` - Shared utility functions for the installer (imported by installer.ab)
- `Scripts/update-tools-launchagent.plist.template` - LaunchAgent template for periodic tool updates
  - When editing, ensure to run the launchd linter: `plutil -lint <file>`
- `install.sh` - **Gitignored**; built by CI/CD and distributed via GitHub releases only
- `dotfiles/` - Configuration files managed with GNU Stow, organized by package

### Installation Process

The installer is written in Amber (`Scripts/installer.ab` + `Scripts/installer_utils.ab`) and compiled to Bash (`install.sh` at repo root).

**Installation Phases:**

1. **macOS Environment Setup** - Installs/updates Xcode Command Line Tools and Homebrew
2. **Homebrew Package Installation** - Bundles packages from Brewfile
3. **1Password Integration** - Connects to 1Password and imports SSH keys from vault
4. **Repository Cloning** - Clones capsuleOS to `~/Projects/capsuleOS`
5. **macOS Defaults Configuration** - Applies system preferences (optional)
6. **Dotfiles Deployment** - Symlinks dotfiles using GNU Stow
7. **Programming Language Tools Installation** - Installs Rust crates from Cargofile
8. **Verification & Cleanup** - Confirms installation and removes temporary files

**Build Process (CI/CD):**

```bash
cd Scripts
amber build installer.ab ../install.sh --minify
```

This compiles `installer.ab` to `install.sh` at the repository root with minification. The compiled script is portable and can run on any macOS system without Amber installed. GitHub Actions automatically builds and attaches `install.sh` to releases.

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

- Prompts for your 1Password vault name
- Fetches SSH keys from the configured vault
- Adds keys to local system and SSH agent
- Stores service token in shell configuration

## Development Environment Features

### Installed Languages & Tools

- **Rust** - Full toolchain with cargo, rust-analyzer. Additional tools defined in `Cargofile` (e.g., `cargo-update`, `cargo-expand`, `cargo-deps`, `cross`).
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

- The installer logs progress to `installer.log` in the current directory
- System preferences are applied automatically but can be skipped
- Failed package installations don't stop the overall process
- SSH keys are managed through 1Password vault integration
- All configurations use modern alternatives (eza vs ls, bat vs cat, ripgrep vs grep)

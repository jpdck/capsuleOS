# macOS Homebrew Setup

Automated setup for a complete macOS development environment using Homebrew.

## Quick Start

```bash
git clone github.com/jpdck/capsuleOS
cd capsuleOS
./install.sh
```

## What It Does

- Installs Homebrew and essential development tools
- Sets up dotfiles using GNU Stow
- Configures 1Password SSH key integration
- Applies macOS system preferences

## Key Files

- `Brewfile` - Package definitions for CLI tools, development languages, and GUI apps
- `install.sh` - Automated setup script
- `dotfiles/` - Configuration files managed with Stow

## Usage

Install packages: `brew bundle install`

Manage dotfiles: `stow package-name` from the `dotfiles/` directory

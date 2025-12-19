# capsuleOS

> One-command macOS bootstrap. Built for me, shared for you.

## What It Does

Complete macOS development environment: 100+ packages, dotfiles, GUI apps, Rust tools, 1Password integration, and system defaults.

## Install

```bash
bash <(curl -fsSL https://github.com/jpdck/capsuleOS/releases/download/latest/install.sh)
```

Idempotent. Re-run anytime to update packages and refresh dotfiles.

## What Happens

1. Xcode Command Line Tools + Homebrew setup
2. Bundles packages from [Brewfile](Brewfile)
3. Connects to 1Password and imports SSH keys
4. Applies macOS system settings (optional)
5. Clones repo to `~/Projects/capsuleOS`
6. Symlinks dotfiles via GNU Stow
7. Sets up automated update schedule
8. Installs Rust tools from [Cargofile](Cargofile)
9. Installs Amber framework
10. Installs Python packages via conda

## Requirements

- macOS (tested on Tahoe 26.2)
- 1Password account with service token

## Why Amber?

Written in [Amber](https://amber-lang.com/) (type-safe, transpiles to bash) because I love typed languages.

## Customize

Fork it. Edit `Brewfile`, `Cargofile`, and `dotfiles/`. That's the point.

## License

Do whatever. Credit appreciated but not required.

# capsuleOS

> One-command macOS bootstrap. Built for me, shared for you. Working spaghetti beats perfect vaporware.

## What It Does

Bootstraps a complete macOS development environment with 100+ curated packages, dotfiles, and configurations. One command, eight minutes, done.

**Installs:**

- **Homebrew packages**
- **GUI apps**
- **Rust tools**
- **Dotfiles**
- **1Password integration**
- **macOS defaults**

## Install

```bash
curl -fsSL https://github.com/jpdck/capsuleOS/releases/download/latest/install.sh | bash
```

That's it. Go make coffee.

## What Happens

1. Installs/updates Xcode Command Line Tools
2. Installs/updates Homebrew
3. Bundles packages from [Brewfile](Brewfile)
4. Connects to 1Password (you'll need a service token)
5. Imports SSH keys from your vault
6. Optionally configures macOS system settings
7. Clones this repo to `~/Projects/capsuleOS`
8. Symlinks dotfiles to your home directory
9. Installs Rust tools from [Cargofile](Cargofile)
10. Installs Amber framework

Check `~/capsuleOS/logs/installer.log` for details.

## Requirements

- macOS (tested on Tahoe 26.2)
- Internet connection
- 1Password account (for SSH key import)

## Why Amber?

This installer is written in [Amber](https://amber-lang.com/) - a modern language that transpiles to bash. You get readable source code ([Scripts/installer.ab](Scripts/installer.ab)) that compiles to portable bash ([Scripts/installer.sh](Scripts/installer.sh)).

Run either version. They're identical.

## Customize

Fork it. Edit `Brewfile` and `Cargofile`. Change dotfiles in `dotfiles/`. Run the installer. That's the point.

## Re-run Safely

Idempotent. Run it again to update packages and refresh dotfiles. Won't break existing setups.

## Build From Source

```bash
# Install Amber
bash <(curl -sL "https://github.com/amber-lang/amber/releases/download/0.5.1-alpha/install.sh")

# Build installer
cd Scripts
amber build installer.ab ../install.sh
```

## No Support

This is a personal project. Use at your own risk.

## License

Do whatever. Credit appreciated but not required.

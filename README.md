# macOS Development Environment Bootstrap

Automated setup script that takes a fresh macOS system to a fully configured development environment. Installs packages via Homebrew, deploys dotfiles with GNU Stow, and configures system settings.

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/jpdck/capsuleOS.git
   cd capsuleOS
   ```

2. **Run the installation script**
   ```bash
   ./install.sh
   ```

3. **Follow the prompts**
   - Enter your 1Password Service Token when prompted
   - Choose which SSH keys to import from 1Password
   - Confirm macOS system settings changes
   - Approve Mac App Store installations

4. **Restart your terminal**
   ```bash
   # Or source the new configuration
   source ~/.zshrc
   ```

That's it. Your development environment is ready.

## What Gets Installed

### Development Tools
- **Languages**: Rust, Go, Python 3.14, Java (OpenJDK 17)
- **Editors**: Helix, VS Code
- **Git Tools**: lazygit, delta, GitKraken
- **Terminal**: Warp, starship prompt, zsh enhancements

### CLI Utilities
- Modern replacements: `eza` (ls), `bat` (cat), `ripgrep` (grep), `fd` (find)
- Development: docker, colima, tmux, fzf, direnv
- System: 1Password CLI, mas (Mac App Store), GNU Stow

### GUI Applications
- **Development**: GitKraken, Docker Desktop, Raycast
- **Productivity**: 1Password, Microsoft Office, Magnet
- **Media**: Infuse, Noir
- **System**: Hidden Bar, Tailscale

### System Configuration
- **Shell**: Zsh with autosuggestions, syntax highlighting, history search
- **macOS Settings**: Dark mode, improved keyboard/trackpad, Finder enhancements
- **Dotfiles**: Git, shell, editor configs via GNU Stow
- **Security**: 1Password integration, SSH key management

## Maintenance

```bash
# Update packages
brew update && brew upgrade

# Check for issues
brew doctor

# Manage dotfiles (from dotfiles/ directory)
stow package-name    # Install/update
stow -D package-name # Remove
stow -R package-name # Reinstall
```

## Requirements

- macOS (tested on macOS 15+)
- Internet connection
- Admin privileges for system settings
- 1Password account (optional, for SSH key management)

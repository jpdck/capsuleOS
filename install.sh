#!/bin/bash

# macOS Bootstrap Installation Script
# Automates setup from bare macOS to fully configured development environment
# Author: Jeffrey Pidcock
# Usage: ./install.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging setup
LOG_FILE="install.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}  macOS  Environment Setup${NC}"
echo -e "${BLUE}===========================================${NC}"
echo "Starting installation at $(date)"
echo "Logging to: $LOG_FILE"
echo ""

# Function to print status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt for user confirmation
confirm() {
    local prompt="$1"
    local response
    echo -e "${YELLOW}$prompt (y/N): ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

#########################################
# Phase 1: System Prerequisites
#########################################

print_status "Phase 1: System Prerequisites"
sleep 2

# Check macOS version
macos_version=$(sw_vers -productVersion)
print_status "Detected macOS version: $macos_version"

# Check for Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    print_status "Installing Xcode Command Line Tools..."
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    PROD=$(softwareupdate -l | grep -E '\*.*Command Line' | awk -F"*" '{print $2}' | sed -e 's/^ *//' | head -n 1)
    if [[ -n "$PROD" ]]; then
        sudo softwareupdate -i "$PROD" --verbose
        print_success "Xcode Command Line Tools installed"
        rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    else
        print_error "Could not find Xcode Command Line Tools in softwareupdate list"
        rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        exit 1
    fi
else
    print_success "Xcode Command Line Tools already installed"
fi

# Install Homebrew if not present
if ! command_exists brew; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        export PATH="/opt/homebrew/bin:$PATH"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        export PATH="/usr/local/bin:$PATH"
    fi

    print_success "Homebrew installed successfully"
else
    print_success "Homebrew already installed"
    # Ensure Homebrew is in PATH
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Update Homebrew
print_status "Updating Homebrew..."
brew update

#########################################
# Phase 2: Package Installation
#########################################

print_status "Phase 2: Package Installation"
sleep 2

# Check for Brewfile
if [[ ! -f "Brewfile" ]]; then
    print_error "Brewfile not found in current directory"
    exit 1
fi

# Install packages from Brewfile
print_status "Installing packages from Brewfile..."
if brew bundle install --verbose; then
    print_success "All packages installed successfully"
else
    print_warning "Some packages may have failed to install"
    print_status "Continuing with available tools..."
fi

#########################################
# Phase 3: 1Password Integration
#########################################

print_status "Phase 3: 1Password Integration"
sleep 2

# Check if 1Password CLI is available
if command_exists op; then
    # Prompt for 1Password service token
    echo -e "${YELLOW}Please enter your 1Password Service Token:${NC}"
    echo -e "${YELLOW}(You can create one at https://my.1password.com/developer-tools/infrastructure-secrets)${NC}"
    read -rs OP_SERVICE_ACCOUNT_TOKEN

    if [[ -n "$OP_SERVICE_ACCOUNT_TOKEN" ]]; then
        # Store token in macOS Keychain for secure access
        print_status "Storing 1Password service token in macOS Keychain..."
        if security add-generic-password -a "$USER" -s "op-service-token" -w "$OP_SERVICE_ACCOUNT_TOKEN" -U 2>/dev/null; then
            print_success "1Password service token stored securely in Keychain"
        else
            print_warning "Failed to store token in Keychain, you may need to add it manually"
        fi

        # Test 1Password CLI with the token
        export OP_SERVICE_ACCOUNT_TOKEN="$OP_SERVICE_ACCOUNT_TOKEN"

        # List SSH keys in ZettoSenshi vault
        print_status "Fetching SSH keys from ZettoSenshi vault..."
        if op vault list --format=json | jq -r '.[].name' | grep -q "ZettoSenshi"; then
            echo -e "${BLUE}Available SSH keys in ZettoSenshi vault:${NC}"

            # List SSH keys using the SSH_KEY category
            ssh_keys=$(op item list --vault="ZettoSenshi" --format=json | jq -r '.[] | select(.category=="SSH_KEY") | .title')

            if [[ -n "$ssh_keys" ]]; then
                echo "$ssh_keys" | nl -w2 -s'. '
            else
                print_warning "No SSH keys found in ZettoSenshi vault"
                ssh_selection="none"
            fi

            echo -e "${YELLOW}Which SSH keys would you like to add to your local system?${NC}"
            echo -e "${YELLOW}Enter the numbers separated by spaces (e.g., 1 3 5), or 'all' for all keys, or 'none' to skip:${NC}"
            read -r ssh_selection

            if [[ "$ssh_selection" != "none" ]]; then
                # Create .ssh directory if it doesn't exist
                mkdir -p ~/.ssh
                chmod 700 ~/.ssh

                # Function to process a single SSH key
                process_ssh_key() {
                    local key_id="$1"
                    local key_name=$(op item get "$key_id" --format=json | jq -r '.title')
                    print_status "Processing SSH key: $key_name"

                    # Extract private key from 1Password using --reveal
                    private_key=$(op item get "$key_id" --fields="label=private key" --reveal)

                    if [[ -n "$private_key" && "$private_key" != "null" ]]; then
                        # Create filename based on key name (sanitize for filesystem)
                        key_filename=$(echo "id_${key_name}" | tr ' ' '_' | tr -cd '[:alnum:]_.-')

                        # Save private key to ~/.ssh/
                        echo "$private_key" > ~/.ssh/"$key_filename"
                        chmod 600 ~/.ssh/"$key_filename"
                        print_success "Added private key: $key_filename"

                        # Start SSH agent if not running
                        if ! pgrep -x ssh-agent > /dev/null; then
                            eval "$(ssh-agent -s)"
                        fi

                        # Add to SSH agent
                        if ssh-add ~/.ssh/"$key_filename" 2>/dev/null; then
                            print_success "Added key to SSH agent: $key_filename"
                        else
                            print_warning "Failed to add key to SSH agent: $key_filename"
                        fi
                    else
                        print_warning "Could not extract private key for $key_name"
                    fi
                }

                if [[ "$ssh_selection" == "all" ]]; then
                    # Add all SSH keys
                    print_status "Adding all SSH keys..."

                    # Get all SSH key IDs
                    ssh_key_ids=$(op item list --vault="ZettoSenshi" --format=json | jq -r '.[] | select(.category=="SSH_KEY") | .id')

                    if [[ -n "$ssh_key_ids" ]]; then
                        while read -r key_id; do
                            if [[ -n "$key_id" ]]; then
                                process_ssh_key "$key_id"
                            fi
                        done <<< "$ssh_key_ids"
                    else
                        print_warning "No SSH keys found to process"
                    fi
                else
                    # Add selected SSH keys by number
                    print_status "Adding selected SSH keys..."

                    # Get SSH key list with indexed array
                    ssh_key_array=($(op item list --vault="ZettoSenshi" --format=json | jq -r '.[] | select(.category=="SSH_KEY") | .id'))

                    for num in $ssh_selection; do
                        if [[ "$num" =~ ^[0-9]+$ ]]; then
                            # Convert to zero-based index
                            index=$((num - 1))

                            if [[ $index -ge 0 && $index -lt ${#ssh_key_array[@]} ]]; then
                                key_id="${ssh_key_array[$index]}"
                                process_ssh_key "$key_id"
                            else
                                print_warning "Invalid selection: $num (out of range)"
                            fi
                        else
                            print_warning "Invalid selection: $num (not a number)"
                        fi
                    done
                fi

                print_success "SSH key setup completed"
            else
                print_status "Skipping SSH key setup"
            fi
        else
            print_warning "ZettoSenshi vault not found or inaccessible"
        fi
    else
        print_warning "No 1Password service token provided, skipping 1Password integration"
    fi
else
    print_warning "1Password CLI not found, skipping 1Password integration"
fi

#########################################
# Phase 4: Repository Setup
#########################################

print_status "Phase 4: Repository Setup"
sleep 2

# Create Projects directory
print_status "Creating $HOME/Projects directory..."
mkdir -p "$HOME/Projects"

# Clone the capsuleOS repository
print_status "Cloning capsuleOS repository..."
if [[ -d "$HOME/Projects/capsuleOS" ]]; then
    print_warning "$HOME/Projects/capsuleOS already exists, removing..."
    rm -rf "$HOME/Projects/capsuleOS"
fi

if git clone ssh://git@github.com/jpdck/capsuleOS.git "$HOME/Projects/capsuleOS"; then
    print_success "Repository cloned successfully"
    cd "$HOME/Projects/capsuleOS"
    print_status "Changed working directory to $HOME/Projects/capsuleOS"
else
    print_error "Failed to clone repository. Please check your SSH keys and try again."
    exit 1
fi

# Verify repository structure
if [[ ! -d "dotfiles" ]]; then
    print_error "dotfiles directory not found in cloned repository"
    exit 1
fi

if [[ ! -f "Brewfile" ]]; then
    print_error "Brewfile not found in cloned repository"
    exit 1
fi

print_success "Repository setup completed"

#########################################
# Phase 5: Dotfiles Setup
#########################################

print_status "Phase 5: Dotfiles Setup"
sleep 2

# Verify stow is installed
if ! command_exists stow; then
    print_error "GNU Stow not found. Please ensure it was installed via Brewfile"
    exit 1
fi

# Run stow for each package
print_status "Setting up dotfiles with stow..."
cd dotfiles

# Handle potential conflicts before stowing
print_status "Checking for potential dotfile conflicts..."

# Remove common conflicting files that tools auto-create
conflicting_files=(
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.zshenv"
    "$HOME/.zprofile"
)

for file in "${conflicting_files[@]}"; do
    if [[ -f "$file" && ! -L "$file" ]]; then
        print_warning "Found conflicting file: $file (backing up and removing)"
        mv "$file" "${file}.backup-$(date +%Y%m%d%H%M%S)"
        print_status "Backed up and removed $file"
    fi
done

for package in */; do
    package_name=$(basename "$package")
    print_status "Stowing $package_name..."
    stow --target="$HOME" --verbose "$package_name" || print_warning "Failed to stow $package_name"
done

cd ..

# 1Password service token is now stored securely in macOS Keychain
# and will be loaded automatically by .zshrc configuration

print_success "Dotfiles setup completed"

#########################################
# Phase 5b: ClaudeCode Managed Settings
#########################################

print_status "Phase 5b: ClaudeCode Managed Settings"
sleep 2

# Source and target paths
CLAUDE_SOURCE_FILE="Settings/ClaudeCode/managed-settings.json"
CLAUDE_TARGET_DIR="/Library/Application Support/ClaudeCode"
CLAUDE_TARGET_FILE="$CLAUDE_TARGET_DIR/managed-settings.json"

if [[ -f "$CLAUDE_SOURCE_FILE" ]]; then
    print_status "Preparing ClaudeCode managed settings deployment..."

    # Ensure target directory exists
    if [[ ! -d "$CLAUDE_TARGET_DIR" ]]; then
        print_status "Creating target directory: $CLAUDE_TARGET_DIR"
        if sudo mkdir -p "$CLAUDE_TARGET_DIR"; then
            print_success "Created directory $CLAUDE_TARGET_DIR"
        else
            print_error "Failed to create $CLAUDE_TARGET_DIR"
        fi
    fi

    if [[ -f "$CLAUDE_TARGET_FILE" ]]; then
        # Compare hashes to detect changes
        new_hash=$(shasum -a 256 "$CLAUDE_SOURCE_FILE" | awk '{print $1}')
        existing_hash=$(shasum -a 256 "$CLAUDE_TARGET_FILE" | awk '{print $1}')

        if [[ "$new_hash" == "$existing_hash" ]]; then
            print_success "ClaudeCode managed settings already up to date"
        else
            print_warning "Existing ClaudeCode managed settings differ from repository version"
            if confirm "Backup and overwrite existing ClaudeCode managed settings?"; then
                timestamp=$(date +%Y%m%d%H%M%S)
                backup_file="$CLAUDE_TARGET_DIR/managed-settings.json.backup-$timestamp"
                if sudo cp "$CLAUDE_TARGET_FILE" "$backup_file"; then
                    print_status "Backup created: $backup_file"
                else
                    print_warning "Failed to create backup before overwrite"
                fi
                if sudo cp "$CLAUDE_SOURCE_FILE" "$CLAUDE_TARGET_FILE"; then
                    print_success "Updated ClaudeCode managed settings"
                else
                    print_error "Failed to overwrite ClaudeCode managed settings"
                fi
            else
                print_status "Keeping existing ClaudeCode managed settings"
            fi
        fi
    else
        # Fresh install
        print_status "Installing ClaudeCode managed settings..."
        if sudo cp "$CLAUDE_SOURCE_FILE" "$CLAUDE_TARGET_FILE"; then
            print_success "Installed ClaudeCode managed settings"
        else
            print_error "Failed to install ClaudeCode managed settings"
        fi
    fi

    # Ownership & permissions (best-effort)
    if sudo chown root:wheel "$CLAUDE_TARGET_FILE" 2>/dev/null; then
        :
    else
        print_warning "Could not set ownership root:wheel (may not be macOS or insufficient privileges)"
    fi
    if sudo chmod 644 "$CLAUDE_TARGET_FILE" 2>/dev/null; then
        :
    else
        print_warning "Could not set permissions 644 on ClaudeCode managed settings"
    fi
else
    print_warning "ClaudeCode managed settings source file not found at $CLAUDE_SOURCE_FILE"
fi

#########################################
# Phase 6: macOS Configuration
#########################################

print_status "Phase 6: macOS System Configuration"
sleep 2

if confirm "Apply recommended macOS system settings?"; then
    print_status "Applying macOS system settings..."

    # Global Interface Settings
    print_status "Configuring global interface settings..."
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write NSGlobalDomain InitialKeyRepeat -int 14
    defaults write NSGlobalDomain KeyRepeat -int 1
    defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
    defaults write NSGlobalDomain AppleScrollerPagingBehavior -bool true
    defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
    defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
    defaults write NSGlobalDomain "com.apple.trackpad.scaling" -float 2.0
    defaults write NSGlobalDomain "com.apple.mouse.tapBehavior" -int 1
    defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

    # Dock Configuration
    print_status "Configuring dock settings..."
    defaults write com.apple.dock autohide -bool false
    defaults write com.apple.dock orientation -string "bottom"
    defaults write com.apple.dock showhidden -bool true
    defaults write com.apple.dock mineffect -string "genie"
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock tilesize -int 36
    defaults write com.apple.dock magnification -bool true
    defaults write com.apple.dock largesize -int 48
    defaults write com.apple.dock autohide-delay -float 0.0
    defaults write com.apple.dock autohide-time-modifier -float 0.5

    # Finder Settings
    print_status "Configuring Finder settings..."
    defaults write com.apple.finder AppleShowAllFiles -bool true
    defaults write com.apple.finder AppleShowAllExtensions -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder QuitMenuItem -bool true

    # Trackpad Settings
    print_status "Configuring trackpad settings..."
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

    # Screensaver Security
    print_status "Configuring screensaver security..."
    defaults write com.apple.screensaver askForPassword -bool true
    defaults write com.apple.screensaver askForPasswordDelay -int 5

    # Restart affected services
    print_status "Restarting affected system services..."
    killall Dock
    killall Finder
    killall SystemUIServer

    print_success "macOS system settings applied"
else
    print_status "Skipping macOS system settings"
fi

# Extract and apply git configuration
if [[ -f ~/.gitconfig ]]; then
    print_status "Git configuration found in dotfiles"
    git_user=$(git config --global user.name 2>/dev/null || echo "")
    git_email=$(git config --global user.email 2>/dev/null || echo "")

    if [[ -n "$git_user" && -n "$git_email" ]]; then
        print_success "Git already configured: $git_user <$git_email>"
    else
        print_warning "Git configuration incomplete, you may need to set user.name and user.email manually"
    fi
else
    print_warning "No git configuration found in dotfiles"
fi

# Create additional directory structure
print_status "Creating additional directory structure..."
mkdir -p ~/Documents/Scripts
print_success "Additional directory structure created"

#########################################
# Phase 7: App Store Installation
#########################################

print_status "Phase 7: App Store Installation"
sleep 2

if command_exists mas; then
    # Check if user is signed into Mac App Store
    if mas account >/dev/null 2>&1; then
        print_status "Mac App Store account detected"

        # Extract App Store IDs from Brewfile
        app_store_ids=(
            1569813296  # 1Password for Safari
            6502451661  # Balatro
            488920185   # Disk Space Analyzer Pro
            1452453066  # Hidden Bar
            1136220934  # Infuse
            409183694   # Keynote
            441258766   # Magnet
            462058435   # Microsoft Excel
            985367838   # Microsoft Outlook
            462062816   # Microsoft PowerPoint
            462054704   # Microsoft Word
            1592917505  # Noir
            409203825   # Numbers
            823766827   # OneDrive
            409201541   # Pages
            639968404   # Parcel
            6738274497  # Raycast Companion
            1475387142  # Tailscale
            1295203466  # Windows App
            1662217862  # Wipr
            497799835   # Xcode
        )

        if confirm "Install Mac App Store applications?"; then
            print_status "Installing Mac App Store applications..."
            for app_id in "${app_store_ids[@]}"; do
                print_status "Installing app ID: $app_id"
                mas install "$app_id" || print_warning "Failed to install app ID: $app_id"
            done
            print_success "Mac App Store installation completed"
        else
            print_status "Skipping Mac App Store installation"
        fi
    else
        print_warning "Not signed into Mac App Store. Please sign in manually and run 'mas install <id>' for desired apps"
    fi
else
    print_warning "Mac App Store CLI (mas) not found"
fi

#########################################
# Phase 8: Language-Specific Tools
#########################################

print_status "Phase 8: Language-Specific Tools Installation"
sleep 2

# Install Rust tools from Cargofile
if command_exists cargo; then
    if [[ -f "Cargofile" ]]; then
        print_status "Installing Rust tools from Cargofile..."

        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip comments and empty lines
            if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// /}" ]]; then
                continue
            fi

            # Extract crate name (first word on the line)
            crate=$(echo "$line" | awk '{print $1}')

            if [[ -n "$crate" ]]; then
                print_status "Installing $crate..."
                if cargo install "$crate"; then
                    print_success "$crate installed successfully"
                else
                    print_warning "Failed to install $crate"
                fi
            fi
        done < "Cargofile"
    else
        print_warning "Cargofile not found, skipping Rust tools installation"
    fi
else
    print_warning "Cargo not found, skipping Rust tools installation"
fi

# Install additional Python packages via conda
if command_exists conda; then
    print_status "Installing additional Python packages via conda..."
    python_packages=("pytest" "ipython" "python-lsp-server")

    for package in "${python_packages[@]}"; do
        print_status "Installing $package..."
        if conda install -y "$package"; then
            print_success "$package installed successfully"
        else
            print_warning "Failed to install $package"
        fi
    done
else
    print_warning "conda not found, skipping Python packages installation"
fi

# Source new shell configuration
print_status "Sourcing new shell configuration..."
if [[ -f ~/.zshrc ]]; then
    # Note: We can't actually source in a bash script, but we can tell the user
    print_status "New .zshrc configuration is ready"
    print_warning "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
fi

# Verify essential tools are accessible
print_status "Verifying tool installation..."
essential_tools=("git" "stow" "starship" "helix" "brew" "op")

for tool in "${essential_tools[@]}"; do
    if command_exists "$tool"; then
        tool_path=$(which "$tool")
        print_success "$tool ✓ ($tool_path)"
    else
        print_warning "$tool ✗ (not found in PATH)"
    fi
done

# Generate summary report
print_status "Installation Summary"
echo ""
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}  Installation Completed Successfully!${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Restart your terminal to apply shell changes"
echo "2. Sign into Mac App Store if you haven't already"
echo "3. Run 'brew doctor' to check for any issues"
echo "4. Test your development tools"
echo ""
echo "Log file: $LOG_FILE"
echo "Installation completed at: $(date)"

print_success "Bootstrap installation complete!"
#/bin/sh

# Script to setup a new mac for developement
# Usage: 
# ./setup-mac.sh
# manual mode - where each step is executed one by one and user can choose to skip or continue
# ./setup-mac.sh -m
# 
# (c) Anurag Khadatkar
# 21 Dec 2025

# early exit on errors
set -e

run_mode="auto"

if [ "$1" = "-w" ]; then
  run_mode="wizard"
elif [ "$1" = "-m" ]; then
    run_mode="manual"
elif [ "$1" = "-h" ]; then
  echo "Usage: ./setup-mac.sh [-m]"
  echo "  -m: manual mode - where each step is executed one by one and user can choose to skip or continue"
  exit 0
fi

# check before executing steps if user wants to skip the step or not
# In default mode, all steps will be executed. In wizard mode, user can choose to skip a step.
skip_step() {
    # wizard mode - ask user if they want to skip the step
    if [ "$run_mode" = "wizard" ]; then
        read -p "Do you want to skip $1? (y/n) " choice
        if [ "$choice" = "y" ] || [ "$choice" = "Y" ] || [ "$choice" = "yes" ] || [ "$choice" = "YES" ]; then
            echo "Skipping $1"
            return 0
        fi
    fi
    # auto mode - install / reinstall the package
    return 1
}

enable_rosetta() {
    if skip_step "Rosetta installation"; then
        return
    fi

    echo "Enabling Rosetta..."
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
}

install_homebrew() {
    if skip_step "Homebrew installation"; then
        return
    fi

    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo "Setting up Homebrew environment variables..."
    echo >> $HOME/.zprofile
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"

    source $HOME/.zprofile
    brew doctor
    brew update

    echo "Homebrew is setup"
}

setup_fonts() {
    if skip_step "Fonts installation"; then
        return
    fi

    echo "Installing fonts..."
    brew tap homebrew/cask-fonts
    brew install --cask font-meslo-lg-nerd-font
    brew install --cask font-fira-code-nerd-font
    brew install --cask font-hack-nerd-font
    brew install --cask font-jetbrains-mono-nerd-font
    brew install --cask font-source-code-pro-nerd-font
    brew install --cask font-ubuntu-mono-nerd-font
}

setup_terminal() {
    if skip_step "Terminal setup"; then
        return
    fi

    echo "Setting up terminal..."
    # lets make the terminal pretty first
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
    source ~/.zshrc
}

setup_zsh() {
    if skip_step "Zsh setup"; then
        return
    fi

    echo "Setting up Zsh..."
    brew install zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions

    # set zsh as default shell
    chsh -s /bin/zsh
}

set_finder_power_prefs() {
    if skip_step "Finder power preferences"; then
        return
    fi

    # System prefs
    # thanks to https://www.robinwieruch.de/mac-setup-web-development/

    echo "Setting up Finder power preferences..."
    
    # take screenshots as jpg (usually smaller size) and not png
    defaults write com.apple.screencapture type jpg

    # do not open previous previewed files (e.g. PDFs) when opening a new one
    defaults write com.apple.Preview ApplePersistenceIgnoreState YES

    # show all filename extensions
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # show status bar
    defaults write com.apple.finder ShowStatusBar -bool true

    # show path bar
    defaults write com.apple.finder ShowPathbar -bool true

    # allow text selection in Quick Look
    defaults write com.apple.finder QLEnableTextSelection -bool true

    # show hidden files by default
    defaults write com.apple.finder AppleShowAllFiles -bool true

    # show Library folder
    chflags nohidden ~/Library

    # restart finder to apply changes
    killall Finder;
}

setup_java() {
    if skip_step "Java setup"; then
        return
    fi

    echo "Setting up Java..."
    # Install SDKMan for Java
    brew tap sdkman/tap
    brew install sdkman-cli
    echo 'export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec' >>~/.zshrc
    echo '  [[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"' >>~/.zshrc
    source ~/.zshrc
    sdk version
    sdk install java 25.0.1-amzn
}

setup_rust() {
    if skip_step "Rust setup"; then
        return
    fi

    echo "Setting up Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source $HOME/.cargo/env
    rustc --version
}

setup_node() {
    if skip_step "Node.js setup"; then
        return
    fi

    echo "Setting up Node.js..."
    # Install nvm for Node.js
    brew install nvm yarn pnpm
    mkdir ~/.nvm
    echo 'export NVM_DIR="$HOME/.nvm"' >>~/.zshrc
    echo '[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"' >>~/.zshrc
    echo '[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"' >>~/.zshrc
    source ~/.zshrc
    nvm install --lts
    nvm use --lts
}

# TODO: Add setup for Python, Go, etc.

# TODO: Add setup for docker runtimes, docker-compose, etc.

setup_essential_packages() {
    if skip_step "Essential packages setup"; then
        return
    fi

    echo "Setting up essential packages..."
    brew install git wget curl tree htop jq
}

setup_essential_programs() {
    if skip_step "Essential programs setup"; then
        return
    fi

    if !skip_step "VS Code setup"; then
        echo "Setting up VS Code..."
        brew install --cask visual-studio-code
    fi

    if !skip_step "Postman setup"; then
        echo "Setting up Postman..."
        brew install --cask postman
    fi

    if !skip_step "FDM setup"; then
        echo "Setting up Free Download Manager..."
        brew install --cask free-download-manager
    fi

    # echo "Setting up essential programs..."
    # brew install --cask iterm2 postman docker
}

run_sequence() {
    enable_rosetta
    install_homebrew
    setup_fonts
    setup_terminal
    setup_zsh
    set_finder_power_prefs
    setup_java
    setup_rust
    setup_node
    setup_essential_packages
    setup_essential_programs
}

manual_step_complete_message() {
    echo "Step $1 completed."
    echo "Press Enter to go back to the menu or type 'q' to quit."
    read choice
    if [ "$choice" = "q" ] || [ "$choice" = "Q" ]; then
        echo "Exiting manual mode."
        exit 0
    else
        manual_menu
    fi
}

run_manual() {
    step=$1

    case $step in
        1)
            enable_rosetta
            manual_step_complete_message "Rosetta installation"
            ;;
        2)
            install_homebrew
            manual_step_complete_message "Homebrew installation"
            ;;
        3)
            setup_fonts
            manual_step_complete_message "Fonts installation"
            ;;
        4)
            setup_terminal
            manual_step_complete_message "Terminal setup"
            ;;
        5)
            setup_zsh
            manual_step_complete_message "Zsh setup"

            ;;
        6)
            set_finder_power_prefs
            manual_step_complete_message "Finder power preferences"

            ;;
        7)
            setup_java
            manual_step_complete_message "Java setup"

            ;;
        8)
            setup_rust
            manual_step_complete_message "Rust setup"

            ;;
        9)
            setup_node
            manual_step_complete_message "Node.js setup"

            ;;
        10)
            setup_essential_packages
            manual_step_complete_message "Essential packages setup"
            ;;
        11)
            setup_essential_programs
            manual_step_complete_message "Essential programs setup"
            ;;
        q|Q)
            echo "Exiting manual mode."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            manual_menu
            run_manual $step
    esac
}

manual_menu() {
    clear;
    echo "--------------------------------------------------------------"
    echo "  Mac Dev Setup Script - Version 1.0"
    echo "--------------------------------------------------------------"
    echo " 1. Enable Rosetta"
    echo " 2. Install Homebrew"
    echo " 3. Setup Fonts"
    echo " 4. Setup Terminal"
    echo " 5. Setup Zsh"
    echo " 6. Set Finder Power Preferences"
    echo " 7. Setup Java"
    echo " 8. Setup Rust"
    echo " 9. Setup Node.js"
    echo "10. Setup Essential Packages"
    echo "11. Setup Essential Programs"
    echo "--------------------------------------------------------------"
    echo "Enter the number of the step you want to execute (or 'q' to quit):"

    read step
    run_manual $step
}

echo "Running setup script in $run_mode mode..."

if [ "$run_mode" = "manual" ]; then
    manual_menu
else
    run_sequence
fi

createDir() {
    if [ ! -d "$1" ]; then
        mkdir "$1"
    fi
}

createSymlink() {
    if [ ! -e "$2" ]; then
        ln -s "$1" "$2"
    fi
}

installProfile() {
    if [ -e "$1" ]; then
        isInstalled=$(grep "$2" "$1")
        if [ -z "$isInstalled" ]; then
            echo "" >> "$1"
            echo "export VOLTA_HOME=\"$HOME/.volta\"" >> "$1"
            echo "export PATH=\"$HOME/.volta/bin:\$PATH\"" >> "$1"
            echo "source $2" >> "$1"
        fi
    fi
}

# Create directories
createDir "$HOME/.volta"
createDir "$HOME/.volta/bin"

# Create symlinks
createSymlink "/usr/bin/volta" "$HOME/.volta/volta"
createSymlink "/usr/bin/volta-migrate" "$HOME/.volta/volta-migrate"
createSymlink "/usr/bin/volta-shim" "$HOME/.volta/volta-shim"

# Install profile
installProfile "$HOME/.bashrc" "/etc/volta/load.bash"
installProfile "$HOME/.cshrc" "/etc/volta/load.sh"
installProfile "$HOME/.config/fish/config.fish" "/etc/volta/load.fish"
installProfile "$HOME/.zshrc" "/etc/volta/load.sh"

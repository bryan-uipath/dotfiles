#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Symlink zshrc
ln -sf "$DOTFILES_DIR/zshrc" ~/.zshrc

# Create .secrets from template if it doesn't exist
if [[ ! -f "$DOTFILES_DIR/.secrets" ]]; then
    cp "$DOTFILES_DIR/.secrets.example" "$DOTFILES_DIR/.secrets"
    echo "Created .secrets from template - fill in your values"
fi

# Create .local.zsh from template if it doesn't exist
if [[ ! -f "$DOTFILES_DIR/.local.zsh" ]]; then
    cp "$DOTFILES_DIR/.local.zsh.example" "$DOTFILES_DIR/.local.zsh"
    echo "Created .local.zsh from template - customize your shortcuts"
fi

# Run macOS setup
if [[ "$(uname)" == "Darwin" ]]; then
    "$DOTFILES_DIR/macos-setup.sh"
fi

echo "Done! Restart your shell or run: source ~/.zshrc"

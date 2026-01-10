#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

link() {
  src="$DOTFILES/$1"
  dest="$2"

  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -f "$dest" ]; then
    echo "Backing up $dest to $dest.backup"
    mv "$dest" "$dest.backup"
  fi

  ln -s "$src" "$dest"
  echo "Linked $dest -> $src"
}

# Create config directories
mkdir -p ~/.config

# Link dotfiles
link "zshrc"        ~/.zshrc
link "vimrc"        ~/.vimrc
link "tmux.conf"    ~/.tmux.conf
# link "starship.toml" ~/.config/starship.toml  # uncomment when added

echo ""
echo "Done! Run 'source ~/.zshrc' to reload."

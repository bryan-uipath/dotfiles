# dotfiles

My terminal configuration for zsh, vim, and tmux.

## Install

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
source ~/.zshrc
```

## What's included

| File | Description |
|------|-------------|
| `zshrc` | Zsh config with aliases, starship prompt, nvm |
| `vimrc` | Vim config with notes shortcuts, checkbox cycling |
| `tmux.conf` | Tmux config |

## Key aliases

| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `gp` | `git push origin HEAD` |
| `gl` | `git log --oneline -n10` |
| `j <dir>` | Jump to `~/code/<dir>` |
| `sz` | Reload zshrc |
| `o` | Open current dir in Finder |

## Updating

Configs are symlinked, so just edit them normally:

```bash
vim ~/.vimrc        # edits ~/dotfiles/vimrc
cd ~/dotfiles
git add -A && git commit -m "update" && git push
```

## Re-applying

After pulling changes on another machine:

```bash
cd ~/dotfiles && git pull && ./bootstrap.sh
```

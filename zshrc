# Source secrets if they exist
[[ -f ~/dotfiles/.secrets ]] && source ~/dotfiles/.secrets

# Source machine-specific config if it exists
[[ -f ~/dotfiles/.local.zsh ]] && source ~/dotfiles/.local.zsh

export PATH="$HOME/.local/bin:$PATH"

export EDITOR=vim
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

eval "$(starship init zsh)"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Git
alias gs="git status"
alias gco="git checkout"
alias gco-="git checkout -"
alias gcb="git checkout -b"
alias gp="git push origin HEAD"
alias gpf="git push --force origin HEAD"
alias gl="git log --oneline -n10"
alias gd="git diff"
alias ga="git add"
alias gc="git commit -m"
alias grs="git reset --hard"

# Quick reload
alias sz="source ~/.zshrc"

# Docker
alias dcu="docker compose up -d"
alias dcl="docker compose logs"

# Open current dir
alias o="open ."

# Open URL in Chrome
chrome() {
    osascript -e "tell application \"Google Chrome\" to open location \"$1\""
}

# Navigation - j prefix
# Define base shortcuts (shared across all machines)
typeset -gA J_SHORTCUTS
J_SHORTCUTS=(
    notes ~/notes
)

# j function - uses J_SHORTCUTS array, falls back to ~/code/<name>
j() {
    if [[ -n "${J_SHORTCUTS[$1]}" ]]; then
        cd "${J_SHORTCUTS[$1]}"
    else
        cd ~/code/$1
    fi
}

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
alias gpull="git pull"

# Quick reload
alias sz="source ~/.zshrc"

# Docker
alias dcu="docker compose up -d"
alias dcl="docker compose logs"

# Open current dir
alias o="open ."

# Notes
alias nw='vim ~/notes/weekly/$(date +%Y-w%V).md'

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

# j function - uses J_SHORTCUTS array, falls back to ~/code/<name> with fuzzy matching
j() {
    # 1. Check shortcuts first (exact match)
    if [[ -n "${J_SHORTCUTS[$1]}" ]]; then
        cd "${J_SHORTCUTS[$1]}"
        return
    fi

    # 2. Check exact match in ~/code
    if [[ -d ~/code/$1 ]]; then
        cd ~/code/$1
        return
    fi

    # 3. Fuzzy match: convert "flow3" to pattern "*f*l*o*w*3*"
    local pattern=""
    for (( i=0; i<${#1}; i++ )); do
        pattern+="*${1:$i:1}"
    done
    pattern+="*"

    # Find matching directories
    local matches=()
    for dir in ~/code/*/; do
        local name="${dir%/}"
        name="${name##*/}"
        if [[ "${name:l}" == ${~pattern:l} ]]; then
            matches+=("$name")
        fi
    done

    if (( ${#matches[@]} == 0 )); then
        echo "j: no match for '$1' in ~/code"
        return 1
    elif (( ${#matches[@]} == 1 )); then
        cd ~/code/${matches[1]}
    else
        # Multiple matches - pick shortest, or show all if ambiguous
        local shortest="${matches[1]}"
        for m in "${matches[@]}"; do
            if (( ${#m} < ${#shortest} )); then
                shortest="$m"
            fi
        done
        echo "j: multiple matches, using shortest: $shortest"
        echo "   (all: ${matches[*]})"
        cd ~/code/$shortest
    fi
}

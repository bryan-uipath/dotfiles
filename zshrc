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
# gco - git checkout with fuzzy branch matching
unalias gco 2>/dev/null
gco() {
    if [[ -z "$1" ]]; then
        git checkout
        return
    fi

    # 1. Try exact match first
    if git show-ref --verify --quiet "refs/heads/$1" 2>/dev/null; then
        git checkout "$1"
        return
    fi

    # 2. Try as-is (handles flags, commits, files, remote branches)
    if git checkout "$@" 2>/dev/null; then
        return
    fi

    # 3. Fuzzy match: convert "featmon" to pattern "*f*e*a*t*m*o*n*"
    local pattern=""
    for (( i=0; i<${#1}; i++ )); do
        pattern+="*${1:$i:1}"
    done
    pattern+="*"

    # Find matching local branches
    local matches=()
    while IFS= read -r branch; do
        if [[ "${branch:l}" == ${~pattern:l} ]]; then
            matches+=("$branch")
        fi
    done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

    if (( ${#matches[@]} == 0 )); then
        echo "gco: no branch matching '$1'"
        return 1
    elif (( ${#matches[@]} == 1 )); then
        git checkout "${matches[1]}"
    else
        # Multiple matches - pick shortest
        local shortest="${matches[1]}"
        for m in "${matches[@]}"; do
            if (( ${#m} < ${#shortest} )); then
                shortest="$m"
            fi
        done
        echo "gco: multiple matches, using shortest: $shortest"
        echo "   (all: ${matches[*]})"
        git checkout "$shortest"
    fi
}
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
alias gpush="git push origin HEAD"
alias gg="git grep"
alias gaa="git add ."

# Aviator
alias avup="av sync --rebase-to-trunk"

# Quick reload
alias sz="source ~/.zshrc"

# Docker
alias dcu="docker compose up -d"
alias dcl="docker compose logs"

# Open current dir
alias o="open ."

# Notes
alias ny='vim ~/notes/$(date +%Y).md'
alias nw='vim ~/notes/weekly/$(date +%Y-w%V).md'
alias nnw='vim ~/notes/weekly/$(date -v+7d +%Y-w%V).md'
alias n="cd ~/notes"
alias nls='ls ~/notes/projects'
alias np='cd ~/notes/projects'

# Create new project and cd into it
npnew() {
    if [[ -z "$1" ]]; then
        echo "Usage: npnew <project-name>"
        return 1
    fi
    mkdir -p ~/notes/projects/$1 && cd ~/notes/projects/$1
}

# Quick capture to inbox
ncap() { echo "- $*" >> ~/notes/$(date +%Y).md; echo "Added to inbox"; }

# Open 1:1 notes for a person
n1() { vim ~/notes/people/$1.md; }

# New meeting note
nmeet() { vim ~/notes/meetings/$(date +%Y-%m-%d)-$1.md; }

# Search all notes
ns() { grep -ri "$*" ~/notes --include="*.md"; }

# Archive a project: narchive <project-name>
narchive() {
    local src=~/notes/projects/$1
    local dest=~/notes/archives/$(date +%Y-%m)-$1
    if [[ ! -e "$src" ]]; then
        echo "narchive: project '$1' not found in ~/notes/projects/"
        return 1
    fi
    mv "$src" "$dest"
    echo "Archived: $dest"
}

# Claude
alias c="claude"
alias cyolo="claude --dangerously-skip-permissions"

# Codex
alias x="codex"
alias xyolo="codex --yolo"

# General shortcuts
alias g='git'
alias v='vi'
alias h='history'
alias k='kubectl'
alias e='open -a Finder ./'

# Directory navigation
alias lt='tree'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias dl='cd ~/Downloads'
alias dt='cd ~/Desktop'

# iTerm tab naming
tabname() { echo -ne "\033]0;$1\007"; }
alias tn='tabname'

# Utilities
alias getpass='openssl rand -base64 40'
alias ip='ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d " " -f2'
alias ttop='top -R -F -s 10 -o rsize'
alias flushdns='dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\\: .*|GET \\/.*\""
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

# Open URL in Chrome
chrome() {
    osascript -e "tell application \"Google Chrome\" to open location \"$1\""
}

# List repos with branches
repos() {
    printf "\e[1m%-30s %s\e[0m\n" "REPO" "BRANCH"
    printf "%-30s %s\n" "----" "------"
    for dir in ~/code/*/; do
        if [[ -d "$dir/.git" ]]; then
            local name="${dir%/}"
            name="${name##*/}"
            local branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
            # Color: green for main/master/develop, yellow otherwise
            if [[ "$branch" =~ ^(main|master|develop)$ ]]; then
                printf "\e[36m%-30s\e[0m \e[32m%s\e[0m\n" "$name" "$branch"
            else
                printf "\e[36m%-30s\e[0m \e[33m%s\e[0m\n" "$name" "$branch"
            fi
        fi
    done
}

# Git tree - show all repos with branch, commit, and date
# Usage: gtree [filter] - fuzzy filter repos and show all branches
gtree() {
    local filter="$1"
    local pattern=""

    # Build fuzzy pattern if filter provided
    if [[ -n "$filter" ]]; then
        for (( i=0; i<${#filter}; i++ )); do
            pattern+="*${filter:$i:1}"
        done
        pattern+="*"
    fi

    # Collect directories: ~/code/* and ~/dotfiles
    local dirs=(~/code/*/ ~/dotfiles)

    if [[ -z "$filter" ]]; then
        # No filter: show current branch only (original behavior)
        printf "\e[1m%-25s %-30s %-10s %s\e[0m\n" "REPO" "BRANCH" "COMMIT" "DATE"
        printf "%-25s %-30s %-10s %s\n" "----" "------" "------" "----"

        for dir in "${dirs[@]}"; do
            if [[ -d "$dir/.git" ]]; then
                local name="${dir%/}"
                name="${name##*/}"
                local branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
                local commit=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
                local date=$(git -C "$dir" log -1 --format="%ar" 2>/dev/null)

                if [[ "$branch" =~ ^(main|master|develop)$ ]]; then
                    printf "\e[36m%-25s\e[0m \e[32m%-30s\e[0m \e[90m%-10s\e[0m %s\n" "$name" "$branch" "$commit" "$date"
                else
                    printf "\e[36m%-25s\e[0m \e[33m%-30s\e[0m \e[90m%-10s\e[0m %s\n" "$name" "$branch" "$commit" "$date"
                fi
            fi
        done
    else
        # Filter provided: show all branches for matching repos
        for dir in "${dirs[@]}"; do
            if [[ -d "$dir/.git" ]]; then
                local name="${dir%/}"
                name="${name##*/}"

                # Fuzzy match repo name
                if [[ "${name:l}" == ${~pattern:l} ]]; then
                    local current=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
                    printf "\e[1;36m%s\e[0m\n" "$name"

                    # List branches with commits in last 7 days, sorted by commit date
                    local cutoff=$(date -v-7d +%s)
                    git -C "$dir" for-each-ref --sort=-committerdate --format='%(refname:short)|%(objectname:short)|%(committerdate:relative)|%(committerdate:unix)' refs/heads/ 2>/dev/null | while IFS='|' read -r branch commit date timestamp; do
                        # Skip branches older than 7 days
                        [[ "$timestamp" -lt "$cutoff" ]] && continue

                        local marker="  "
                        [[ "$branch" == "$current" ]] && marker="* "

                        if [[ "$branch" =~ ^(main|master|develop)$ ]]; then
                            printf "  %s\e[32m%-28s\e[0m \e[90m%-10s\e[0m %s\n" "$marker" "$branch" "$commit" "$date"
                        else
                            printf "  %s\e[33m%-28s\e[0m \e[90m%-10s\e[0m %s\n" "$marker" "$branch" "$commit" "$date"
                        fi
                    done
                    echo
                fi
            fi
        done
    fi
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

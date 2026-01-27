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

# FZF - fuzzy finder (Ctrl+R for history, Ctrl+T for files, Alt+C for cd)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Git
alias gs="git status"
# gco - git checkout with fuzzy branch matching
# No args + fzf available: interactive picker sorted by recent
# With args: fuzzy match branch name
unalias gco 2>/dev/null
gco() {
    # No args: interactive picker with fzf (if available)
    if [[ -z "$1" ]]; then
        if command -v fzf &>/dev/null; then
            local branch=$(git branch --sort=-committerdate --format='%(refname:short)' | fzf --preview 'git log --oneline -10 {}')
            [[ -n "$branch" ]] && git checkout "$branch"
        else
            git checkout
        fi
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
        # Multiple matches - use fzf if available, otherwise pick shortest
        if command -v fzf &>/dev/null; then
            local branch=$(printf '%s\n' "${matches[@]}" | fzf --preview 'git log --oneline -10 {}')
            [[ -n "$branch" ]] && git checkout "$branch"
        else
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
alias gf="git fetch origin"
alias glog="git log --oneline -n10"

# Quick commit + push (git add . && commit && push)
gcp() { git add . && git commit -m "$*" && git push origin HEAD; }

# Aviator
alias avup="av sync --rebase-to-trunk"
alias avs="av sync"
alias avtc="av tree --current"
alias avta="av tree"

# av pr wrapper that adds stack comments to ALL PRs in the stack
# Usage: avp [av pr flags]
avp() {
    # Run av pr with all args (--draft by default)
    av pr --draft "$@"
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        return $exit_code
    fi

    # Update stack comments on all PRs
    avp-update-stack-comments
}

# Update stack comments on all PRs in the current stack
# Can be run standalone to refresh comments without creating PRs
avp-update-stack-comments() {
    # Get the stack tree
    local stack_tree=$(av tree --current 2>/dev/null)

    if [[ -z "$stack_tree" ]]; then
        echo "avp: no stack found"
        return 0
    fi

    # Parse the stack tree to extract branches and PR URLs
    # Use a temp file to avoid subshell issues with here-strings
    local tmpfile=$(mktemp)
    echo "$stack_tree" > "$tmpfile"

    local pr_urls=()
    local pr_numbers=()

    while IFS= read -r line; do
        # Match PR URL line
        if [[ "$line" == *"github.com"*"/pull/"* ]]; then
            local pr_url=$(echo "$line" | grep -oE 'https://github.com/[^/]+/[^/]+/pull/[0-9]+')
            local pr_number=$(echo "$pr_url" | grep -oE '[0-9]+$')
            pr_urls+=("$pr_url")
            pr_numbers+=("$pr_number")
        fi
    done < "$tmpfile"
    rm -f "$tmpfile"

    if [[ ${#pr_numbers[@]} -eq 0 ]]; then
        echo "avp: no PRs found in stack"
        return 0
    fi

    # Update each PR in the stack with a custom body
    for pr_number in "${pr_numbers[@]}"; do
        [[ -z "$pr_number" ]] && continue

        # Build indented bullet list (reversed, with THIS PR indicator)
        local stack_list=""
        local indent=""
        for (( i=${#pr_urls[@]}; i>=1; i-- )); do
            local indicator=""
            [[ "${pr_numbers[$i]}" == "$pr_number" ]] && indicator=" **← THIS PR**"
            stack_list+="${indent}- ${pr_urls[$i]}$indicator"$'\n'
            indent+="  "
        done

        local stack_body="<!-- av-stack-comment -->
### Current Stack

$stack_list
_Managed with [Aviator](https://www.aviator.co/stacking)_"

        # Check if comment already exists (use API to get numeric ID)
        local existing_comment=$(gh api "repos/{owner}/{repo}/issues/$pr_number/comments" --jq '.[] | select(.body | contains("av-stack-comment")) | .id' 2>/dev/null | head -1)

        if [[ -n "$existing_comment" ]]; then
            gh api -X PATCH "/repos/{owner}/{repo}/issues/comments/$existing_comment" -f body="$stack_body" > /dev/null 2>&1
            echo "avp: updated stack comment on PR #$pr_number"
        else
            gh pr comment "$pr_number" --body "$stack_body" > /dev/null 2>&1
            echo "avp: added stack comment to PR #$pr_number"
        fi
    done
}

# Graphite -> Aviator migration helper
# Reminds you to use aviator and suggests the equivalent command
gt() {
    local cmd="$1"
    echo "Reminder: Use Aviator instead of Graphite!"
    echo ""
    case "$cmd" in
        track)
            echo "  gt track  ->  av stack branch"
            echo "  Run: av stack branch"
            ;;
        squash)
            echo "  gt squash  ->  av squash"
            echo "  Run: av squash"
            ;;
        restack)
            echo "  gt restack  ->  av restack"
            echo "  Run: av restack"
            ;;
        sync)
            echo "  gt sync  ->  av sync"
            echo "  Run: av sync"
            ;;
        submit)
            echo "  gt submit  ->  av pr"
            echo "  Run: av pr"
            ;;
        tree)
            echo "  gt tree  ->  av tree"
            echo "  Run: av tree (or avtc for --current, avta for all)"
            ;;
        *)
            echo "Common Graphite -> Aviator mappings:"
            echo "  gt track   ->  av stack branch"
            echo "  gt squash  ->  av squash"
            echo "  gt restack ->  av restack"
            echo "  gt sync    ->  av sync"
            echo "  gt submit  ->  av pr"
            echo "  gt tree    ->  av tree"
            echo ""
            echo "Run 'av help' for full Aviator documentation"
            ;;
    esac
}

# Quick reload
alias sz="source ~/.zshrc"

# Docker
alias dcu="docker compose up -d"
alias dcl="docker compose logs"
alias dcd="docker compose down"
alias dcr="docker compose restart"


# Interactive docker compose logs with fzf
dcf() {
    if ! command -v fzf &>/dev/null; then
        docker compose logs -f "$@"
        return
    fi
    local service
    if [[ -n "$1" ]]; then
        service="$1"
    else
        service=$(docker compose ps --format '{{.Service}}' 2>/dev/null | fzf)
    fi
    [[ -n "$service" ]] && docker compose logs -f "$service"
}

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

# Interactive note fuzzy find with fzf (search content, open in vim)
nff() {
    if ! command -v fzf &>/dev/null; then
        echo "nf: fzf not installed"
        return 1
    fi
    local file
    if [[ -n "$1" ]]; then
        file=$(grep -ril "$1" ~/notes --include="*.md" | fzf --preview 'head -50 {}')
    else
        file=$(find ~/notes -name "*.md" -type f | fzf --preview 'head -50 {}')
    fi
    [[ -n "$file" ]] && vim "$file"
}

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
# For single-pane tabs: tn "name" sets the session title
# For multi-pane tabs: use Cmd+Shift+I (Edit Tab Title) for a tab-level name
tabname() {
    echo -ne "\033]1;$1\007"
    # Set iTerm user variable (value must be base64 encoded)
    echo -ne "\033]1337;SetUserVar=tabname=$(echo -n "$1" | base64)\007"
}
alias tn='tabname'

# Utilities
alias getpass='openssl rand -base64 40'
alias ip='ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d " " -f2'
alias ttop='top -R -F -s 10 -o rsize'
alias flushdns='dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\\: .*|GET \\/.*\""
alias urlencode='python3 -c "import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))"'

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
# No args + fzf available: interactive picker
j() {
    # No args: interactive picker with fzf (if available)
    if [[ -z "$1" ]]; then
        if command -v fzf &>/dev/null; then
            local dir=$(ls -d ~/code/*/ 2>/dev/null | xargs -n1 basename | fzf --preview 'git -C ~/code/{} log --oneline -5 2>/dev/null || echo "Not a git repo"')
            [[ -n "$dir" ]] && cd ~/code/"$dir"
        else
            echo "j: specify a directory or install fzf for interactive picker"
        fi
        return
    fi

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
        # Multiple matches - always pick shortest (fzf only used with no args)
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

# Cargo / rust
export PATH="$HOME/.cargo/bin:$PATH"

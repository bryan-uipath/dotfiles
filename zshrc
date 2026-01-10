
export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


export PATH="$HOME/.local/bin:$PATH"

export GH_NPM_REGISTRY_TOKEN=$(gh auth token)

chrome() {
    osascript -e "tell application \"Google Chrome\" to open location \"$1\""
}

ghui() {
    chrome "https://github.com/UiPath/$1"
}


export EDITOR=vim
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

eval "$(starship init zsh)"

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

# Navigation - j prefix
j() {
  case $1 in
    po)    cd ~/code/PO.Frontend ;;
    flow)  cd ~/code/flow-workbench ;;
    notes) cd ~/code/notes ;;
    *)     cd ~/code/$1 ;;
  esac
}

# Open current dir
alias o="open ."

# aliases.zsh — command aliases, each guarded so a missing tool on another
# machine degrades gracefully instead of erroring.

# Shell shortcuts
alias c=clear
alias w='watch -n1'
alias untar='tar -zxvf '
alias myip='curl ipinfo.io/ip'
alias ec='echo $?'
alias zshconfig="vim $DOTFILESDIR/zsh/.zshrc"
alias dotfiles="cd $DOTFILESDIR"

command -v prettyping &>/dev/null && alias ping=prettyping

# Kubernetes
if command -v kubecolor &>/dev/null; then
  alias kubectl=kubecolor
  alias k=kubecolor
else
  alias k=kubectl
fi
command -v kubectx &>/dev/null && alias kctx=kubectx
command -v kubens &>/dev/null && alias kns=kubens

# Modern CLI replacements
if command -v eza &>/dev/null; then
  alias ls='eza --icons'
  alias ll='eza --icons -l'
  alias la='eza --icons -la'
fi
command -v bat &>/dev/null && alias cat='bat'

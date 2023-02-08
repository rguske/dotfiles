# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# export PATH=$HOME/bin:/usr/local/bin:$PATH
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export TERM="xterm-256color"
export PATH=$PATH:"/home/linuxbrew/.linuxbrew/bin"
#export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# ZSH Theme Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# oh-my-zsh
plugins=(git docker zsh-syntax-highlighting zsh-autosuggestions docker)
source $ZSH/oh-my-zsh.sh

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# kubectl completion
source <(kubectl completion zsh)

# kind completion
source <(kind completion zsh)

# auto-completion/ syntax highlighting
# brew install zsh-autosuggestions zsh-syntax-highlighting
source /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# configure highlighting and auto-suggestions
#ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='bg=235,fg=100'
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=0'

# brew install fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"

# export dotfiles folder https://github.com/rguske/dotfiles
export DOTFILESDIR='$HOME/dotfiles'

# source file for aliases
source ~/.zsh_aliases

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

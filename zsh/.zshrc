# .zshrc — symlinked from $DOTFILESDIR/zsh/.zshrc to ~/.zshrc by install.sh

# Resolve this repo's root directory dynamically by following the symlink
# zsh reads at ~/.zshrc back to wherever this repo actually lives (e.g.
# ~/dotfiles, or a cloud-synced folder) — no path is hardcoded here.
0=${(%):-%N}
export DOTFILESDIR="${0:A:h:h}"

# Auto-attach (or create) a persistent tmux session named "main" for every
# new interactive shell, so every Ghostty window/tab lands inside tmux by
# default. Every such window becomes another view onto the SAME session
# (same windows/panes visible everywhere) rather than an independent one —
# that's intentional, it's what makes the tmux-resurrect/continuum setup
# below actually persistent across Ghostty restarts. Guarded against:
# already being inside tmux ($TMUX set), non-interactive shells (scripts,
# tool invocations), and IDE-embedded terminals (Cursor/VS Code set
# TERM_PROGRAM=vscode) where auto-starting tmux would be unexpected.
if [[ -o interactive ]] && [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" != "vscode" ]] \
  && command -v tmux &>/dev/null; then
  tmux attach -t main 2>/dev/null || tmux new -s main
fi

export ZSH="$HOME/.oh-my-zsh"

# Let Oh My Zsh skip its own compinit call; we run a cached one below so
# shell startup doesn't rebuild the completion dump on every launch.
skip_global_compinit=1

plugins=(git docker fzf-tab)
source "$ZSH/oh-my-zsh.sh"

# Cached, fast compinit: only rebuild the completion dump once every 24h.
autoload -Uz compinit
_zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n "$_zcompdump"(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
unset _zcompdump

# zsh-autosuggestions via Homebrew directly (survives `brew upgrade`, no
# symlink-into-oh-my-zsh fragility).
[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

source "$DOTFILESDIR/zsh/exports.zsh"
source "$DOTFILESDIR/zsh/functions.zsh"
source "$DOTFILESDIR/zsh/completions.zsh"
source "$DOTFILESDIR/zsh/aliases.zsh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# zsh-syntax-highlighting must be sourced last of all zsh widgets/plugins.
[ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

command -v starship &>/dev/null && eval "$(starship init zsh)"

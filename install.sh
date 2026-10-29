#!/usr/bin/env bash
# install.sh — symlink this repo's dotfiles into place, backing up anything
# that already exists first. Safe to re-run any time.
#
# Usage:
#   ./install.sh              # symlink dotfiles only
#   ./install.sh --with-brew  # also run `brew bundle --file Brewfile`

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"
LINKED=()
BACKED_UP=()

if [[ "$(uname -s)" != "Darwin" && "${1:-}" != "--force" ]]; then
  echo "error: this installer currently only supports macOS (pass --force to override)." >&2
  exit 1
fi

link() {
  local src="$1" dest="$2"

  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    return 0 # already correctly linked
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    local rel="${dest#"$HOME"/}"
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    mv "$dest" "$BACKUP_DIR/$rel"
    BACKED_UP+=("$dest")
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  LINKED+=("$dest -> $src")
}

link "$DOTFILES_DIR/zsh/.zshrc"      "$HOME/.zshrc"
link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
link "$DOTFILES_DIR/starship.toml"   "$HOME/.config/starship.toml"
link "$DOTFILES_DIR/ghostty/config"  "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
link "$DOTFILES_DIR/ghostty/wallpaper.jpg" "$HOME/.config/ghostty/wallpaper.jpg"
link "$DOTFILES_DIR/tmux/scripts"    "$HOME/.config/tmux/scripts"

# The old ~/.zsh_aliases is superseded by zsh/aliases.zsh (sourced from the
# new .zshrc) — back it up out of the way if it's still sitting there.
if [[ -e "$HOME/.zsh_aliases" && ! -L "$HOME/.zsh_aliases" ]]; then
  mkdir -p "$BACKUP_DIR"
  mv "$HOME/.zsh_aliases" "$BACKUP_DIR/.zsh_aliases"
  BACKED_UP+=("$HOME/.zsh_aliases")
fi

# TPM (tmux plugin manager)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  echo "Cloned TPM. Start tmux and press 'prefix + I' (capital i) to install tmux plugins."
fi

# fzf-tab (no Homebrew formula; installed as an Oh My Zsh custom plugin)
if [[ -d "$HOME/.oh-my-zsh" && ! -d "$HOME/.oh-my-zsh/custom/plugins/fzf-tab" ]]; then
  git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$HOME/.oh-my-zsh/custom/plugins/fzf-tab"
fi

if [[ "${1:-}" == "--with-brew" ]]; then
  brew bundle --file "$DOTFILES_DIR/Brewfile"
fi

echo
echo "=== install.sh summary ==="
if [[ ${#BACKED_UP[@]} -gt 0 ]]; then
  echo "Backed up (see $BACKUP_DIR):"
  printf '  %s\n' "${BACKED_UP[@]}"
fi
if [[ ${#LINKED[@]} -gt 0 ]]; then
  echo "Linked:"
  printf '  %s\n' "${LINKED[@]}"
else
  echo "Everything was already linked correctly — nothing to do."
fi

# functions.zsh — reusable shell functions.

# theme [light|dark] — switch Ghostty, tmux, and the Starship prompt
# together between Catppuccin Mocha (dark) and Catppuccin Latte (light).
# No argument toggles based on Ghostty's current theme.
#
# Edits the real files inside $DOTFILESDIR (not the ~-symlinked paths) —
# sed -i replaces a file in place by renaming a temp file over it, which
# would silently turn a symlink into a regular file if run on the ~ path
# instead, breaking the "symlinked from the repo" setup everything else
# here relies on. Reading through the ~ symlink (e.g. `tmux source-file
# ~/.tmux.conf`) is fine; only *writing* through it is the problem.
#
# tmux and Starship pick this up live (tmux via an explicit reload below,
# Starship because it re-reads starship.toml on every prompt). Ghostty has
# no file-watcher, so press its reload-config keybind (cmd+shift+,) or
# restart it to see the new theme/background there.
#
# This edits tracked dotfiles, so `git status` in $DOTFILESDIR will show a
# pending change after switching — that's expected local state, not a bug;
# commit it only if you want the new theme to be the repo's default too.
theme() {
  local mode="$1"
  local ghostty_conf="$DOTFILESDIR/ghostty/config"
  local tmux_conf="$DOTFILESDIR/tmux/.tmux.conf"
  local starship_conf="$DOTFILESDIR/starship.toml"

  if [[ -z "$mode" ]]; then
    if grep -q '^theme = "Catppuccin Mocha"' "$ghostty_conf" 2>/dev/null; then
      mode="light"
    else
      mode="dark"
    fi
  fi

  case "$mode" in
    dark)
      sed -i '' 's/^theme = "Catppuccin Latte"/theme = "Catppuccin Mocha"/' "$ghostty_conf"
      sed -i '' 's/^set -g @catppuccin_flavor "latte"/set -g @catppuccin_flavor "mocha"/' "$tmux_conf"
      sed -i '' 's/^palette = "catppuccin_latte"/palette = "catppuccin_mocha"/' "$starship_conf"
      ;;
    light)
      sed -i '' 's/^theme = "Catppuccin Mocha"/theme = "Catppuccin Latte"/' "$ghostty_conf"
      sed -i '' 's/^set -g @catppuccin_flavor "mocha"/set -g @catppuccin_flavor "latte"/' "$tmux_conf"
      sed -i '' 's/^palette = "catppuccin_mocha"/palette = "catppuccin_latte"/' "$starship_conf"
      ;;
    *)
      echo "usage: theme [light|dark]" >&2
      return 1
      ;;
  esac

  if [[ -n "$TMUX" ]]; then
    tmux source-file "$tmux_conf" >/dev/null 2>&1
  fi

  echo "theme: switched to $mode."
  echo "  tmux + Starship: applied now."
  echo "  Ghostty: press cmd+shift+, (or restart) to apply."
}

# Terminal & Dotfiles Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current half-wired Ghostty/zsh/tmux setup with a Kubernetes-aware, Catppuccin-themed terminal stack (Starship + Oh My Zsh + tmux/TPM + Ghostty), fully captured in the `rguske/dotfiles` repo and installable on any machine via `install.sh`.

**Architecture:** A flat, single-purpose-per-file dotfiles repo. zsh config is split into `exports.zsh` / `functions.zsh` / `completions.zsh` / `aliases.zsh`, sourced in that order from `.zshrc`. Starship (`starship.toml`), tmux (`tmux/.tmux.conf` + a small status-bar helper script), and Ghostty (`ghostty/config`) are independent, self-contained config files. `install.sh` is the only script that touches `$HOME`; it symlinks every managed file into place, backing up anything it would overwrite first.

**Tech Stack:** zsh, Oh My Zsh, Starship, tmux + TPM, Ghostty, Homebrew (`Brewfile`), bash (`install.sh`), git/GitHub.

## Global Constraints

- Repository root for all work in this plan: `/Users/rguske/Library/CloudStorage/GoogleDrive-robert.guske@googlemail.com/My Drive/dev/dotfiles` (existing `rguske/dotfiles` GitHub repo; remote `origin` already configured over SSH; `gh` already authenticated). All file paths below are relative to this root unless given as an absolute `$HOME`-based path.
- macOS only — Homebrew paths and the Ghostty config location assume Darwin. `install.sh` must refuse to run on non-Darwin without a `--force` flag.
- Keep Oh My Zsh as the zsh framework. Do not introduce Zinit or any other framework.
- tmux prefix is `Ctrl-a` (default `Ctrl-b` is freed).
- The Starship `kubernetes` module must always render `context(namespace)` (never directory-scoped), and must render context names matching `(?i).*prod.*` in bold red via `[[kubernetes.contexts]]`.
- Every optional external tool (`oc`, `kind`, `crc`, `kubecolor`, `eza`, `bat`, `zoxide`, `prettyping`) must be guarded with `command -v <tool> &>/dev/null` so its absence on another machine never breaks the shell.
- Dotfiles are installed via a dependency-free `install.sh` (no GNU Stow, no chezmoi). It must be idempotent and must back up anything it would overwrite to `~/.dotfiles_backup/<timestamp>/` before symlinking.
- Unused leftovers already on disk (`~/.p10k.zsh`, the old `~/.config/starship.toml` stub, `~/.oh-my-zsh/plugins/kube-ps1`, `~/.config/tmux/plugins/catppuccin` and `catppuccin_bck`) must be left untouched and unreferenced — do not delete them as part of this plan.
- `$DOTFILESDIR` must never be hardcoded to a specific clone path (e.g. not hardcoded to `~/dotfiles` or to the Google Drive path) — it must be resolved dynamically from the location of the sourced `.zshrc` file, so the same repo works whether it's cloned to `~/dotfiles` or synced inside a cloud-storage folder.

---

## Task 1: Repo skeleton + Brewfile

**Files:**
- Create: `Brewfile`
- Create: `.gitignore`

**Interfaces:**
- Consumes: nothing.
- Produces: `Brewfile` listing every Homebrew dependency used by later tasks (consumed by Task 2 and by `install.sh` in Task 11's `--with-brew` flag).

- [ ] **Step 1: Create `.gitignore`**

```gitignore
.DS_Store
```

- [ ] **Step 2: Create `Brewfile`**

```ruby
# Brewfile — reproducible package list for the terminal setup.
# Install everything with: brew bundle --file Brewfile

cask "ghostty"

brew "tmux"
brew "starship"
brew "zoxide"
brew "eza"
brew "bat"
brew "kubecolor"
brew "prettyping"
brew "fzf"
brew "kubectx"
brew "k9s"
brew "gh"
```

- [ ] **Step 3: Verify the Brewfile parses**

Run: `brew bundle list --all --file=Brewfile`
Expected: prints the list of casks/formulae (`ghostty`, `tmux`, `starship`, `zoxide`, `eza`, `bat`, `kubecolor`, `prettyping`, `fzf`, `kubectx`, `k9s`, `gh`) with no syntax errors. (`--all` is required: current Homebrew's `brew bundle list` defaults to formulae-only and silently omits casks like `ghostty` without it.)

- [ ] **Step 4: Commit**

```bash
git add .gitignore Brewfile
git commit -m "chore: add Brewfile and gitignore"
```

---

## Task 2: Install Homebrew packages

**Files:** none created/modified (execution-only task).

**Interfaces:**
- Consumes: `Brewfile` (Task 1).
- Produces: `starship`, `zoxide`, `eza`, `bat`, `kubecolor`, `prettyping` binaries on `$PATH`, needed by the real-tool verification steps in Tasks 6, 8, and 9.

- [ ] **Step 1: Install everything declared in the Brewfile**

Run: `brew bundle --file Brewfile`
Expected: exits 0; already-installed formulae (`tmux`, `fzf`, `kubectx`, `k9s`, `gh`, `ghostty`) are skipped, new ones (`starship`, `zoxide`, `eza`, `bat`, `kubecolor`, `prettyping`) are installed.

- [ ] **Step 2: Verify**

Run: `brew bundle check --file=Brewfile`
Expected: `The Brewfile's dependencies are satisfied.` (exit 0)

- [ ] **Step 3: Commit**

Nothing to commit (no files changed) — skip.

---

## Task 3: `zsh/exports.zsh`

**Files:**
- Create: `zsh/exports.zsh`

**Interfaces:**
- Consumes: nothing.
- Produces: `$LANG`, `$TERM`, `$GOPATH`, `$PATH` additions. Sourced by `.zshrc` (Task 7).

- [ ] **Step 1: Create the file**

```zsh
# exports.zsh — environment variables and $PATH additions

export LANG=en_US.UTF-8
export TERM="xterm-256color"

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Cursor Agent CLI
export PATH="$HOME/.local/bin:$PATH"
```

- [ ] **Step 2: Verify syntax**

Run: `zsh -n zsh/exports.zsh`
Expected: no output, exit 0.

- [ ] **Step 3: Verify it sets the expected variables**

Run: `zsh -c 'source zsh/exports.zsh; echo "$LANG|$GOPATH"'`
Expected: `en_US.UTF-8|/Users/rguske/go`

- [ ] **Step 4: Commit**

```bash
git add zsh/exports.zsh
git commit -m "feat(zsh): add exports.zsh"
```

---

## Task 4: `zsh/functions.zsh`

**Files:**
- Create: `zsh/functions.zsh`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing yet (scaffold). Sourced by `.zshrc` (Task 7).

- [ ] **Step 1: Create the file**

```zsh
# functions.zsh — reusable shell functions.
#
# Empty scaffold for now. Add workflow-specific functions here as they come
# up; because this file is sourced from .zshrc, new functions never require
# touching .zshrc again.
```

- [ ] **Step 2: Verify syntax**

Run: `zsh -n zsh/functions.zsh`
Expected: no output, exit 0.

- [ ] **Step 3: Commit**

```bash
git add zsh/functions.zsh
git commit -m "feat(zsh): add functions.zsh scaffold"
```

---

## Task 5: `zsh/completions.zsh`

**Files:**
- Create: `zsh/completions.zsh`

**Interfaces:**
- Consumes: `compdef`/`compinit` must already be initialized by the time this file is sourced (handled by `.zshrc` in Task 7, which sources this file after `compinit`).
- Produces: zsh completions for `kubectl`, `kind`, `crc`, `oc` when each is present. Sourced by `.zshrc` (Task 7).

- [ ] **Step 1: Create the file**

```zsh
# completions.zsh — shell completions for CLI tools, each guarded so a
# missing tool on another machine doesn't break the shell.
# NOTE: compinit must already have run before this file is sourced.

if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh)
fi

if command -v kind &>/dev/null; then
  source <(kind completion zsh)
fi

if command -v crc &>/dev/null; then
  source <(crc completion zsh)
fi

if command -v oc &>/dev/null; then
  source <(oc completion zsh)
  compdef _oc oc
fi
```

- [ ] **Step 2: Verify syntax**

Run: `zsh -n zsh/completions.zsh`
Expected: no output, exit 0.

- [ ] **Step 3: Verify it sources cleanly with compinit already run**

Run: `zsh -c 'autoload -Uz compinit && compinit -C && source zsh/completions.zsh && echo OK'`
Expected: `OK` with no errors (guards skip any tool not installed; `kubectl` is installed on this machine so its completion loads without error).

- [ ] **Step 4: Commit**

```bash
git add zsh/completions.zsh
git commit -m "feat(zsh): add guarded completions.zsh"
```

---

## Task 6: `zsh/aliases.zsh`

**Files:**
- Create: `zsh/aliases.zsh`

**Interfaces:**
- Consumes: `$DOTFILESDIR` (exported by `.zshrc`, Task 7) for the `zshconfig`/`dotfiles` aliases.
- Produces: aliases `c`, `w`, `untar`, `myip`, `ec`, `zshconfig`, `dotfiles`, `ping` (if `prettyping` present), `k`/`kubectl` (via `kubecolor` if present), `kctx`, `kns`, `ls`/`ll`/`la` (via `eza` if present), `cat` (via `bat` if present). Sourced by `.zshrc` (Task 7).

- [ ] **Step 1: Create the file**

```zsh
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
```

- [ ] **Step 2: Verify syntax**

Run: `zsh -n zsh/aliases.zsh`
Expected: no output, exit 0.

- [ ] **Step 3: Verify aliases resolve with `$DOTFILESDIR` set and real tools present**

Run: `zsh -c 'export DOTFILESDIR=/tmp/dotfiles-test; source zsh/aliases.zsh; alias zshconfig; alias k; alias ls'`
Expected: `zshconfig='vim /tmp/dotfiles-test/zsh/.zshrc'`, `k=kubecolor` (since `kubecolor` was installed in Task 2), `ls='eza --icons'` (since `eza` was installed in Task 2).

- [ ] **Step 4: Commit**

```bash
git add zsh/aliases.zsh
git commit -m "feat(zsh): add guarded aliases.zsh"
```

---

## Task 7: `zsh/.zshrc`

**Files:**
- Create: `zsh/.zshrc`

**Interfaces:**
- Consumes: `zsh/exports.zsh`, `zsh/functions.zsh`, `zsh/completions.zsh`, `zsh/aliases.zsh` (Tasks 3–6) via `$DOTFILESDIR`-relative `source` calls; Homebrew-installed `zsh-autosuggestions`, `zsh-syntax-highlighting`, `starship`, `zoxide` binaries (optional, each guarded).
- Produces: `$DOTFILESDIR` (exported, dynamically resolved — never hardcoded), the full interactive shell environment. This is the file `install.sh` (Task 11) symlinks to `~/.zshrc`.

- [ ] **Step 1: Create the file**

```zsh
# .zshrc — symlinked from $DOTFILESDIR/zsh/.zshrc to ~/.zshrc by install.sh

# Resolve this repo's root directory dynamically by following the symlink
# zsh reads at ~/.zshrc back to wherever this repo actually lives (e.g.
# ~/dotfiles, or a cloud-synced folder) — no path is hardcoded here.
0=${(%):-%N}
export DOTFILESDIR="${0:A:h:h}"

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
```

- [ ] **Step 2: Verify syntax**

Run: `zsh -n zsh/.zshrc`
Expected: no output, exit 0.

- [ ] **Step 3: Verify it runs end-to-end from a symlink (proves the dynamic `$DOTFILESDIR` resolution works)**

This keeps the real `$HOME` (so the real Oh My Zsh / Homebrew installs resolve
normally, matching the actual target environment) and only tests that
sourcing `.zshrc` through a symlink placed somewhere else still resolves
`$DOTFILESDIR` to this repo, not to the symlink's own directory:

```bash
tmp_dir=$(mktemp -d)
ln -s "$(pwd)/zsh/.zshrc" "$tmp_dir/.zshrc"
zsh -c "source '$tmp_dir/.zshrc'; echo DOTFILESDIR=\$DOTFILESDIR; alias k"
rm -rf "$tmp_dir"
```

Expected: `DOTFILESDIR=<absolute path to this repo>` (the real repo path, **not** `$tmp_dir` — proving the symlink was followed back to the real file), followed by the `k=kubecolor` alias line, with no error output.

- [ ] **Step 4: Commit**

```bash
git add zsh/.zshrc
git commit -m "feat(zsh): add .zshrc entrypoint"
```

---

## Task 8: `starship.toml`

**Files:**
- Create: `starship.toml`

**Interfaces:**
- Consumes: nothing (standalone config).
- Produces: the Starship prompt definition. Consumed by `starship init zsh` in `.zshrc` (Task 7) at runtime, and symlinked to `~/.config/starship.toml` by `install.sh` (Task 11).

- [ ] **Step 1: Create the file**

```toml
# starship.toml — prompt: path, git, and an always-on Kubernetes
# context/namespace indicator that turns bold red for prod-like contexts.

format = """
$directory\
$git_branch\
$git_status\
$kubernetes\
$line_break\
$character"""

palette = "catppuccin_mocha"

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"

[directory]
style = "bold lavender"
truncation_length = 3
truncate_to_repo = true
read_only = " 🔒"
format = "[$path]($style)[$read_only]($read_only_style) "

[git_branch]
style = "bold mauve"
format = "on [$symbol$branch]($style) "

[git_status]
style = "bold peach"
format = "([$all_status$ahead_behind]($style) )"

[kubernetes]
disabled = false
format = '[⎈ $context($namespace)]($style) '
style = "bold blue"

[[kubernetes.contexts]]
# Case-insensitive "contains prod" match. NOTE: (?i) is unsupported by this
# starship build's regex engine (it silently fails to compile and the rule
# gets dropped) — do not "simplify" this back to (?i).*prod.*.
context_pattern = ".*[Pp][Rr][Oo][Dd].*"
style = "bold red"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"
```

- [ ] **Step 2: Verify the config loads and renders without error**

Run: `STARSHIP_CONFIG="$(pwd)/starship.toml" starship prompt`
Expected: prints a single rendered prompt line (directory + possibly git/k8s segments) to stdout with no error/warning on stderr.

- [ ] **Step 3: Verify the Kubernetes module renders and prod-matching contexts turn red**

```bash
STARSHIP_CONFIG="$(pwd)/starship.toml" starship module kubernetes \
  --path . 2>&1 | cat -v
```

Expected: no error output. (If no kube context is active the segment may be empty — that's fine; this step is checking for config/schema errors, not live cluster state. Live context/namespace behavior is verified end-to-end in Task 13.)

- [ ] **Step 4: Commit**

```bash
git add starship.toml
git commit -m "feat(prompt): add starship.toml with kubernetes/git/directory modules"
```

---

## Task 9: tmux config + status-bar helper script

**Files:**
- Create: `tmux/scripts/k8s-status.sh`
- Create: `tmux/.tmux.conf`

**Interfaces:**
- Consumes: `kubectl` (optional, guarded) from `tmux/scripts/k8s-status.sh`; TPM must be cloned to `~/.tmux/plugins/tpm` for the plugin line at the bottom to do anything (handled by `install.sh`, Task 11; harmless no-op if missing).
- Produces: `tmux/.tmux.conf`, symlinked to `~/.tmux.conf` by `install.sh`. `tmux/scripts/` symlinked to `~/.config/tmux/scripts` by `install.sh`, referenced from `.tmux.conf` as `~/.config/tmux/scripts/k8s-status.sh`.

- [ ] **Step 1: Create the status-bar helper script**

```bash
#!/usr/bin/env bash
# Prints "<context>/<namespace>" for the tmux status bar, falling back
# gracefully when kubectl isn't configured or installed.

if ! command -v kubectl &>/dev/null; then
  exit 0
fi

context=$(kubectl config current-context 2>/dev/null) || exit 0
namespace=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
echo "${context}/${namespace:-default}"
```

- [ ] **Step 2: Make it executable**

```bash
mkdir -p tmux/scripts
chmod +x tmux/scripts/k8s-status.sh
```

- [ ] **Step 3: Verify the script**

Run: `bash -n tmux/scripts/k8s-status.sh && ./tmux/scripts/k8s-status.sh`
Expected: `bash -n` prints nothing (valid syntax); running it prints `<your-current-context>/<namespace-or-default>` (e.g. `docker-desktop/default`) since `kubectl` is installed on this machine, with no error.

- [ ] **Step 4: Create `tmux/.tmux.conf`**

```tmux
# ~/.tmux.conf — symlinked from $DOTFILESDIR/tmux/.tmux.conf by install.sh

# Prefix: Ctrl-a instead of the default Ctrl-b
unbind C-b
set -g prefix C-a
bind C-a send-prefix

set -g mouse on
set -g default-terminal "tmux-256color"

# Intuitive splits, preserving the current pane's working directory
unbind '"'
unbind %
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Reload config without restarting tmux
bind r source-file ~/.tmux.conf \; display-message "tmux config reloaded"

# ---- Plugins (managed by TPM: https://github.com/tmux-plugins/tpm) ----
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux'
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin 'tmux-plugins/tmux-battery'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'

# Catppuccin theme
set -g @catppuccin_flavor "mocha"
set -g @catppuccin_window_status_style "rounded"

# Auto-save/restore sessions across reboots
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# Status bar: session/CPU/app (left via catppuccin) ; k8s context+namespace,
# battery (right)
set -g status-left-length 100
set -g status-right-length 100
set -g status-left ""
set -g status-right "#{E:@catppuccin_status_application}"
set -agF status-right "#{E:@catppuccin_status_cpu}"
set -ag status-right "#(~/.config/tmux/scripts/k8s-status.sh)"
set -ag status-right "#{E:@catppuccin_status_session}"
set -agF status-right "#{E:@catppuccin_status_battery}"

# Initialize TPM (must be the last line in this file)
run '~/.tmux/plugins/tpm/tpm'
```

- [ ] **Step 5: Verify the config starts a real tmux server without fatal errors**

```bash
tmux -f tmux/.tmux.conf -L plan-verify new-session -d -s t "sleep 2"
tmux -L plan-verify list-sessions
tmux -L plan-verify kill-server
```

Expected: `list-sessions` prints a line like `t: 1 windows ...`; no fatal `tmux: ` parse errors on stderr (a one-line message that TPM's `run` script is missing is expected and harmless at this point — TPM isn't cloned until Task 11/13 — but the server must still start and `list-sessions` must succeed).

- [ ] **Step 6: Commit**

```bash
git add tmux/
git commit -m "feat(tmux): add tmux.conf (Ctrl-a prefix, TPM plugins, k8s status segment)"
```

---

## Task 10: `ghostty/config`

**Files:**
- Create: `ghostty/config`

**Interfaces:**
- Consumes: nothing.
- Produces: `ghostty/config`, symlinked by `install.sh` (Task 11) to `~/Library/Application Support/com.mitchellh.ghostty/config`.

- [ ] **Step 1: Create the file**

```
theme = catppuccin-mocha
shell-integration = zsh

# macos-titlebar-style = hidden
font-family = "SauceCodePro NFM Light"
font-size = 12
cursor-style = bar
# background-opacity = 0.9
background-blur-radius = 20

keybind = global:ctrl+grave_accent=toggle_quick_terminal
```

- [ ] **Step 2: Verify Ghostty accepts the config without error**

Run: `/Applications/Ghostty.app/Contents/MacOS/ghostty +show-config --config-file="$(pwd)/ghostty/config" 2>&1 | head -20`
Expected: prints the resolved configuration (including `theme = catppuccin-mocha` and `shell-integration = zsh`) with no `error:`/`unknown key` lines. (Full visual verification — the theme actually rendering — happens in Task 13 when the config is symlinked and Ghostty is restarted.)

- [ ] **Step 3: Commit**

```bash
git add ghostty/
git commit -m "feat(ghostty): enable catppuccin-mocha theme and shell-integration"
```

---

## Task 11: `install.sh`

**Files:**
- Create: `install.sh`

**Interfaces:**
- Consumes: `zsh/.zshrc`, `tmux/.tmux.conf`, `tmux/scripts/`, `starship.toml`, `ghostty/config` (Tasks 7–10), `Brewfile` (Task 1).
- Produces: symlinks under `$HOME` (see Step 1), clones of TPM and `fzf-tab`, and (with `--with-brew`) a `brew bundle` install. This is the script the user runs on any machine to reproduce the whole setup.

- [ ] **Step 1: Create the file**

```bash
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
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x install.sh
```

- [ ] **Step 3: Verify syntax**

Run: `bash -n install.sh`
Expected: no output, exit 0.

- [ ] **Step 4: Verify against a fake `$HOME` (does not touch your real dotfiles)**

```bash
tmp_home=$(mktemp -d)
mkdir -p "$tmp_home/.oh-my-zsh/custom/plugins" \
         "$tmp_home/Library/Application Support/com.mitchellh.ghostty" \
         "$tmp_home/.config"
echo "pretend old zshrc" > "$tmp_home/.zshrc"

HOME="$tmp_home" bash install.sh

test -L "$tmp_home/.zshrc" && readlink "$tmp_home/.zshrc"
test -L "$tmp_home/.tmux.conf" && readlink "$tmp_home/.tmux.conf"
test -L "$tmp_home/.config/starship.toml" && readlink "$tmp_home/.config/starship.toml"
test -L "$tmp_home/Library/Application Support/com.mitchellh.ghostty/config"
test -L "$tmp_home/.config/tmux/scripts" && readlink "$tmp_home/.config/tmux/scripts"
test -d "$tmp_home/.tmux/plugins/tpm"
test -d "$tmp_home/.oh-my-zsh/custom/plugins/fzf-tab"
cat "$tmp_home/.dotfiles_backup"/*/.zshrc
```

Expected: every `readlink` prints an absolute path inside this repo; all `test` commands exit 0 (no output, since `test` is silent on success — a nonzero exit would print nothing either, so rely on `echo $?` after each if you want explicit confirmation); the final `cat` prints `pretend old zshrc`, proving the pre-existing file was backed up rather than clobbered.

- [ ] **Step 5: Verify idempotency (second run does nothing destructive)**

Run: `HOME="$tmp_home" bash install.sh`
Expected: output ends with `Everything was already linked correctly — nothing to do.` and no new backup folder is created under `$tmp_home/.dotfiles_backup/`.

```bash
ls "$tmp_home/.dotfiles_backup" | wc -l   # expect: 1 (only the first run's backup)
rm -rf "$tmp_home"
```

- [ ] **Step 6: Commit**

```bash
git add install.sh
git commit -m "feat: add idempotent install.sh"
```

---

## Task 12: `README.md`

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: nothing (documentation only).
- Produces: usage instructions for a human cloning this repo on a new machine.

- [ ] **Step 1: Replace the file contents**

```markdown
# dotfiles

Personal terminal setup: Ghostty + zsh (Oh My Zsh) + Starship + tmux, with a
Kubernetes-aware prompt that always shows the current context/namespace and
auto-flags anything matching "prod" in bold red.

## What's here

| Path                   | Purpose                                                |
|------------------------|---------------------------------------------------------|
| `zsh/.zshrc`           | Main zsh entrypoint, symlinked to `~/.zshrc`            |
| `zsh/exports.zsh`      | Environment variables / `$PATH`                         |
| `zsh/functions.zsh`    | Reusable shell functions                                 |
| `zsh/completions.zsh`  | Guarded CLI completions (kubectl, kind, crc, oc)         |
| `zsh/aliases.zsh`      | Aliases, each guarded against missing tools              |
| `starship.toml`        | Prompt config — path, git, Kubernetes context/namespace  |
| `tmux/.tmux.conf`      | tmux config (prefix `Ctrl-a`, TPM-managed plugins)       |
| `tmux/scripts/`        | Helper scripts used by the tmux status bar               |
| `ghostty/config`       | Ghostty terminal config (Catppuccin Mocha theme)         |
| `Brewfile`             | Every Homebrew package this setup depends on             |
| `install.sh`           | Idempotent installer — symlinks everything into place    |

## Install on a new machine

```bash
git clone git@github.com:rguske/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --with-brew
exec zsh
```

Inside tmux, press `prefix + I` (capital i; prefix is `Ctrl-a`) once so TPM
installs the plugins declared in `tmux/.tmux.conf`.

## Re-running

`install.sh` is idempotent and safe to re-run. Anything it would overwrite is
backed up first to `~/.dotfiles_backup/<timestamp>/`.

## Kubernetes prompt

The Starship `kubernetes` module always shows `⎈ <context>(<namespace>)` and
switches to bold red automatically when the context name contains "prod" —
see `[[kubernetes.contexts]]` in `starship.toml` to add more patterns. The
same context/namespace also appears in the tmux status bar via
`tmux/scripts/k8s-status.sh`.
```

- [ ] **Step 2: Verify**

Run: `cat README.md | head -5`
Expected: starts with `# dotfiles` followed by the one-line description above.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document setup and install instructions"
```

---

## Task 13: Real install + end-to-end verification

**Files:** none created/modified (verification-only task against the real `$HOME`).

**Interfaces:**
- Consumes: every file produced by Tasks 1–12.
- Produces: the live, working setup on this machine.

- [ ] **Step 1: Run the real installer**

Run: `./install.sh --with-brew`
Expected: summary printed; existing `~/.zshrc`, `~/.zsh_aliases`, `~/.tmux.conf`, and the Ghostty config are listed under "Backed up"; all five targets listed under "Linked"; `brew bundle` reports dependencies satisfied.

- [ ] **Step 2: Reload the shell and confirm no errors**

Run: `exec zsh -c 'pwd; echo DOTFILESDIR=$DOTFILESDIR'`
Expected: `pwd` prints `$HOME` (the old forced `cd` into the Google Drive folder is gone), `DOTFILESDIR` points at this repo, no error/warning lines printed anywhere in the session.

- [ ] **Step 3: Confirm the prompt renders with icons**

Open a new Ghostty window/tab, run `cd ~ && ls`.
Expected: the prompt shows a colored path segment and (inside a git repo) a git branch segment with no missing-glyph boxes (confirms the Nerd Font + Starship init wiring).

- [ ] **Step 4: Confirm live Kubernetes context/namespace updates**

```bash
kubectx            # list available contexts
kubectx <some-context>
kubens <some-namespace>
```

Expected: immediately after each command, the next prompt line shows `⎈ <context>(<namespace>)` matching what was just set. If `<some-context>` contains "prod", the whole segment renders in bold red.

- [ ] **Step 5: Confirm tmux**

```bash
tmux kill-server 2>/dev/null; tmux
```
Then inside tmux: press `Ctrl-a` then `I` (capital i) to install TPM plugins, then `Ctrl-a` then `|` to split, `Ctrl-a` then `r` to reload.
Expected: prefix is `Ctrl-a` (`Ctrl-b` does nothing), status bar shows CPU/battery/context-namespace segments once TPM finishes installing plugins, `|` splits vertically into two panes sharing the same cwd, `r` reloads without error.

- [ ] **Step 6: Confirm Ghostty theme**

Quit and reopen Ghostty.
Expected: Catppuccin Mocha colors are applied (matches the saved `terminal/catppuccin-mocha.itermcolors` palette), and a new tab/split opens in the same working directory as the pane it was spawned from (confirms `shell-integration = zsh` is active).

- [ ] **Step 7: Record the outcome**

If any expectation in Steps 2–6 fails, fix the relevant file from Tasks 3–10 (not this task) and re-run Step 1 before proceeding. Do not commit from this task — it only verifies work already committed in prior tasks.

---

## Task 14: Push to GitHub

**Files:** none (git operation only).

**Interfaces:**
- Consumes: all commits from Tasks 1–12.
- Produces: `rguske/dotfiles` on GitHub fully up to date.

- [ ] **Step 1: Confirm the local history is what you expect**

Run: `git log --oneline origin/main..HEAD`
Expected: lists every commit made in Tasks 1, 3–12 (Task 2 and Task 13 made no commits).

- [ ] **Step 2: Push**

Run: `git push origin main`
Expected: push succeeds; `git log --oneline origin/main..HEAD` now prints nothing.

- [ ] **Step 3: Verify on GitHub**

Run: `gh repo view rguske/dotfiles --web=false` and `gh api repos/rguske/dotfiles/commits --jq '.[0].commit.message'`
Expected: the latest commit message matches the last local commit from Task 12 (`docs: document setup and install instructions`) or later.

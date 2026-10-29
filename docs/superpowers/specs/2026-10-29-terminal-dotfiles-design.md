# Terminal & Dotfiles Overhaul — Design

**Date:** 2026-10-29
**Status:** Approved

## Goal

Replace the current ad-hoc, partially-broken terminal setup (Ghostty + zsh + tmux) with a
slick, fast, Kubernetes-aware setup that is fully captured in dotfiles and reproducible on
any new machine via a single install script + Brewfile. Pushed to the existing
`github.com/rguske/dotfiles` repo.

## Current State (baseline, discovered during brainstorming)

- `~/.zshrc` / `~/.zsh_aliases`: Oh My Zsh (`plugins=(git docker)`), `zsh-autosuggestions` /
  `zsh-syntax-highlighting` sourced from Homebrew, `fzf` sourced, `kubectl`/`kind`/`crc`/`oc`
  completions sourced unconditionally, a dead `powerline-go` precmd hook driving the prompt,
  and a hardcoded `cd` into the Google Drive dev folder on every shell start.
- `~/.p10k.zsh` (95 KB, fully configured), `~/.config/starship.toml` (stub), and an Oh My Zsh
  `kube-ps1` plugin all exist on disk but are **not** referenced from `.zshrc` — orphaned
  leftovers from previous experiments.
- No Kubernetes context/namespace indicator is actually active today.
- `~/.tmux.conf`: Catppuccin Mocha styling, `tmux-cpu`/`tmux-battery` wired via direct `run`
  paths. The Catppuccin plugin itself is present (manually cloned to
  `~/.config/tmux/plugins/catppuccin/tmux/`, plus an unused `catppuccin_bck` copy) — it was
  never broken, just not managed by TPM. TPM is installed at `~/.tmux/plugins/tpm` but never
  invoked — plugins are a mix of manually-cloned and hand-wired `run` lines instead of a
  single managed list.
- `~/.config/ghostty` config (under Application Support): `theme = "Apple System Colors"`
  (a `catppuccin-mocha` line is present but commented out), Nerd Font set, cursor/blur
  configured, `shell-integration = zsh` is commented out, a quick-terminal keybind exists.
- `github.com/rguske/dotfiles`: exists, empty except README, `gh` CLI already authenticated
  with push access via the `origin` remote (SSH).
- Already installed via Homebrew: `fzf`, `gh`, `k9s`, `kubectx`/`kubens`, `tmux`,
  `tmux-mem-cpu-load`. tmux plugins already on disk: `tpm`, `tmux-cpu`, `tmux-battery`,
  `tmux-pomodoro-plus`. Not installed: `starship`, `zoxide`, `eza`, `bat`, `kubecolor`.

## Decisions (confirmed with user)

| Decision | Choice |
|---|---|
| Prompt engine | Starship |
| Zsh framework | Keep Oh My Zsh |
| tmux prefix | `Ctrl-a` |
| Ghostty/tmux relationship | tmux is the real multiplexer inside a single Ghostty window/tab; Ghostty native tabs remain available for quick scratch windows |
| Kubernetes context styling | Always show context+namespace; auto-flag prod-like context names in red |
| Extra CLI tools | eza, bat, zoxide, kubecolor, fzf-tab |
| Dotfiles install tooling | Custom `install.sh` symlink script (no extra dependency) |
| Auto-cd into Google Drive folder | Remove — shell starts in `$HOME` |

## Architecture

```
dotfiles/
├── README.md                 # setup + usage instructions
├── install.sh                 # idempotent installer: backup + symlink + optional brew bundle
├── Brewfile                    # reproducible package list
├── starship.toml
├── zsh/
│   ├── .zshrc
│   ├── aliases.zsh
│   ├── exports.zsh
│   ├── functions.zsh
│   └── completions.zsh
├── tmux/
│   └── .tmux.conf
└── ghostty/
    └── config
```

Each component is independently testable/sourceable:
- `starship.toml` is consumed only by the `starship init zsh` call in `.zshrc`; it has no
  dependency on any other file in the repo and can be validated with `starship config` /
  `starship explain`.
- `zsh/*.zsh` files are sourced in a fixed order from `.zshrc`:
  `exports.zsh` → `functions.zsh` → `completions.zsh` → `aliases.zsh`. Each file guards
  tool-specific logic with `command -v <tool> &>/dev/null` so a missing tool degrades
  gracefully instead of throwing errors on another machine.
- `tmux/.tmux.conf` depends only on TPM being cloned to `~/.tmux/plugins/tpm` (handled by
  `install.sh`).
- `ghostty/config` is a flat key-value file with no cross-file dependency.
- `install.sh` is the only piece that touches `$HOME` directly; every other file is inert
  until symlinked.

## Component Details

### 1. Starship (`starship.toml`)

- `[kubernetes]`: `disabled = false`, format `"⎈ $context($namespace) "`, always on
  (no `detect_files`/`detect_folders` restriction — per "always show" decision).
  Uses `[[kubernetes.contexts]]` entries with `context_pattern = "(?i)prod"` to override
  `style = "bold red"` for anything matching prod/production; default style is a calmer
  Catppuccin accent (mauve/blue).
- `[directory]`: `truncation_length = 3`, `truncate_to_repo = true`, home substituted with
  `~`, read-only icon enabled.
- `[git_branch]` / `[git_status]`: enabled, standard Catppuccin coloring.
- `[character]`: success/error coloring of the prompt symbol.
- Palette: Catppuccin Mocha hex values, matching tmux and Ghostty theme.

### 2. zsh

- `.zshrc` responsibilities only: set `$ZSH`, `plugins=(git docker zsh-autosuggestions
  zsh-syntax-highlighting fzf-tab)`, source Oh My Zsh, `eval "$(starship init zsh)"`,
  `eval "$(zoxide init zsh)"`, source the four support files in the order above, `compinit`
  with a once-per-day cache rebuild (`compinit -C` guarded by comparing dump file mtime).
- `aliases.zsh`: existing aliases preserved (`k`, `kctx`, `kns`, `c`, `w`, `ec`, etc.), plus
  `ls`/`ll`/`la` → `eza` equivalents, `cat` → `bat`, `k`/`kubectl` → `kubecolor` wrapper
  (all guarded by `command -v` checks).
- `functions.zsh`: any reusable shell functions (currently none beyond what exists; kept as
  an empty scaffold file for future growth).
- `exports.zsh`: `$GOPATH`, `$TERM`, `$PATH` additions, `$DOTFILESDIR` — ports forward
  existing exports, drops the hardcoded `cd`.
- `completions.zsh`: `kubectl`, `kind`, `crc`, `oc` completions, each behind
  `command -v <tool> &>/dev/null` guards.
- `zsh-autosuggestions` and `zsh-syntax-highlighting` keep today's approach — sourced
  directly via `$(brew --prefix)/share/...` in `.zshrc` (version-independent, survives
  `brew upgrade`, no symlink fragility) — rather than registered as Oh My Zsh plugins.
  `fzf-tab` *is* registered as an Oh My Zsh plugin (`plugins=(git docker fzf-tab)`), since it
  has no Homebrew formula; `install.sh` clones it from GitHub into
  `~/.oh-my-zsh/custom/plugins/fzf-tab` if not already present (a plain git clone, not a
  version-pinned path, so it's safe to re-run and survives upgrades via `git pull`).

### 3. tmux (`tmux/.tmux.conf`)

- `set -g prefix C-a`, `unbind C-b`, `bind C-a send-prefix`.
- `set -g mouse on` (kept), `set -g default-terminal "tmux-256color"` (kept).
- TPM plugin list declared properly:
  `tmux-plugins/tpm`, `catppuccin/tmux`, `tmux-plugins/tmux-cpu`,
  `tmux-plugins/tmux-battery`, `tmux-plugins/tmux-resurrect`,
  `tmux-plugins/tmux-continuum`, `tmux-plugins/tmux-yank`.
  `run '~/.tmux/plugins/tpm/tpm'` at the bottom of the file (TPM convention).
- `tmux-continuum` configured for auto-save/restore of sessions across reboots.
- Status bar: session name (left), CPU / current k8s context+namespace (via a small inline
  `#()` shell command calling `kubectl config current-context` / the active namespace) /
  battery (right), Catppuccin Mocha flavor, rounded window-status style (as already set).
- Keybinds: `bind | split-window -h -c "#{pane_current_path}"`,
  `bind - split-window -v -c "#{pane_current_path}"`, vim-style pane navigation
  (`bind -n` not used — kept prefixed: `bind h/j/k/l select-pane -L/-D/-U/-R`),
  `bind r source-file ~/.tmux.conf \; display "Config reloaded"`.

### 4. Ghostty (`ghostty/config`)

- `theme = "catppuccin-mocha"` (uncomment/replace the Apple System Colors line).
- `shell-integration = zsh` (uncomment).
- Keep existing `font-family`, `font-size`, `cursor-style`, `background-blur-radius`, and the
  `ctrl+grave_accent=toggle_quick_terminal` keybind as-is.
- No changes to native tab/split keybinds — Ghostty defaults (`Cmd+T`, `Cmd+1-9`, etc.) are
  retained for scratch windows alongside tmux.

### 5. `install.sh`

- Idempotent, safe to re-run.
- For each managed file (`~/.zshrc`, `~/.zsh_aliases` → replaced by the `zsh/*.zsh` set,
  `~/.tmux.conf`, the Ghostty config under
  `~/Library/Application Support/com.mitchellh.ghostty/config`, `~/.config/starship.toml`):
  if the destination exists and is not already the expected symlink, move it to
  `~/.dotfiles_backup/<timestamp>/` before creating the symlink.
- Clones TPM to `~/.tmux/plugins/tpm` if missing. TPM manages its own plugin clones under
  `~/.tmux/plugins/`; the old manually-cloned `~/.config/tmux/plugins/catppuccin` and unused
  `catppuccin_bck` directories are left untouched (not referenced by the new config) and can
  be deleted manually later.
- Symlinks/clones `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `fzf-tab` into
  `~/.oh-my-zsh/custom/plugins/` if missing.
- Optional `--with-brew` flag runs `brew bundle --file Brewfile`.
- Prints a summary of what was linked/backed up at the end.

### 6. `Brewfile`

Captures every package needed to reproduce the setup on a fresh Mac: `ghostty`, `tmux`,
`starship`, `zoxide`, `eza`, `bat`, `kubecolor`, `fzf`, `kubectx`, `k9s`, plus the tmux
plugins that are fetched via git rather than brew (handled by `install.sh`, not the
Brewfile).

## Error Handling

- Every `command -v` guard in the zsh files prevents errors on a machine missing an
  optional tool (e.g. `oc`, `kind`, `crc`, `kubecolor`).
- `install.sh` uses `set -euo pipefail` and checks before every destructive action
  (never overwrites without backing up first); it exits with a clear message if run on a
  non-macOS/non-Homebrew system without `--force`.
- tmux config failures (e.g. a plugin not yet installed via TPM) degrade to tmux running
  without that module rather than refusing to start — standard TPM behavior.

## Testing / Verification Plan

1. Run `install.sh` (dry, confirm backups land in `~/.dotfiles_backup/<timestamp>/`).
2. `exec zsh` — confirm shell starts in `$HOME`, no errors on stderr, prompt renders with
   icons (validates Nerd Font + Starship init).
3. `kubectx <some-context>` and `kubens <some-namespace>` — confirm the Starship prompt
   updates immediately with the new context/namespace, and that a context name containing
   `prod` renders in red.
4. Kill and restart tmux (`tmux kill-server && tmux`) — confirm prefix is `Ctrl-a`, TPM
   plugins load (status bar shows CPU/battery/context), `prefix + |` and `prefix + -` split
   correctly, `prefix + r` reloads without error.
5. Restart Ghostty — confirm Catppuccin Mocha theme is applied and shell-integration is
   active (new tab opens in the same cwd as the pane it was spawned from).
6. `git add` / `commit` / `push` the dotfiles repo to `origin` (already configured, `gh`
   authenticated) and confirm it lands on GitHub.

## Out of Scope

- Changing the zsh plugin manager away from Oh My Zsh.
- Any Linux/WSL-specific paths (Ghostty config path, Homebrew paths) — macOS only for now.
- Migrating `~/.p10k.zsh` or the old `~/.config/starship.toml` stub — left untouched on
  disk, unreferenced, safe to delete manually later.

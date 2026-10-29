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
| `starship.toml`        | Powerline-style prompt — os/path/git/Kubernetes segments |
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

## Prompt

`starship.toml` is a Powerline-style, Powerlevel10k-esque prompt built on
Starship's official `catppuccin-powerline` preset: colored pill segments
with arrow separators for OS, path, git branch/status, Kubernetes
context/namespace, and time, followed by command duration — then a bare
`❯` prompt character on its own line.

## Kubernetes prompt

The Kubernetes segment always shows `⎈ <context>(<namespace>)` and its
whole pill switches to solid red automatically when the context name
contains "prod" — see `[[kubernetes.contexts]]` in `starship.toml` to add
more patterns. The same context/namespace also appears in the tmux status
bar via `tmux/scripts/k8s-status.sh`.

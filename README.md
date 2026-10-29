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

## tmux status bar

Right side, left to right: current app, CPU, memory, weather, Kubernetes
context/namespace, session name, battery.

Weather (`xamut/tmux-weather`) calls [wttr.in](https://wttr.in) — no API
key needed; location is IP-geolocated by default. Pin a city with
`set -g @tmux-weather-location "Berlin"` in `tmux/.tmux.conf` if you'd
rather not rely on IP geolocation (e.g. on a laptop that moves around, or
behind a VPN).

CPU/memory/battery are hand-built pills (same `#{@thm_*}` colors and
separator glyphs catppuccin's own modules use) that call each plugin's
backing script directly via `#(...)`, rather than using catppuccin's
bundled cpu/battery modules or tmux-cpu/tmux-battery's own
`#{cpu_percentage}`-style template variables. Those template variables are
installed via a one-shot find-and-replace each plugin runs against
`status-right`'s text at plugin-load time, and TPM loads all plugins in
parallel — so whether the text to replace already exists by the time that
find-and-replace runs is a race. (Separately, CPU specifically has its own
script in `tmux/scripts/cpu-status.sh` rather than tmux-cpu's own
`cpu_percentage.sh`, which shells out to `iostat -c 2` — two samples,
~1s — on macOS; commands that take about that long are much more likely
to lose the race, so a single near-instant `ps` snapshot is used instead.)

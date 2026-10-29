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
| `tmux/.tmux.conf`      | tmux config (prefix `Ctrl-b`, TPM-managed plugins)       |
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

Inside tmux, press `prefix + I` (capital i; prefix is `Ctrl-b`) once so TPM
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

Right side, left to right: current app, CPU, memory, network, weather,
Kubernetes context/namespace, session name, battery.

Network (`tmux/scripts/net-status.sh`) shows `↓down ↑up ping` for the
active interface (auto-detected via the default route, so it follows
Wi-Fi/Ethernet switches). Like CPU, it's a custom script rather than a
bundled plugin, and deliberately never blocks: throughput is a delta
between this run's interface byte counters and the previous run's
(cached in a file) instead of two samples a second apart, and the ping
reading is whatever a previous *background*, fully-detached ping already
wrote to its own cache file — this run also kicks off the next one before
returning. Pin a different ping target by editing `PING_HOST` in the
script.

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

## tmux quick-action menu

Press `prefix + m` for an on-screen popup menu — the key to press is shown
right next to each action, no memorizing required:

| Key | Action                      |
|-----|------------------------------|
| `1` | Show all windows (`choose-tree -Zw`) |
| `2` | Split the pane horizontally  |
| `3` | Launch `k9s`                 |
| `4` | Launch `htop`                |

This overrides tmux's default `prefix + m` binding ("mark pane"), which is
rarely used. Edit the `bind-key m display-menu ...` line near the bottom of
`tmux/.tmux.conf` to add more entries.

## tmux auto-start

Every new interactive Ghostty shell automatically attaches to (or creates) a
tmux session named `main` — see the guarded block near the top of
`zsh/.zshrc`. It's skipped for non-interactive shells, for Cursor/VS Code's
embedded terminal (`$TERM_PROGRAM=vscode`), and if already inside tmux.

Because every window attaches to the *same* `main` session, all Ghostty
windows/tabs show the same set of tmux windows and panes — opening a new
Ghostty tab doesn't give you an independent tmux session, it gives you
another view into the one shared session. That's intentional: it's what
makes tmux-resurrect/continuum's persistence actually useful across Ghostty
restarts. If you'd rather each window get its own independent session,
change `tmux new -s main` to `tmux new` in `zsh/.zshrc`.

## Switching light/dark theme

Run `theme light` or `theme dark` (no arg toggles) to switch Ghostty, tmux,
and the Starship prompt together between Catppuccin Mocha (dark, default)
and Catppuccin Latte (light) — see the `theme` function in
`zsh/functions.zsh`. tmux and Starship apply immediately; Ghostty has no
config file-watcher, so press its reload-config keybind (`cmd+shift+,`) or
restart it afterwards to see the new theme and background there.

This edits the tracked files in the repo directly (not the `~`-symlinked
copies — rewriting *those* in place would turn the symlinks into regular
files), so `git status` will show a pending change after switching. That's
expected: it's local preference, not a bug — commit it only if you want the
new theme to become the repo's default too.

## Background wallpaper

`ghostty/config` sets a subtle background image (`ghostty/wallpaper.jpg`,
`background-image-opacity = 0.2`, `background-image-fit = cover`) so it
reads as a faint backdrop rather than competing with text. Swap in your own
image by replacing `ghostty/wallpaper.jpg` and adjusting
`background-image-opacity` to taste (`0` = invisible, `1` = fully opaque).

#!/usr/bin/env bash
# Prints "<down> <up> <ping>ms" for the tmux status bar: current network
# throughput on the active interface (down/up) plus the last known ping
# latency to 1.1.1.1.
#
# Never blocks:
#  - Throughput is a delta between this run's interface byte counters and
#    the previous run's, cached in a file — a single instant `netstat -ib`
#    read plus arithmetic, not two samples a second apart. See the iostat
#    note in cpu-status.sh for why a ~1s blocking command is risky to run
#    as a tmux status-line format job (#(...)): it's a one-shot process
#    tmux re-invokes on every status-interval refresh, not a
#    continuously-running daemon, so anything slow in that process directly
#    risks the segment going blank.
#  - Ping latency is whatever the last *background* ping already wrote to
#    its cache file; this invocation also kicks off the next background
#    ping (fully detached: subshell, stdin/stdout/stderr redirected away
#    from tmux's pipe, disowned) before returning, so a slow or unreachable
#    network can never stall the status bar itself — worst case the ping
#    reading just goes briefly stale until the backgrounded one finishes.

CACHE_DIR="${TMPDIR:-/tmp}/tmux-net-status"
mkdir -p "$CACHE_DIR" 2>/dev/null
THROUGHPUT_CACHE="$CACHE_DIR/throughput"
PING_CACHE="$CACHE_DIR/ping"
PING_LOCK="$CACHE_DIR/ping.lock"
PING_HOST="1.1.1.1"

fmt_bytes() {
  # bytes/sec -> short human string (whole numbers; one decimal only once
  # we're into MB/s, where the extra precision actually matters)
  awk -v b="$1" 'BEGIN {
    if (b < 0) b = 0
    if (b >= 1048576)      printf "%.1fM", b / 1048576
    else if (b >= 1024)    printf "%.0fK", b / 1024
    else                   printf "%.0fB", b
  }'
}

iface=$(route -n get default 2>/dev/null | awk '/interface: /{print $2; exit}')
now=$(date +%s)
down="…"
up="…"

if [[ -n "$iface" ]]; then
  read -r rx tx < <(netstat -ib 2>/dev/null | awk -v i="$iface" '$1 == i {print $7, $10; exit}')

  if [[ -n "$rx" && -n "$tx" ]]; then
    if [[ -f "$THROUGHPUT_CACHE" ]]; then
      read -r prev_iface prev_time prev_rx prev_tx < "$THROUGHPUT_CACHE"
      if [[ "$prev_iface" == "$iface" ]]; then
        elapsed=$(( now - prev_time ))
        if (( elapsed > 0 )); then
          down=$(fmt_bytes $(( (rx - prev_rx) / elapsed )))
          up=$(fmt_bytes $(( (tx - prev_tx) / elapsed )))
        fi
      fi
    fi
    echo "$iface $now $rx $tx" > "$THROUGHPUT_CACHE"
  fi
fi

ping_ms="…"
[[ -f "$PING_CACHE" ]] && ping_ms=$(<"$PING_CACHE")

# Stale-lock cleanup: if a previous background ping died without cleaning up
# (e.g. the machine slept mid-ping), don't let that wedge pings forever.
if [[ -d "$PING_LOCK" ]]; then
  lock_age=$(( $(date +%s) - $(stat -f %m "$PING_LOCK" 2>/dev/null || echo 0) ))
  (( lock_age > 5 )) && rmdir "$PING_LOCK" 2>/dev/null
fi

if mkdir "$PING_LOCK" 2>/dev/null; then
  (
    rtt=$(ping -c 1 -t 1 "$PING_HOST" 2>/dev/null | grep -oE 'time=[0-9.]+' | cut -d= -f2)
    if [[ -n "$rtt" ]]; then
      printf '%.0fms\n' "$rtt" > "$PING_CACHE"
    else
      echo "✕" > "$PING_CACHE"
    fi
    rmdir "$PING_LOCK" 2>/dev/null
  ) </dev/null >/dev/null 2>&1 &
  disown
fi

echo "↓${down} ↑${up} ${ping_ms}"

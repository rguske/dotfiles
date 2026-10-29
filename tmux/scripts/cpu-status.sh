#!/usr/bin/env bash
# Prints "NN.N%" current CPU utilization for the tmux status bar.
#
# Deliberately NOT using tmux-cpu's own cpu_percentage.sh: on macOS that
# script shells out to `iostat -c 2 disk0`, which blocks for ~1 second
# (two samples) to compute a delta. Commands that take ~1s reliably never
# complete when run as a tmux status-line format job (#(...)) — reproduced
# directly: the job is torn down/re-issued before it finishes, so the
# segment is permanently blank. Summing the instantaneous %CPU column from
# `ps` (like tmux-cpu's own non-iostat/non-sar fallback) needs a single
# snapshot, returns in well under 100ms, and never hits that problem.
cores=$(sysctl -n hw.ncpu 2>/dev/null)
[ -z "$cores" ] && cores=1

ps -A -o %cpu= | awk -v cores="$cores" '{s+=$1} END {printf "%.1f%%", s/cores}'

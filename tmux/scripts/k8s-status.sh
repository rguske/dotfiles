#!/usr/bin/env bash
# Prints "<context>/<namespace>" for the tmux status bar, falling back
# gracefully when kubectl isn't configured or installed.

if ! command -v kubectl &>/dev/null; then
  exit 0
fi

context=$(kubectl config current-context 2>/dev/null) || exit 0
namespace=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
echo "${context}/${namespace:-default}"

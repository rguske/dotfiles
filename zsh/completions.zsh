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

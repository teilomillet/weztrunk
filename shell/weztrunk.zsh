if command -v wt >/dev/null 2>&1; then
  eval "$(command wt config shell init zsh)"
fi

wtx() {
  local runner="$HOME/.local/bin/wt-code"

  if [[ ! -x "$runner" ]]; then
    printf 'WezTrunk launcher not found: %s\n' "$runner" >&2
    return 1
  fi

  wt switch -x "$runner '{{ repo }}' '{{ branch | sanitize }}'" "$@"
}

alias wtn='wtx --create'

if [ -n "${ZSH_VERSION:-}" ]; then
  weztrunk_shell=zsh
elif [ -n "${BASH_VERSION:-}" ]; then
  weztrunk_shell=bash
else
  weztrunk_shell=
fi

if command -v wt >/dev/null 2>&1; then
  case "$weztrunk_shell" in
    zsh|bash)
      eval "$(command wt config shell init "$weztrunk_shell")"
      ;;
  esac
fi

wtx() {
  runner="$HOME/.local/bin/wt-code"

  if [ ! -x "$runner" ]; then
    printf 'WezTrunk launcher not found: %s\n' "$runner" >&2
    return 1
  fi

  wt switch -x "$runner '{{ repo }}' '{{ branch | sanitize }}'" "$@"
}

alias wtn='wtx --create'

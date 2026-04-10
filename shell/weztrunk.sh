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
  switcher="$HOME/.local/bin/weztrunk-switch"

  if [ ! -x "$switcher" ]; then
    printf 'WezTrunk switch helper not found: %s\n' "$switcher" >&2
    return 1
  fi

  if [ "${1:-}" = "--create" ]; then
    shift
    "$switcher" create "$PWD" "$@"
    return
  fi

  if [ "$#" -eq 0 ] || [ "${1:-}" = "--" ]; then
    "$switcher" pick "$PWD" "$@"
    return
  fi

  branch=$1
  shift
  "$switcher" switch "$PWD" "$branch" "$@"
}

alias wtn='wtx --create'

wthelp() {
  weztrunk_cmd="$HOME/.local/bin/weztrunk"

  if [ ! -x "$weztrunk_cmd" ]; then
    printf 'WezTrunk command not found: %s\n' "$weztrunk_cmd" >&2
    return 1
  fi

  "$weztrunk_cmd" man "$@"
}

wtman() {
  wthelp "$@"
}

alias wtm='wtman'

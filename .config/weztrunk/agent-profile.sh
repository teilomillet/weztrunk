#!/bin/sh

weztrunk_canonical_provider() {
  case "${1:-}" in
    ''|codex)
      printf 'codex\n'
      ;;
    claude|claude-code)
      printf 'claude-code\n'
      ;;
    opencode|open-code)
      printf 'opencode\n'
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

weztrunk_config_runner() {
  printf '%s\n' "${WEZTRUNK_CONFIG_RUNNER:-"$HOME/.local/bin/weztrunk-config"}"
}

weztrunk_config_query() {
  runner=$(weztrunk_config_runner)
  if [ ! -x "$runner" ]; then
    return 1
  fi

  "$runner" "$@"
}

weztrunk_agent_provider() {
  if provider=$(weztrunk_config_query provider 2>/dev/null); then
    printf '%s\n' "$provider"
    return 0
  fi

  weztrunk_canonical_provider "${WEZTRUNK_AGENT:-codex}"
}

weztrunk_agent_profile_name() {
  if profile=$(weztrunk_config_query profile 2>/dev/null); then
    printf '%s\n' "$profile"
    return 0
  fi

  printf 'deep\n'
}

weztrunk_args_root() {
  printf '%s\n' "${WEZTRUNK_AGENT_ARGS_DIR:-"$HOME/.config/weztrunk/providers"}"
}

weztrunk_args_file() {
  mode=$1
  provider=$(weztrunk_agent_provider)
  printf '%s/%s/%s.args\n' "$(weztrunk_args_root)" "$provider" "$mode"
}

weztrunk_find_agent_bin() {
  if [ -n "${WEZTRUNK_AGENT_BIN:-${WWC_AGENT_BIN:-}}" ]; then
    printf '%s\n' "${WEZTRUNK_AGENT_BIN:-$WWC_AGENT_BIN}"
    return 0
  fi

  configured_bin=$(weztrunk_config_query provider-bin 2>/dev/null || true)

  case "$(weztrunk_agent_provider)" in
    codex)
      default_bin=${configured_bin:-codex}
      fallback="/home/linuxbrew/.linuxbrew/bin/codex /opt/homebrew/bin/codex"
      ;;
    claude-code)
      default_bin=${configured_bin:-claude}
      fallback="/home/linuxbrew/.linuxbrew/bin/claude /opt/homebrew/bin/claude"
      ;;
    opencode)
      default_bin=${configured_bin:-opencode}
      fallback="/home/linuxbrew/.linuxbrew/bin/opencode /opt/homebrew/bin/opencode"
      ;;
    *)
      default_bin=${configured_bin:-$(weztrunk_agent_provider)}
      fallback=
      ;;
  esac

  case "$default_bin" in
    */*)
      if [ -x "$default_bin" ]; then
        printf '%s\n' "$default_bin"
        return 0
      fi
      ;;
  esac

  if command -v "$default_bin" >/dev/null 2>&1; then
    command -v "$default_bin"
    return 0
  fi

  for fallback_path in $fallback; do
    if [ -n "$fallback_path" ] && [ -x "$fallback_path" ]; then
      printf '%s\n' "$fallback_path"
      return 0
    fi
  done

  printf 'No agent CLI found for provider %s. Set WEZTRUNK_AGENT_BIN or install %s.\n' "$(weztrunk_agent_provider)" "$default_bin" >&2
  exit 127
}

weztrunk_join_args() {
  joined=
  sep=

  for arg in "$@"; do
    joined=$joined$sep$arg
    sep=' '
  done

  printf '%s\n' "$joined"
}

weztrunk_agent_name() {
  printf '%s/%s\n' "$(weztrunk_agent_provider)" "$(weztrunk_agent_profile_name)"
}

weztrunk_detect_appearance() {
  case "${WEZTRUNK_APPEARANCE:-}" in
    *Dark*|dark)
      printf 'dark\n'
      return 0
      ;;
    *Light*|light)
      printf 'light\n'
      return 0
      ;;
  esac

  if [ "$(uname -s 2>/dev/null || printf unknown)" = Darwin ] && command -v defaults >/dev/null 2>&1; then
    if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
      printf 'dark\n'
    else
      printf 'light\n'
    fi
    return 0
  fi

  background=${COLORFGBG##*;}
  case "$background" in
    ''|0|1|2|3|4|5|6|8)
      printf 'dark\n'
      ;;
    *)
      printf 'light\n'
      ;;
  esac
}

weztrunk_codex_theme() {
  case "$(weztrunk_detect_appearance)" in
    light)
      printf 'weztrunk-gruvbox-light-violet\n'
      ;;
    *)
      printf 'weztrunk-gruvbox-dark-tangerine\n'
      ;;
  esac
}

weztrunk_codex_launch() {
  agent_bin=$(weztrunk_find_agent_bin)
  prompt=$(weztrunk_join_args "$@")
  args_file=$(weztrunk_args_file launch)

  set -- \
    "$agent_bin" \
    --sandbox workspace-write \
    -c sandbox_workspace_write.network_access=true \
    -c "tui.theme=\"$(weztrunk_codex_theme)\""

  if extra_args=$(weztrunk_config_query args launch 2>/dev/null); then
    old_ifs=$IFS
    IFS='
'
    for line in $extra_args; do
      [ -n "$line" ] && set -- "$@" "$line"
    done
    IFS=$old_ifs
  fi

  if [ -r "$args_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        ''|'#'*)
          continue
          ;;
        *)
          set -- "$@" "$line"
          ;;
      esac
    done < "$args_file"
  fi

  if [ -n "$prompt" ]; then
    set -- "$@" "$prompt"
  fi

  exec "$@"
}

weztrunk_claude_launch() {
  agent_bin=$(weztrunk_find_agent_bin)
  prompt=$(weztrunk_join_args "$@")
  args_file=$(weztrunk_args_file launch)

  set -- "$agent_bin"

  if extra_args=$(weztrunk_config_query args launch 2>/dev/null); then
    old_ifs=$IFS
    IFS='
'
    for line in $extra_args; do
      [ -n "$line" ] && set -- "$@" "$line"
    done
    IFS=$old_ifs
  fi

  if [ -r "$args_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        ''|'#'*)
          continue
          ;;
        *)
          set -- "$@" "$line"
          ;;
      esac
    done < "$args_file"
  fi

  if [ -n "$prompt" ]; then
    set -- "$@" "$prompt"
  fi

  exec "$@"
}

weztrunk_opencode_launch() {
  agent_bin=$(weztrunk_find_agent_bin)
  prompt=$(weztrunk_join_args "$@")
  args_file=$(weztrunk_args_file launch)

  set -- "$agent_bin"

  if extra_args=$(weztrunk_config_query args launch 2>/dev/null); then
    old_ifs=$IFS
    IFS='
'
    for line in $extra_args; do
      [ -n "$line" ] && set -- "$@" "$line"
    done
    IFS=$old_ifs
  fi

  if [ -r "$args_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        ''|'#'*)
          continue
          ;;
        *)
          set -- "$@" "$line"
          ;;
      esac
    done < "$args_file"
  fi

  if [ -n "$prompt" ]; then
    set -- "$@" --prompt "$prompt"
  fi

  exec "$@"
}

weztrunk_codex_commit() {
  agent_bin=$(weztrunk_find_agent_bin)
  tmp=$(mktemp)
  args_file=$(weztrunk_args_file commit)

  cleanup() {
    rm -f "$tmp"
  }
  trap cleanup EXIT HUP INT TERM

  set -- \
    "$agent_bin" \
    exec \
    --skip-git-repo-check \
    -c system_prompt='' \
    --sandbox read-only \
    --output-last-message "$tmp"

  if extra_args=$(weztrunk_config_query args commit 2>/dev/null); then
    old_ifs=$IFS
    IFS='
'
    for line in $extra_args; do
      [ -n "$line" ] && set -- "$@" "$line"
    done
    IFS=$old_ifs
  fi

  if [ -r "$args_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        ''|'#'*)
          continue
          ;;
        *)
          set -- "$@" "$line"
          ;;
      esac
    done < "$args_file"
  fi

  set -- "$@" -
  "$@" >/dev/null 2>&1
  cat "$tmp"
}

weztrunk_claude_commit() {
  agent_bin=$(weztrunk_find_agent_bin)
  args_file=$(weztrunk_args_file commit)

  set -- "$agent_bin" -p --output-format text --tools ""

  if extra_args=$(weztrunk_config_query args commit 2>/dev/null); then
    old_ifs=$IFS
    IFS='
'
    for line in $extra_args; do
      [ -n "$line" ] && set -- "$@" "$line"
    done
    IFS=$old_ifs
  fi

  if [ -r "$args_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        ''|'#'*)
          continue
          ;;
        *)
          set -- "$@" "$line"
          ;;
      esac
    done < "$args_file"
  fi

  set -- "$@" "Follow the instructions in the piped content exactly. Return only the requested final output."
  "$@"
}

weztrunk_opencode_commit() {
  agent_bin=$(weztrunk_find_agent_bin)
  args_file=$(weztrunk_args_file commit)
  stdin_file=$(mktemp)

  cleanup() {
    rm -f "$stdin_file"
  }
  trap cleanup EXIT HUP INT TERM

  cat > "$stdin_file"

  set -- "$agent_bin" run --file "$stdin_file"

  if extra_args=$(weztrunk_config_query args commit 2>/dev/null); then
    old_ifs=$IFS
    IFS='
'
    for line in $extra_args; do
      [ -n "$line" ] && set -- "$@" "$line"
    done
    IFS=$old_ifs
  fi

  if [ -r "$args_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        ''|'#'*)
          continue
          ;;
        *)
          set -- "$@" "$line"
          ;;
      esac
    done < "$args_file"
  fi

  set -- "$@" "Use the attached file as the full task. Return only the requested final output."
  "$@"
}

weztrunk_agent_launch() {
  provider=$(weztrunk_agent_provider)

  case "$provider" in
    codex)
      weztrunk_codex_launch "$@"
      ;;
    claude-code)
      weztrunk_claude_launch "$@"
      ;;
    opencode)
      weztrunk_opencode_launch "$@"
      ;;
    *)
      if command -v weztrunk_custom_agent_launch >/dev/null 2>&1; then
        weztrunk_custom_agent_launch "$provider" "$@"
        return
      fi

      printf 'Unsupported WEZTRUNK_AGENT provider: %s\n' "$provider" >&2
      printf 'Supported built-ins: codex, claude-code, opencode\n' >&2
      printf 'For custom providers, define weztrunk_custom_agent_launch() in ~/.config/weztrunk/agent-profile.local.sh\n' >&2
      exit 64
      ;;
  esac
}

weztrunk_agent_commit() {
  provider=$(weztrunk_agent_provider)

  case "$provider" in
    codex)
      weztrunk_codex_commit
      ;;
    claude-code)
      weztrunk_claude_commit
      ;;
    opencode)
      weztrunk_opencode_commit
      ;;
    *)
      if command -v weztrunk_custom_agent_commit >/dev/null 2>&1; then
        weztrunk_custom_agent_commit "$provider"
        return
      fi

      printf 'Unsupported WEZTRUNK_AGENT provider for commit generation: %s\n' "$provider" >&2
      printf 'Supported built-ins: codex, claude-code, opencode\n' >&2
      printf 'For custom providers, define weztrunk_custom_agent_commit() in ~/.config/weztrunk/agent-profile.local.sh\n' >&2
      exit 64
      ;;
  esac
}

local_profile=${WEZTRUNK_AGENT_LOCAL_PROFILE:-"$HOME/.config/weztrunk/agent-profile.local.sh"}
if [ -r "$local_profile" ]; then
  # shellcheck source=/dev/null
  . "$local_profile"
fi

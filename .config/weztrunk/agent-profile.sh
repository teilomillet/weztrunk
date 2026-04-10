#!/bin/sh

weztrunk_agent_provider() {
  case "${WEZTRUNK_AGENT:-codex}" in
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
      printf '%s\n' "${WEZTRUNK_AGENT}"
      ;;
  esac
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
  if [ -n "${WEZTRUNK_AGENT_BIN:-}" ]; then
    printf '%s\n' "$WEZTRUNK_AGENT_BIN"
    return 0
  fi

  case "$(weztrunk_agent_provider)" in
    codex)
      default_bin=codex
      fallback=/opt/homebrew/bin/codex
      ;;
    claude-code)
      default_bin=claude
      fallback=/opt/homebrew/bin/claude
      ;;
    opencode)
      default_bin=opencode
      fallback=/opt/homebrew/bin/opencode
      ;;
    *)
      default_bin=$(weztrunk_agent_provider)
      fallback=
      ;;
  esac

  if command -v "$default_bin" >/dev/null 2>&1; then
    command -v "$default_bin"
    return 0
  fi

  if [ -n "$fallback" ] && [ -x "$fallback" ]; then
    printf '%s\n' "$fallback"
    return 0
  fi

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
  printf '%s\n' "$(weztrunk_agent_provider)"
}

weztrunk_codex_launch() {
  agent_bin=$(weztrunk_find_agent_bin)
  prompt=$(weztrunk_join_args "$@")
  args_file=$(weztrunk_args_file launch)

  set -- \
    "$agent_bin" \
    -c model_reasoning_effort='xhigh' \
    --sandbox workspace-write \
    -c sandbox_workspace_write.network_access=true

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
    -c model_reasoning_effort='low' \
    -c system_prompt='' \
    --sandbox read-only \
    --output-last-message "$tmp"

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

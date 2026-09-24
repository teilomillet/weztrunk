#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
helper="$repo_root/.local/bin/weztrunk-context"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

fake_wezterm=$tmp/wezterm
log=$tmp/wezterm.log
cat > "$fake_wezterm" <<'SH'
#!/bin/sh
set -eu
case "$1 $2" in
  'cli list')
    printf '[{"pane_id":42}]\n'
    ;;
  'cli send-text')
    payload=$(cat)
    printf 'send %s :: %s\n' "$*" "$payload" >> "$WEZTRUNK_TEST_LOG"
    ;;
  'cli activate-pane')
    printf 'activate %s\n' "$*" >> "$WEZTRUNK_TEST_LOG"
    ;;
  *)
    exit 64
    ;;
esac
SH
chmod 700 "$fake_wezterm"

export XDG_STATE_HOME=$tmp/state
export WEZTRUNK_WEZTERM_BIN=$fake_wezterm
export WEZTRUNK_TEST_LOG=$log

repo=$(basename "$repo_root")
branch=$(git -C "$repo_root" branch --show-current)
"$helper" register "$repo" "$branch" 42 codex/deep
pane=$($helper pane "$repo_root")
[ "$pane" = "42
codex/deep" ]

context=$tmp/context.md
printf 'exact context\n' > "$context"
agent=$(printf 'Question: why?\nContext: %s\n' "$context" | "$helper" send "$repo_root" "$context")
[ "$agent" = codex/deep ]
grep -F 'send cli send-text --pane-id 42 :: Question: why?' "$log" >/dev/null
grep -F 'activate cli activate-pane --pane-id 42' "$log" >/dev/null

fake_dispatcher=$tmp/weztrunk-agent
cat > "$fake_dispatcher" <<SH
#!/bin/sh
case "\$1" in
  name) printf 'codex/deep\\n' ;;
  socket-path) printf '%s/socket\\n' '$tmp' ;;
  launch) exit 0 ;;
  *) exit 64 ;;
esac
SH
chmod 700 "$fake_dispatcher"

mkdir -p "$tmp/bin"
cat > "$tmp/bin/dtach" <<'SH'
#!/bin/sh
exit 0
SH
chmod 700 "$tmp/bin/dtach"

WEZTERM_PANE=42 \
WEZTRUNK_CONTEXT_RUNNER=$helper \
WEZTRUNK_AGENT_DISPATCHER=$fake_dispatcher \
WEZTRUNK_CONFIG_RUNNER=/definitely/missing \
WEZTRUNK_SLEEP_GUARD=none \
PATH="$tmp/bin:$PATH" \
  "$repo_root/.local/bin/wt-code" "$repo" "$branch"

pane=$($helper pane "$repo_root")
[ "$pane" = "42
codex/deep" ]

printf 'context bridge: launch registered, validated, sent, submitted, and focused\n'

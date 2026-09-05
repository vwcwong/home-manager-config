# SessionStart hook. Mentions accumulated convention findings once they are
# worth a look. No model call — this runs on the startup path of every session,
# so it stays pure jq and file counting.

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-conventions"
findings_dir="$state_dir/findings.d"

# Below this it is not worth interrupting for; the evidence bar in
# /refresh-conventions wants several sessions agreeing before it proposes
# anything, so a handful of findings would mostly produce "nothing to do".
threshold=10

main() {
  # Stay silent inside the extractor's own nested session.
  if [ -n "${CLAUDE_CONVENTIONS_WORKER:-}" ]; then
    return 0
  fi

  if [ "${CLAUDE_CONVENTIONS_DISABLE:-}" = "1" ]; then
    return 0
  fi

  local payload source count
  payload=$(cat)
  source=$(printf '%s' "$payload" | jq -r '.source // empty')

  # Only on a genuinely new session. Nudging on resume/clear/compact/fork would
  # repeat the same message several times within one sitting.
  if [ "$source" != "startup" ]; then
    return 0
  fi

  [ -d "$findings_dir" ] || return 0
  count=$(cat "$findings_dir"/*.jsonl 2>/dev/null | grep -c . || true)

  if [ "${count:-0}" -lt "$threshold" ]; then
    return 0
  fi

  jq -cn --arg msg "$count convention findings pending — run /refresh-conventions in ~/.config/home-manager" \
    '{systemMessage: $msg}'
}

main "$@"

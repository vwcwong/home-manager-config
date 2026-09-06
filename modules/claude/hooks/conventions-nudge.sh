# SessionStart hook. Mentions accumulated findings once they are worth a look.
# Runs on every session's startup path, so no model call — pure jq.

# Below this /refresh-conventions would mostly find nothing worth proposing.
threshold=10

# Findings, not sessions — but the extractor emits at most 3 per session.
pending_count() {
  [ -d "$findings_dir" ] || { printf '0'; return 0; }
  cat "$findings_dir"/*.jsonl 2>/dev/null | grep -c . || true
}

# Resume/clear/compact would repeat the nudge within one sitting.
is_new_session() {
  [ "$1" = "startup" ]
}

nudge() {
  jq -cn --arg msg \
    "$1 convention findings pending — run /refresh-conventions in ~/.config/home-manager" \
    '{systemMessage: $msg}'
}

main() {
  if is_disabled; then
    return 0
  fi

  local payload source count
  payload=$(cat)
  source=$(printf '%s' "$payload" | jq -r '.source // empty')

  if ! is_new_session "$source"; then
    return 0
  fi

  count=$(pending_count)
  if [ "$count" -lt "$threshold" ]; then
    return 0
  fi

  nudge "$count"
}

main "$@"

# SessionEnd hook. Looks over the session that just finished and records any
# durable working preference it revealed, for /refresh-conventions to fold into
# the config later. Never edits config and never touches git.
#
# The model call happens in a detached worker because a SessionEnd hook blocks
# the exit path: quitting Claude must not wait on an API round trip.
#
# Recursion is not a concern despite this being a hook that runs Claude — the
# worker uses `claude --bare`, which skips hooks entirely.

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-conventions"
findings_dir="$state_dir/findings.d"
offsets_dir="$state_dir/offsets"
log_file="$state_dir/extract.log"

# Sessions shorter than this are almost always a single task and no more; the
# generalisable stuff shows up when you have had time to push back on something.
min_turns=3

log() { printf '%s  %s\n' "$(date -Is)" "$*" >>"$log_file"; }

# Emits the user's own words from a transcript, one turn per block, starting
# after $2 lines. Tool results, system reminders and slash-command scaffolding
# are stripped — none of that is the user speaking, and feeding it to the
# extractor is what turns the journal into noise.
user_turns() {
  tail -n "+$(($2 + 1))" "$1" 2>/dev/null | jq -r '
    select(.type == "user" and (.isMeta | not) and (.isCompactSummary | not))
    | .message.content
    | (if type == "string" then . else (map(select(.type == "text") | .text) | join("\n")) end)
    | select(. != null)
    | gsub("(?s)<system-reminder>.*?</system-reminder>"; "")
    | gsub("(?s)<local-command-caveat>.*?</local-command-caveat>"; "")
    | gsub("(?s)<local-command-stdout>.*?</local-command-stdout>"; "")
    | gsub("(?s)<command-name>.*?</command-name>"; "")
    | gsub("(?s)<command-message>.*?</command-message>"; "")
    | gsub("(?s)<command-args>.*?</command-args>"; "")
    | gsub("(?s)<command-contents>.*?</command-contents>"; "")
    | sub("^\\s+"; "") | sub("\\s+$"; "")
    | select(length > 0)
  ' 2>/dev/null
}

# Keeps only the lines that are a well-formed finding, so prose or a fence the
# model added around its output is discarded rather than failing the batch.
valid_findings() {
  local line
  while IFS= read -r line; do
    printf '%s' "$line" \
      | jq -ce 'select(type == "object" and has("category") and has("observation"))' \
        2>/dev/null || true
  done
}

run_worker() {
  local transcript="$1" session_id="$2" project="$3" offset="$4"
  local turns turn_count raw findings out

  turns=$(user_turns "$transcript" "$offset")
  turn_count=$(printf '%s' "$turns" | grep -c . || true)

  # Deliberately leave the offset alone here. A session that ends below the
  # threshold and is later resumed should have these turns counted again as
  # part of the longer session, not silently dropped.
  if [ "${turn_count:-0}" -lt "$min_turns" ]; then
    log "skip $session_id: $turn_count turns"
    return 0
  fi

  # Reviewing proposals is itself a conversation full of convention talk. Left
  # unguarded it would feed its own output back in as fresh evidence.
  if printf '%s' "$turns" | grep -q '/refresh-conventions'; then
    log "skip $session_id: review session"
    return 0
  fi

  # Append the config as it stands so the extractor can drop anything already
  # covered, rather than re-reporting existing rules every session.
  local existing
  existing=$(printf '## Rules already in the config\n\n%s' \
    "$(cat "$HOME/.claude/CLAUDE.md" 2>/dev/null)")

  # This is a hook that runs Claude, so the nested session would fire the hook
  # again. `--bare` would skip hooks outright but only authenticates via
  # ANTHROPIC_API_KEY, which a subscription login does not have — hence the
  # environment guard that both hooks check on entry instead.
  #
  # Run from a neutral directory so no project's CLAUDE.md leaks into the
  # extraction; the config we want it to compare against is appended explicitly.
  raw=$(cd "$state_dir" && printf '%s' "$turns" | CLAUDE_CONVENTIONS_WORKER=1 claude -p \
    --model claude-haiku-4-5-20251001 \
    --allowedTools "" \
    --system-prompt-file "$HOME/.claude/prompts/extract-conventions.md" \
    --append-system-prompt "$existing" 2>>"$log_file") || {
    log "skip $session_id: extractor call failed"
    return 0
  }

  wc -l <"$transcript" | tr -d ' ' >"$offsets_dir/$session_id"

  # One JSON object per line, so a model that adds a stray sentence or a
  # markdown fence costs us that line rather than the whole extraction.
  findings=$(printf '%s\n' "$raw" | valid_findings)

  if [ -z "$findings" ]; then
    log "ok $session_id: no findings from $turn_count turns"
    return 0
  fi

  # One file per session rather than a shared journal: concurrent session exits
  # then need no locking, and `flock` is Linux-only anyway.
  out="$findings_dir/$(date +%Y%m%dT%H%M%S)-$session_id.jsonl"
  printf '%s\n' "$findings" | jq -c \
    --arg ts "$(date -Is)" \
    --arg session_id "$session_id" \
    --arg project "$project" \
    '{ts: $ts, session_id: $session_id, project: $project} + .' >"$out"

  log "ok $session_id: $(wc -l <"$out" | tr -d ' ') findings from $turn_count turns"
}

main() {
  # The extractor runs Claude, and that nested session fires this hook again on
  # exit. Bail before doing anything so the analysis cannot analyse itself.
  if [ -n "${CLAUDE_CONVENTIONS_WORKER:-}" ]; then
    return 0
  fi

  mkdir -p "$findings_dir" "$offsets_dir"

  if [ "${1:-}" = "--worker" ]; then
    run_worker "$2" "$3" "$4" "$5"
    return 0
  fi

  if [ "${CLAUDE_CONVENTIONS_DISABLE:-}" = "1" ]; then
    return 0
  fi

  local payload transcript session_id cwd offset total
  payload=$(cat)
  transcript=$(printf '%s' "$payload" | jq -r '.transcript_path // empty')
  session_id=$(printf '%s' "$payload" | jq -r '.session_id // empty')
  cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty')

  if [ -z "$transcript" ] || [ ! -r "$transcript" ] || [ -z "$session_id" ]; then
    return 0
  fi

  # A resumed session ends more than once. Track how far we have read so each
  # turn is only ever analysed as part of one extraction.
  offset=$(cat "$offsets_dir/$session_id" 2>/dev/null || printf '0')
  total=$(wc -l <"$transcript" | tr -d ' ')
  if [ "$total" -le "$offset" ]; then
    return 0
  fi

  nohup "$0" --worker "$transcript" "$session_id" "$(basename "$cwd")" "$offset" \
    >/dev/null 2>&1 &
  return 0
}

main "$@"

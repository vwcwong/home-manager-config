# SessionEnd hook. Records durable working preferences for /refresh-conventions.
#
# The model call is detached because SessionEnd blocks the exit path. That
# worker runs Claude, whose exit fires this hook again; is_disabled stops the
# recursion, since `--bare` (which skips hooks) needs an API key we lack.

offsets_dir="$state_dir/offsets"
log_file="$state_dir/extract.log"

model="claude-haiku-4-5-20251001"

# Below this a session is one task; preferences surface in longer ones.
min_turns=3

# Detached, so nothing would reap a hung call.
call_timeout=120

log_max_lines=400

count_lines() {
  grep -c . || true
}

log() {
  printf '%s  %s\n' "$(date -Is)" "$*" >>"$log_file"
  if [ "$(count_lines <"$log_file")" -gt "$log_max_lines" ]; then
    tail -n "$((log_max_lines / 2))" "$log_file" >"$log_file.tmp" &&
      mv "$log_file.tmp" "$log_file"
  fi
}

# --- transcript ---------------------------------------------------------------

# The user's own words, after $2 lines. Tool output and scaffolding are
# stripped — feeding them in is what makes findings noisy.
user_turns() {
  tail -n "+$(($2 + 1))" "$1" 2>/dev/null | jq -rR '
    fromjson? // empty
    | select(.type == "user" and (.isMeta | not) and (.isCompactSummary | not))
    | .message.content
    | (if type == "string" then . else (map(select(.type == "text") | .text) | join("\n")) end)
    | select(. != null)
    | gsub("(?s)<(system-reminder|local-command-[a-z]+|command-[a-z]+)>.*?</\\1>"; "")
    | sub("^\\s+"; "") | sub("\\s+$"; "")
    | select(length > 0)
  ' 2>/dev/null
}

# A review session is all convention talk; it would feed its output back in.
is_review_session() {
  printf '%s' "$1" | grep -q '/refresh-conventions'
}

# --- offsets ------------------------------------------------------------------
#
# A resumed session ends more than once; offsets keep each turn to one
# extraction.

read_offset() {
  cat "$offsets_dir/$1" 2>/dev/null || printf '0'
}

save_offset() {
  count_lines <"$2" >"$offsets_dir/$1"
}

has_new_turns() {
  [ "$(count_lines <"$1")" -gt "$2" ]
}

# --- extraction ---------------------------------------------------------------

# Lets the extractor drop anything the config already covers.
existing_rules() {
  printf '## Rules already in the config\n\n%s' \
    "$(cat "$HOME/.claude/CLAUDE.md" 2>/dev/null)"
}

# Subshell contains the cd. Neutral directory so no project's CLAUDE.md leaks
# in; the config to compare against is appended explicitly.
run_extractor() {
  (
    cd "$state_dir" || return 1
    printf '%s' "$1" | CLAUDE_CONVENTIONS_WORKER=1 \
      timeout "$call_timeout" claude -p \
      --model "$model" \
      --allowedTools "" \
      --system-prompt-file "$extractor_prompt" \
      --append-system-prompt "$(existing_rules)" 2>>"$log_file"
  )
}

# Dropping non-JSON lines first means a fence costs that line, not the batch.
valid_findings() {
  grep '^{' |
    jq -c 'select(type == "object" and has("category") and has("observation"))' \
      2>/dev/null || true
}

# Metadata /refresh-conventions clusters on: distinct sessions, and global
# preferences versus per-repo ones.
stamp_findings() {
  jq -c --arg ts "$(date -Is)" --arg session_id "$1" --arg project "$2" \
    '{ts: $ts, session_id: $session_id, project: $project} + .'
}

# One file per session: concurrent exits then need no locking.
findings_path() {
  printf '%s/%s.jsonl' "$findings_dir" "$1"
}

# --- worker -------------------------------------------------------------------

run_worker() {
  local transcript="$1" session_id="$2" project="$3" offset="$4"
  local turns turn_count raw findings out

  turns=$(user_turns "$transcript" "$offset")
  turn_count=$(printf '%s' "$turns" | count_lines)

  # Leave the offset alone: if this session resumes, these turns count then.
  if [ "$turn_count" -lt "$min_turns" ]; then
    log "skip $session_id: $turn_count turns"
    return 0
  fi

  if is_review_session "$turns"; then
    log "skip $session_id: review session"
    return 0
  fi

  if ! raw=$(run_extractor "$turns"); then
    log "skip $session_id: extractor call failed"
    return 0
  fi

  save_offset "$session_id" "$transcript"

  findings=$(printf '%s\n' "$raw" | valid_findings)
  if [ -z "$findings" ]; then
    log "ok $session_id: no findings from $turn_count turns"
    return 0
  fi

  out=$(findings_path "$session_id")
  printf '%s\n' "$findings" | stamp_findings "$session_id" "$project" >>"$out"
  log "ok $session_id: $(printf '%s' "$findings" | count_lines) findings from $turn_count turns"
}

# --- entry point --------------------------------------------------------------

spawn_worker() {
  nohup "$0" --worker "$1" "$2" "$3" "$4" >/dev/null 2>&1 &
}

main() {
  if is_disabled; then
    return 0
  fi

  mkdir -p "$findings_dir" "$offsets_dir"

  if [ "${1:-}" = "--worker" ]; then
    run_worker "$2" "$3" "$4" "$5"
    return 0
  fi

  local fields transcript session_id cwd offset
  fields=$(jq -r '[.transcript_path, .session_id, .cwd] | @tsv' 2>/dev/null || true)
  IFS=$'\t' read -r transcript session_id cwd <<<"$fields"

  if [ -z "$transcript" ] || [ ! -r "$transcript" ] || [ -z "$session_id" ]; then
    return 0
  fi

  offset=$(read_offset "$session_id")
  if ! has_new_turns "$transcript" "$offset"; then
    return 0
  fi

  spawn_worker "$transcript" "$session_id" "$(basename "$cwd")" "$offset"
}

main "$@"

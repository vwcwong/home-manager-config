# Shared by both convention hooks; prepended to each at build time by mkHook.

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/claude-conventions"
findings_dir="$state_dir/findings.d"

# The extractor runs Claude, whose session start and end fire these hooks again.
is_disabled() {
  [ -n "${CLAUDE_CONVENTIONS_WORKER:-}" ] ||
    [ "${CLAUDE_CONVENTIONS_DISABLE:-}" = "1" ]
}

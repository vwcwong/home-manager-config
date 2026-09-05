# Merges the convention hooks into an existing ~/.claude/settings.json without
# disturbing anything else in it. Entries are matched on the script name rather
# than the full path, so a rebuild (which changes the store hash) replaces the
# old registration instead of stacking a second one beside it.

def without(marker):
  map(.hooks = ((.hooks // []) | map(select((.command // "") | contains(marker) | not))))
  | map(select((.hooks | length) > 0));

def register(event; marker; command):
  .hooks[event] = (((.hooks[event] // []) | without(marker))
    + [{hooks: [{type: "command", command: command}]}]);

(.hooks //= {})
| register("SessionEnd"; "extract-conventions"; $extract)
| register("SessionStart"; "conventions-nudge"; $nudge)

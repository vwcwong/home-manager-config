{ ... }:
{
  home.file.".claude/CLAUDE.md".text = ''
    # User Instructions

    ## Worktree Workflow

    Always implement plans in a git worktree. When a plan is approved and implementation begins, use the `EnterWorktree` tool (or spawn an Agent with `isolation: "worktree"`) before making any code changes. This keeps the main working tree clean and lets changes be reviewed before merging.
  '';
}

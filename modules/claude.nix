{ ... }:
{
  home.file.".claude/CLAUDE.md".text = ''
    # User Instructions

    ## Communication Style

    Be concise. Default to dot points over prose:

    - Prefer short bullet lists to paragraphs, including for explanations and summaries.
    - Skip preamble, restating the question, and trailing summaries.
    - Only use full prose when a bullet would break the meaning (e.g. a single short
      answer, or code/command output).

    ## Worktree Workflow

    Before making any code changes, use `EnterWorktree` with a short descriptive name
    (e.g., `fix-auth`, `add-dark-mode`). Do this as soon as the user confirms they want
    implementation to proceed — not after exploring or planning.

    - **Naming**: use the feature/fix name in kebab-case. This makes `git worktree list`
      readable and the branch name meaningful.
    - **Exception**: skip the worktree for pure read-only tasks (exploration, explanation)
      or single-file trivial fixes where the user explicitly says to edit in place.
    - **After implementation**: commit changes inside the worktree, then either open a PR
      or ask the user how they want to merge. Do not merge manually without asking.
    - **Exiting**: use `ExitWorktree` with `action: "keep"` when work is done or paused
      (preserves the branch for review/PR). Use `action: "remove"` only if the user
      explicitly abandons the work.
    - **Agents**: spawning an Agent with `isolation: "worktree"` is for fully delegated
      tasks, not inline work. For interactive sessions where you make changes yourself,
      always use `EnterWorktree` directly.
  '';
}

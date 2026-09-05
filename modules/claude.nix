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

    ## Development Preferences

    These are defaults, not rules. Existing conventions in the codebase always win —
    match surrounding style, naming, structure, and tooling even where it contradicts
    the below. Apply these only when the codebase is silent, or for brand-new projects.

    - **Commits**: split work into a sensible sequence of commits rather than one big
      commit. Keep refactoring/formatting changes in separate commits from
      functionality changes — never mix the two in one commit. Use conventional
      commit format:

      ```
      type(scope): Description
      ```

      - Types: `feat`, `fix`, `docs`, `ci`, `chore` (routine maintenance, dependency
        bumps, housekeeping) — add more only if the project clearly needs them.
      - Scopes: define ones relevant to the project's own areas (e.g. `api`, `auth`,
        `cli`) rather than reusing scopes from unrelated projects. Multiple scopes are
        comma-separated and alphabetical; use a `global`/broad scope instead if a change
        touches more than ~3 areas.
      - Description: capitalised, imperative mood ("Add" not "Added"), no trailing period.
      - Example: `feat(auth): Add refresh token rotation`
    - **Comments**: minimise comments in favour of self-documenting code (clear names,
      small functions). Only comment where the *why* isn't obvious from the code itself.
    - **Tests**: minimise tests to those that meaningfully increase confidence in the
      code. Don't write tests for practically impossible cases or just for coverage.
  '';
}

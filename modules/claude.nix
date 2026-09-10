{ pkgs, ... }:
let
  # Separate files so writeShellApplication can shellcheck them at build time.
  mkHook = { name, runtimeInputs, prelude ? "" }: pkgs.writeShellApplication {
    inherit name runtimeInputs;
    text = prelude
      + builtins.readFile ./claude/lib/common.sh
      + builtins.readFile (./claude/hooks + "/${name}.sh");
  };

  extractConventions = mkHook {
    name = "extract-conventions";
    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.gnugrep pkgs.claude-code ];
    prelude = ''
      extractor_prompt="${./claude/prompts/extract-conventions.md}"
    '';
  };

  conventionsNudge = mkHook {
    name = "conventions-nudge";
    runtimeInputs = [ pkgs.coreutils pkgs.jq pkgs.gnugrep ];
  };

  # Each event holds matcher groups; both hooks are one unmatched command.
  commandHook = pkg: name: [
    { hooks = [{ type = "command"; command = "${pkg}/bin/${name}"; }]; }
  ];
in
{
  home.file.".claude/CLAUDE.md".text = ''
    # User Instructions

    ## Communication Style

    Be concise. Default to dot points over prose:

    - Prefer short bullet lists to paragraphs, including for explanations and summaries.
    - Skip preamble, restating the question, and trailing summaries.
    - Only use full prose when a bullet would break the meaning (e.g. a single short
      answer, or code/command output).
    - Cut filler intensifiers and stock LLM phrasing. Never use "genuinely",
      "honestly", "truly", "actually", "simply", "just", "really", "quite", or
      "you're absolutely right". Delete the word rather than swapping in another
      intensifier.
    - Don't narrate your own reasoning process with phrases like "instead of
      assuming", "let me think about", "it's worth noting", "I want to be careful
      here", or "to be clear". State the conclusion and the reason for it.

    ## Scope Discipline

    Avoid scope creep at all costs. Produce the minimum change that solves the
    stated problem to a high standard, and stop there:

    - Don't refactor, rename, reformat, or tidy nearby code just because it is
      adjacent to the change and could be improved.
    - Don't add abstractions, options, or handling for cases the task doesn't
      require.
    - Report unrelated problems you notice rather than fixing them — widening the
      scope is the user's call.

    ## Worktree Workflow

    Use `EnterWorktree` with a short descriptive name (e.g., `fix-auth`, `add-dark-mode`)
    before making code changes that warrant isolation. Do this as soon as the user
    confirms they want implementation to proceed — not after exploring or planning.

    - **Naming**: use the feature/fix name in kebab-case. This makes `git worktree list`
      readable and the branch name meaningful.
    - **When to use**: worktrees are for work needing isolation — parallel tasks, risky
      refactors, or anything with a long build/test cycle. Skip them for pure read-only
      tasks (exploration, explanation), and for single-file edits where a branch in place
      is enough or the user says to edit in place.
    - **Base**: create the worktree from a freshly fetched `origin/main`. If it outlives a
      merge to main, rebase onto main before opening the PR.
    - **After implementation**: commit changes inside the worktree, then either open a PR
      or ask the user how they want to merge. Do not merge manually without asking.
    - **Exiting**: use `ExitWorktree` with `action: "keep"` when work is done or paused
      (preserves the branch for review/PR). Use `action: "remove"` only if the user
      explicitly abandons the work. On `keep`, either push the branch or say plainly that
      it is local-only.
    - **Cleanup**: once the PR is squash-merged, remove the worktree and delete the branch
      locally and on the remote. Squash merges leave no merge ancestry, so
      `git branch --merged` never reports these branches — test with `git cherry main
      <branch>` instead, where only `-` lines means it landed.
    - **Stale check**: at the start of a session in a repo with worktrees, run
      `git worktree list` and report any whose branch has landed (removable) or holds
      unpushed commits (stale).
    - **Ignore**: keep `.claude/worktrees/` out of version control via `.gitignore` or
      `.git/info/exclude`, so worktrees don't surface as untracked noise.
    - **Agents**: spawning an Agent with `isolation: "worktree"` is for fully delegated
      tasks, not inline work. For interactive sessions where you make changes yourself,
      always use `EnterWorktree` directly.

    ## Development Preferences

    These are defaults, not rules. Existing conventions in the codebase always win —
    match surrounding style, naming, structure, and tooling even where it contradicts
    the below. Apply these only when the codebase is silent, or for brand-new projects.

    - **Dependencies**: hand-roll small, routine work. Before a large implementation
      of a standard problem (auth, parsing, retries, scheduling, serialisation),
      investigate established libraries first and report what you found — pick a
      well-maintained one that fits, and only hand-roll when none does.
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
    - **Commit dates**: keep the author date and the commit date exactly identical.
      When amending a commit, fast-forward the author date to the new commit date by
      pinning both to a single timestamp:

      ```
      D="$(date -Iseconds)" && GIT_COMMITTER_DATE="$D" git commit --amend --date="$D"
      ```

      Plain `--amend` leaves the old author date behind, and `--date=now` on its own
      can land a second off the committer timestamp.
    - **Comments**: minimise comments in favour of self-documenting code (clear names,
      small functions). Only comment where the *why* isn't obvious from the code itself.
    - **Tests**: minimise tests to those that meaningfully increase confidence in the
      code. Don't write tests for practically impossible cases or just for coverage.
    - **Merging**: squash merge pull requests. Rewrite the squashed message to follow
      the commit format above, dropping the PR number the merge UI appends. A PR that
      can't be sensibly squashed into one commit — mixed types, or too many scopes —
      should have been split into separate PRs instead.
  '';

  # Claude Code only reads settings.json (it rewrites ~/.claude.json instead),
  # so nix can own it outright.
  programs.claude-code = {
    enable = true;

    package = null; # already in home.packages

    settings = {
      model = "opus";
      theme = "dark";
      agentPushNotifEnabled = true;

      hooks = {
        SessionEnd = commandHook extractConventions "extract-conventions";
        SessionStart = commandHook conventionsNudge "conventions-nudge";
      };
    };
  };
}

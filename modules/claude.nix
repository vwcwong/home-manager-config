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
    - **Deletion test.** For every intensifier, hedge, and adverb: if cutting the
      word leaves the meaning intact, cut it. The fix is deletion, never
      substitution of a near-synonym. Words that rarely survive: "genuinely",
      "honestly", "truly", "actually", "simply", "just", "really", "quite",
      "clearly", "essentially", "of course", "that said", "it's worth noting".
    - **No negative-space framing.** Say what is true rather than what isn't. Drop
      "rather than X", "instead of X", "not X, but Y", "X, not Y" unless X is a
      real alternative the user raised or is actively deciding between.
    - **No process narration.** Don't describe how you arrived at an answer or what
      you're about to do: "let me think about", "I want to be careful here", "to be
      clear", "first I'll", "instead of assuming". State the conclusion and the
      reason for it.
    - **No performed agreement or praise.** No "you're absolutely right", "great
      question", "good catch", "exactly". Answer, or say what was wrong and
      correct it.
    - The bullets above are symptoms of one rule: every word must carry information
      the reader doesn't already have. Apply that rule to phrasings not listed
      here, including ones with the same shape as these.

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

    Default to editing in place. Use `EnterWorktree` only when the work is
    isolation-worthy — keeping a body of work off the main checkout, not a
    ceremony for every edit.

    - **Use a worktree when** any of these hold: the change spans several files or
      several commits; it is a feature or refactor headed for its own PR; it is
      experimental and may be thrown away; or the main checkout has to stay clean
      while the work is in progress.
    - **Edit in place when**: the task is read-only; the change is small and
      contained (a config tweak, a typo, a one-file fix); the user is iterating on
      something they need live in their own checkout; or the session is already on
      a suitable feature branch.
    - **When unsure**: start in place. If the change grows past a couple of files,
      or the user asks for a PR, say so and move to a worktree before going further.
    - **Timing**: enter the worktree as soon as the user confirms implementation
      should proceed — not after exploring or planning.
    - **Naming**: use the feature/fix name in kebab-case (e.g. `fix-auth`,
      `add-dark-mode`). This makes `git worktree list` readable and the branch name
      meaningful.
    - **In-place commits**: branch first if committing in place on the default branch.
    - **After implementation**: commit changes inside the worktree, then either open a PR
      or ask the user how they want to merge. Do not merge manually without asking.
    - **Exiting**: use `ExitWorktree` with `action: "keep"` when work is done or paused
      (preserves the branch for review/PR). Use `action: "remove"` only if the user
      explicitly abandons the work.
    - **Agents**: spawning an Agent with `isolation: "worktree"` is for fully delegated
      tasks, not inline work. For interactive sessions where you make changes yourself,
      use `EnterWorktree` directly.

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
        Write it in plain English: avoid identifiers, file paths, flags, and other
        code-like terms unless plain wording would lose the meaning.
      - Example: `feat(auth): Add refresh token rotation`, not
        `feat(auth): Add rotateRefreshToken() to auth/tokens.ts`
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

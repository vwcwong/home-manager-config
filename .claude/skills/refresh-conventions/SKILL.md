---
name: refresh-conventions
description: Review accumulated session findings and propose updates to the Claude config in this repo. ONLY when the user explicitly runs /refresh-conventions. Never invoke this autonomously, never as a step inside another task, and never because a session happened to touch conventions or CLAUDE.md.
---

# Refresh conventions

The `SessionEnd` hook installed by `modules/claude.nix` records durable working
preferences it spots in each finished session. This turns that pile into config
changes — or, more often, decides there is nothing worth changing yet.

## Scope

Edit only:

- `modules/claude.nix` — the global user instructions written to `~/.claude/CLAUDE.md`
- `CLAUDE.md` — this repo's agent docs
- `.claude/docs/*.md` — this repo's conventions

**Do nothing with git.** No branch, no commit, no push, no PR. Edit the working
tree, show what changed, and stop. The user decides what happens next.

## Steps

### 1. Read the findings

```
cat ~/.local/state/claude-conventions/findings.d/*.jsonl | jq -s .
```

Each record is `{ts, session_id, project, category, observation, evidence}`.

If the directory is empty or missing, say so and stop.

### 2. Cluster

Group records that say the same thing, however differently worded. Count
**distinct `session_id`s** per cluster, not records — three findings from one
long session is one session's worth of evidence, not three.

### 3. Apply the evidence bar

This is the part that matters. A config that accretes a rule every week becomes
noise, and a noisy config is worse than a short one.

- **New rule**: needs **≥3 distinct sessions**.
- **Changed rule**: needs concrete evidence the current wording misfires — the
  user correcting Claude on something the config already claims to cover.
- **Removed rule**: needs evidence it is stale, or contradicted by newer
  instructions.
- **Cap at 5 changes.** If more qualify, take the best-evidenced 5.
- Drop anything already covered by the existing config, even loosely.
- Drop anything that reads as task-specific on inspection — the extractor is
  deliberately cheap and lets some through.

**Proposing nothing is a good outcome** and should be the common one. Say
plainly that nothing met the bar rather than reaching for the closest thing.

### 4. Propose

For each surviving cluster, before editing, state:

- the rule, in the imperative, as it would read in the config
- which file it belongs in
- how many distinct sessions support it, and one short piece of evidence
- whether it is an addition, a rewording, or a removal

Match the surrounding prose style — these files are terse and use dot points.
Keep additions short; prefer rewording an existing rule over adding a new one
next to it.

### 5. Edit and report

Make the edits, then show `git diff`. Summarise in a few lines what changed and
what evidence drove it. Remind the user the config only takes effect after
`hm-switch`.

### 6. Archive what you consumed

Move every findings file you read into the applied pile, so the same evidence is
not counted again next time and the `SessionStart` nudge resets:

```
mkdir -p ~/.local/state/claude-conventions/applied.d
mv ~/.local/state/claude-conventions/findings.d/*.jsonl \
   ~/.local/state/claude-conventions/applied.d/
```

Do this even when nothing met the bar — otherwise the same rejected findings are
re-examined every run and the nudge never goes quiet.

---
name: refresh-conventions
description: Review accumulated session findings and propose updates to the Claude config in this repo. ONLY when the user explicitly runs /refresh-conventions. Never invoke this autonomously, never as a step inside another task, and never because a session happened to touch conventions or CLAUDE.md.
---

# Refresh conventions

The `SessionEnd` hook from `modules/claude.nix` records durable working
preferences it spots in each finished session. This turns that pile into config
changes — or, more often, decides there is nothing worth changing yet.

Edit only `modules/claude.nix` (the global instructions written to
`~/.claude/CLAUDE.md`), `CLAUDE.md`, and `.claude/docs/*.md`. **Do nothing with
git** — no branch, commit, push, or PR. Edit the working tree, show what
changed, and stop.

**1. Read.** `cat ~/.local/state/claude-conventions/findings.d/*.jsonl | jq -s .`
Records are `{ts, session_id, project, category, observation, evidence}`. If the
directory is empty or missing, say so and stop.

**2. Cluster.** Group records that say the same thing, however differently
worded. Count **distinct `session_id`s**, not records — three findings from one
long session is one session's worth of evidence. Check `project` too: a cluster
confined to one repo belongs in that repo's `CLAUDE.md`, not the global config.

**3. Apply the evidence bar.** A config that accretes a rule every week becomes
noise, and a noisy config is worse than a short one.

- **New rule**: needs **≥3 distinct sessions**.
- **Changed rule**: needs evidence the current wording misfires — the user
  correcting Claude on something the config already claims to cover.
- **Removed rule**: needs evidence it is stale or contradicted.
- **Cap at 5 changes**; if more qualify, take the best-evidenced 5.
- Drop anything the config already covers, even loosely, and anything that reads
  as task-specific — the extractor is cheap and lets some through.

**Proposing nothing is a good outcome** and should be the common one. Say
plainly that nothing met the bar rather than reaching for the closest thing.

**4. Propose, then edit.** For each surviving cluster, state up front: the rule
as it would read in the config, which file it belongs in, how many distinct
sessions back it with one short quote, and whether it is an addition, rewording,
or removal. Match the surrounding style — terse, dot points. Prefer rewording an
existing rule over adding a new one beside it. Then edit, show `git diff`, and
note the config only takes effect after `hm-switch`.

**5. Archive.** Do this even when nothing met the bar, or the same rejected
findings are re-examined every run and the nudge never goes quiet.

```
cd ~/.local/state/claude-conventions && mkdir -p applied.d && mv findings.d/*.jsonl applied.d/
```

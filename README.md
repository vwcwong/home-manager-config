# Home Manager Configuration
This repository contains my [Home Manager](https://nixos.wiki/wiki/Home_Manager) configuration for creating a reproducible, reliable, and cross-platform development environment.

To use this configuration, just follow these steps:
1. Install Nix via the [official installer](https://nixos.org/download/).
2. Clone this repository using `git clone https://github.com/V-Wong/home-manager-config.git ~/.config/home-manager`.
3. Start Home Manager with `nix run home-manager switch -- --impure`.
4. Restart your terminal.

## Convention analysis

Claude Code config in this repo keeps itself honest against how I actually work.

- A `SessionEnd` hook reads the user turns of each finished session and records
  any durable working preference it finds. Detached, so quitting Claude never
  waits on it, and `CLAUDE_CONVENTIONS_DISABLE=1` turns it off.
- A `SessionStart` hook mentions the pile once ten findings have accumulated.
- Running `/refresh-conventions` in this repo turns those findings into proposed
  edits to `modules/claude.nix`, `CLAUDE.md`, and `.claude/docs/`. It needs three
  distinct sessions behind a rule before suggesting it, and makes no commits.

Findings live in `~/.local/state/claude-conventions/`; consumed ones move to
`applied.d/` there. Nothing changes the config without review.

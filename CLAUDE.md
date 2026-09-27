# Home Manager Configuration

Nix flake that builds a Home Manager configuration for macOS (`aarch64-darwin`)
and Linux (`x86_64-linux`).

## Layout

- `flake.nix`: inputs and the single `homeConfigurations.<user>` output.
  Tracks nixpkgs-unstable and Home Manager master.
- `home.nix`: packages and module imports.
- `modules/*.nix`: one module per program (Claude Code, direnv, Git, tmux, Zed,
  Zsh).
- `modules/claude/`: files behind `modules/claude.nix`. `CLAUDE.md` becomes the
  global `~/.claude/CLAUDE.md`. Hook scripts live in separate `.sh` files so
  `writeShellApplication` can shellcheck them at build time.
- `zsh/p10k.zsh`: Powerlevel10k prompt config.

## Development Workflow

The flake reads `$USER` and probes the filesystem for the platform, so every
command needs `--impure`.

- Validate a change without applying it:

  ```
  nix build ".#homeConfigurations.$(whoami).activationPackage" --impure --no-link
  ```

- Apply it to the machine: `home-manager switch --impure` (alias `hm-switch`).
  This changes the user's live environment; ask before running it.
- CI builds the same activation package on macOS and Linux for every push and
  pull request to `main`. A scheduled job updates `flake.lock` daily.

## Conventions

- [@.claude/docs/git-conventions.md](.claude/docs/git-conventions.md) - Git
  commit message conventions

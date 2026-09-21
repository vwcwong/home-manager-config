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
  # Claude Code only reads settings.json (it rewrites ~/.claude.json instead),
  # so nix can own it outright.
  programs.claude-code = {
    enable = true;

    package = null; # already in home.packages

    context = ./claude/CLAUDE.md;

    settings = {
      model = "opus";
      outputStyle = "Concise";
      theme = "dark";
      agentPushNotifEnabled = true;

      hooks = {
        SessionEnd = commandHook extractConventions "extract-conventions";
        SessionStart = commandHook conventionsNudge "conventions-nudge";
      };
    };
  };
}

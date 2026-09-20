{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.email = "vincent@vwong.dev";
      user.name = "Vincent Wong";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
    # Excludes-file patterns match from the working tree root, so `**/` is
    # needed to catch copies outside it.
    ignores = [
      "**/.claude/settings.local.json"
      "**/.claude/worktrees/"
    ];
  };
}

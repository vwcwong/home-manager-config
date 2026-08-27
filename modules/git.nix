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
  };
}

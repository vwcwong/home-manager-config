{ ... }:
{
  programs.git = {
    enable = true;
    userEmail = "vincent@vwong.dev";
    userName = "Vincent Wong";
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };
}

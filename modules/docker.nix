{ pkgs, lib, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  systemd.user.services.docker = {
    Unit.Description = "Docker daemon (rootless)";
    Service = {
      Type = "notify";
      NotifyAccess = "all";
      ExecStart = "${pkgs.docker}/bin/dockerd-rootless";
      ExecReload = "${pkgs.coreutils}/bin/kill -s HUP $MAINPID";
      Delegate = true;
      KillMode = "mixed";
      Restart = "always";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.sessionVariables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/docker.sock";
}

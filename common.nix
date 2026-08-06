{ config, lib, pkgs, ... }:

{
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  environment.variables = { EDITOR = "vim"; };
  environment.systemPackages = with pkgs; [
    # IMPORTANT
    # 1. Check if an Option exists first: https://search.nixos.org/options
    # 2. Always sort packages alphabetically

    bind # dig, nslookup, ...
    btop
    curl
    htop
    iputils # ping, tracepath, ...
    kubectl
    kubernetes-helm
    lsof
    netcat
    openssl
    restic
    socat
    sysstat
    tcpdump
    tmux
    trash-cli
    tree
    usbutils
    vim
  ];

  networking.useNetworkd = true;
  systemd.network.wait-online.anyInterface = true;
  # Cilium (Kubernetes) is used as firewall
  networking.firewall.enable = false;

  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
    };
  };

  programs.fish = {
    enable = true;
    promptInit = ''
      set -U fish_greeting
      alias rm="rm -i"

      if test "$TERM" != "linux"
        # show all themes with: fish_config theme show
        fish_config theme choose catppuccin-mocha --color-theme=dark
      end
    '';
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      insecure-registries = [ "dean-homelab:5000" ];
    };
  };

  # only require sudo password every 60 min
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=60
  '';

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
    extraConfig = ''
      Match user git
        AllowTcpForwarding no
        AllowAgentForwarding no
        PasswordAuthentication no
        PermitTTY no
        X11Forwarding no
    '';
  };

  # run commands at specific time
  services.atd.enable = true;

  services.sysstat = {
      enable = true;
      # every 10 minutes
      collect-frequency = "*:00/10";
  };

  users.groups.devops = {};

  users.users.dean = {
    isNormalUser = true;
    extraGroups = [ "devops" "wheel" ]; # Enable `sudo` for the user.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+E5ey8cjpUlHALMBFbDy9ijCd0M+w0iz0VIIE5cM77 dean-home"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKAmMvFppJL6njZ45WthZ3kM1Aq7bdPjbp+IsHUapOMm deanqx-pad"
    ];
    shell = pkgs.fish;
    packages = with pkgs; [
    ];
  };

  services.comin = {
    enable = true;
    remotes = [{
      name = "origin";
      url = "https://github.com/deanqx/homelab-nixos";
      branches.main.name = "main";
    }];
  };

  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];

    # garbage collect packages
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # remove dublicate packages
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  system.stateVersion = "26.05";
}

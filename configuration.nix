{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 28d";
  };

  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      user.name = "deanqx";
      user.email = "dean@kowatsch.de";
      push.autoSetupRemote = true;
    };
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "sudo" ];
      theme = "robbyrussell";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      iputils # ping, tracepath, arping, clockdiff 
      netcat
      curl
      wget
      nmap
      openssl
      htop
      sysstat
      tmux
      tree
      trash-cli
    ];

    variables.VIMINIT = "source /etc/vimrc";
    etc."vimrc".text = ''
      syntax on
      set number
      set relativenumber
      set autoindent
      set smartindent
      set smarttab       " Tab behaves according to shiftwidth
      set expandtab      " Convert tabs to spaces (optional, but recommended)
      set shiftwidth=4   " Default number of spaces for each indent
      set tabstop=4      " Number of spaces a tab counts for
      set softtabstop=4  " How many spaces Tab inserts in insert mode
    '';
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "dean@kowatsch.de";
  };

  services.openssh = {
    enable = true;
    ports = [ 54359 ];
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

  networking = {
    hostName = "dean-homelab";
    networkmanager.enable = true;

    firewall = {
      enable = true;
      logRefusedConnections = true;
      logRefusedPackets = true;
      allowedTCPPorts = [
        80 # ACME (SSL certificate)
        47539 # home assistant
      ];
    };
  };

  services.atd.enable = true;

  services.sysstat = {
      enable = true;
      collect-frequency = "*:00/1";
  };

  services.nginx = {
    enable = true;
    user = "nginx";
    group = "nginx";
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."deanqx.kowi.it" =  {
      enableACME = true;
      forceSSL = true; # required for ssl to be added to the config

      listen = [{
        addr = "0.0.0.0";
        port = 80;
      }{
        addr = "0.0.0.0";
        port = 47539;
        ssl = true;
      }];

      locations."/" = {
        proxyPass = "http://127.0.0.1:8123/";
        proxyWebsockets = true;
      };
    };
  };

  virtualisation.docker = {
      enable = true;
      daemon.settings = {
        insecure-registries = [ "dean-homelab:5000" ];
      };
  };

  users.users.dean = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable `sudo` for the user.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+E5ey8cjpUlHALMBFbDy9ijCd0M+w0iz0VIIE5cM77 dean-home"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKAmMvFppJL6njZ45WthZ3kM1Aq7bdPjbp+IsHUapOMm deanqx-pad"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
    ];
  };

  # enable git server (https://nixos.wiki/wiki/Git)
  # create repo called ".git":
  # sudo -u git sh -c "git init --bare ~/.git"
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = "/srv/git";
    createHome = true;
    shell = "${pkgs.git}/bin/git-shell";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+E5ey8cjpUlHALMBFbDy9ijCd0M+w0iz0VIIE5cM77 dean-home"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKAmMvFppJL6njZ45WthZ3kM1Aq7bdPjbp+IsHUapOMm deanqx-pad"
    ];
  };

  users.groups.git = {};

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  system.stateVersion = "25.11";
}

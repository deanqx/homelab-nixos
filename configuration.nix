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
      core.editor = "nvim";
      user.name = "deanqx";
      user.email = "dean@kowatsch.de";
      push.autoSetupRemote = true;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    configure.customLuaRC = ''
      vim.wo.number = true
      vim.wo.relativenumber = true
      vim.opt.autoindent = true
      vim.opt.smartindent = true
      vim.cmd("filetype plugin indent on")
      vim.opt.expandtab = true     -- use spaces instead of tabs
      vim.opt.tabstop = 2          -- how many spaces a tab counts for
      vim.opt.shiftwidth = 2       -- indent size
      vim.opt.softtabstop = 2      -- spaces inserted when pressing Tab
      vim.keymap.set("v", " y", "\"+y")
      -- block cursor for all modes
      vim.opt.guicursor = "n-v-i-c:block-Cursor"
      -- remove background
      vim.api.nvim_set_hl(0, "Normal", { bg = "none"})
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none"})
      vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none"})
      vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none"})
    '';
  };

  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "sudo" ];
      theme = "robbyrussell";
    };
    # alias is needed for autocompletions
    shellInit = "docker() { sudo docker \"$@\" }";
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
      kubernetes-helm
    ];

    variables = {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };
  };

  # only require sudo password every 60 min
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=60
  '';

  # mDNS, needed for Thread (Home Assistant)
  services.avahi.enable = true;

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
    nftables.enable = true;

    firewall = {
      enable = true;
      logRefusedConnections = true;
      logRefusedPackets = true;
      allowedTCPPorts = [
        80 # ACME (SSL certificate)
        6443 # k3s pod communication
        47539 # nginx SSH
      ];
    };
  };

  services.atd.enable = true;

  services.sysstat = {
      enable = true;
      collect-frequency = "*:00/1";
  };

  services.k3s = {
    enable = true;
    role = "server"; # "agent" for worker only
    extraFlags = [
      "--write-kubeconfig-mode 640"
      "--write-kubeconfig-group k3s"
    ];
  };

  # Let's Encrypt HTTPS verification
  security.acme = {
    acceptTerms = true;
    defaults.email = "dean@kowatsch.de";
  };

  services.nginx = {
    enable = true;
    user = "nginx";
    group = "nginx";
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  # TODO deanqx -> home
  # Homeassistant
  services.nginx.virtualHosts."home.kowi.it" = {
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

  # Nextcloud
  services.nginx.virtualHosts."cloud.kowi.it" = {
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

    # forwards to Kubernetes Ingress
    locations."/" = {
      proxyPass = "http://127.0.0.1:1234/";
      proxyWebsockets = true;
    };
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      insecure-registries = [ "dean-homelab:5000" ];
    };
  };

  # allows access to manage Kubernetes cluster
  users.groups.k3s = {};

  users.users.dean = {
    isNormalUser = true;
    extraGroups = [ "wheel" "k3s" ]; # Enable `sudo` for the user.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+E5ey8cjpUlHALMBFbDy9ijCd0M+w0iz0VIIE5cM77 dean-home"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIS1EgZ67VX7KNZ1IOCAwVFfZrLZLdEHlG6rGVoSJUiz dean-home-windows"
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIS1EgZ67VX7KNZ1IOCAwVFfZrLZLdEHlG6rGVoSJUiz dean-home-windows"
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

{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];

    # garbage collect packages
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 28d";
    };

    # remove dublicate packages
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      core.editor = "nvim";
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
      vim.opt.scrolloff = 8
      vim.opt.expandtab = true     -- use spaces instead of tabs
      vim.opt.tabstop = 2          -- how many spaces a tab counts for
      vim.opt.shiftwidth = 2       -- indent size
      vim.opt.softtabstop = 2      -- spaces inserted when pressing Tab
      vim.keymap.set("v", " y", "\"+y")
      vim.g.clipboard = {
        name = 'OSC 52',
        copy = {
          ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
          ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
          ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
          ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        },
      }
      -- block cursor for all modes
      vim.opt.guicursor = "n-v-i-c:block-Cursor"
      -- remove background
      vim.api.nvim_set_hl(0, "Normal", { bg = "none"})
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none"})
      vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none"})
      vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "none"})
    '';
  };

  programs.fish = {
    enable = true;
    promptInit = ''
      set -U fish_greeting
      alias rm="rm -i"

      # show all themes with: fish_config theme show
      fish_config theme choose catppuccin-mocha
    '';
  };

  environment = {
    systemPackages = with pkgs; [
      # always sort alphabetically:
      btop
      curl
      htop
      iputils # ping, tracepath, arping, clockdiff 
      kubectl
      kubernetes-helm
      netcat
      openssl
      sysstat
      tmux
      trash-cli
      tree
      wget
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

  # required for Longhorn
  services.openiscsi.enable = true;
  services.openiscsi.name = "iqn.2026-04.it.kowi.iscsi:home";

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

  networking = {
    hostName = "dean-homelab";
    networkmanager.enable = true;
    # Cilium (Kubernetes) is used as firewall
    firewall.enable = false;
    nftables.enable = false;
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      # use embedded etcd datastore
      "--cluster-init"

      # replacing with Cilium
      "--flannel-backend=none"
      "--disable-kube-proxy"
      "--disable-network-policy"

      # disable default ingress and load balancer
      "--disable=traefik"
      "--disable=servicelb"
    ];
  };

  # run commands at specific time
  services.atd.enable = true;

  services.sysstat = {
      enable = true;
      # every 10 minutes
      collect-frequency = "*:00/10";
  };

  # Let's Encrypt HTTPS verification
  security.acme = {
    acceptTerms = true;
    defaults.email = "dean@kowatsch.de";
  };

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      insecure-registries = [ "dean-homelab:5000" ];
    };
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

  users.groups.git = {};

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

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  system.stateVersion = "26.05";
}

{ config, lib, pkgs, ... }:

{
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

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
  ];

  networking.useNetworkd = true;
  systemd.network.wait-online.anyInterface = true;
  # Cilium (Kubernetes) is used as firewall
  networking.firewall.enable = false;

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
      -- search only case sensitive when one upper case letter is used
      vim.opt.smartcase = true
      vim.opt.expandtab = true  -- use spaces instead of tabs
      vim.opt.tabstop = 2       -- how many spaces a tab counts for
      vim.opt.shiftwidth = 2    -- indent size
      vim.opt.softtabstop = 2   -- spaces inserted when pressing Tab
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

      if test "$TERM" != "linux"
        # show all themes with: fish_config theme show
        fish_config theme choose catppuccin-mocha
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

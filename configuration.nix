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
      vim.opt.scrolloff = 8
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
    histSize = 80000;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };
  
  programs.zsh.promptInit = ''
    # needed for docker autocompletion
    docker() { sudo docker "$@" }

    autoload -U colors && colors
    setopt PROMPT_SUBST

    # Fix Ctrl + Left/Right arrows
    bindkey "^[[1;5C" forward-word
    bindkey "^[[1;5D" backward-word
    # Bind Ctrl + U to delete the entire line
    bindkey "^U" kill-whole-line

    prepend-sudo() {
        if [[ -z $BUFFER ]]; then
            # If the line is empty, get the last command from history
            BUFFER="sudo $(fc -ln -1)"
            # Move cursor to the end of the line
            CURSOR=''${#BUFFER}
        elif [[ $BUFFER == sudo\ * ]]; then
            # If already sudo, remove it
            LBUFFER="''${LBUFFER#sudo }"
        else
            LBUFFER="sudo $BUFFER"
        fi
    }
    
    zle -N prepend-sudo
    bindkey '^[^[' prepend-sudo
  
    PROMPT='%F{magenta}[%B%F{cyan}%n%F{white}@%F{cyan}%M%b%F{magenta}] %B%F{white}%~%b %F{magenta}$ %f'
    ZSH_HIGHLIGHT_STYLES[path]='bold'
  '';

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

    shellAliases = {
      kubectl = "sudo -E kubectl";
      helm = "sudo -E helm";
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
    nftables.enable = true;

    firewall = {
      enable = true;
      logRefusedConnections = true;
      logRefusedPackets = true;
      allowedTCPPorts = [
        80 # ACME (SSL certificate)
        443 # nginx reverse proxy SSL
        6443 # k3s pod communication
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
    role = "server";
    extraFlags = [
      # traefik is installed with Helm for more control
      "--disable=traefik"
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
    package = pkgs.angie;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    appendHttpConfig = ''
      log_format verbose_format '[$time_local] $remote_addr $remote_user -> '
                                '$http_host $request -> $status '
                                '"$http_user_agent" (in: $request_length, out: $body_bytes_sent)';

      access_log /var/log/nginx/access.log verbose_format;
    '';
  };

  # Home Assistant
  services.nginx.virtualHosts."home.kowi.it" = {
    enableACME = true;
    forceSSL = true; # required for ssl to be added to the config

    extraConfig = ''
      add_header Strict-Transport-Security 'max-age=15552000; includeSubDomains; preload' always;
    '';

    listen = [{
      addr = "0.0.0.0";
      port = 80;
    }{
      addr = "0.0.0.0";
      port = 443;
      ssl = true;
    }];

    locations."/" = {
      proxyPass = "http://127.0.0.1:8123/";
      proxyWebsockets = true;
    };
  };

  # Cloud (hosted in Kubernetes)
  services.nginx.virtualHosts."cloud.kowi.it" = {
    enableACME = true;
    forceSSL = true; # required for ssl to be added to the config

    extraConfig = ''
      add_header Strict-Transport-Security 'max-age=15552000; includeSubDomains; preload' always;
    '';

    listen = [{
      addr = "0.0.0.0";
      port = 80;
    }{
      addr = "0.0.0.0";
      port = 443;
      ssl = true;
    }];

    # forwards to Kubernetes Ingress
    locations."/" = {
      proxyPass = "http://127.0.0.1:9080/";
      proxyWebsockets = true;
    };
  };

  # Dashboard for Kubernetes
  services.nginx.virtualHosts."dashboard.kowi.it" = {
    enableACME = true;
    forceSSL = true; # required for ssl to be added to the config

    # nix-shell --packages apacheHttpd --extra-experimental-features flakes \
    # --run 'sudo htpasswd -B -c /etc/nginx/.dashboard-passwd USER'
    # sudo chmod 600 /etc/nginx/.dashboard-passwd
    basicAuthFile = "/etc/nginx/.dashboard-passwd";

    extraConfig = ''
      add_header Strict-Transport-Security 'max-age=15552000; includeSubDomains; preload' always;
    '';

    listen = [{
      addr = "0.0.0.0";
      port = 80;
    }{
      addr = "0.0.0.0";
      port = 443;
      ssl = true;
    }];

    # forwards to Kubernetes Ingress
    locations."/" = {
      proxyPass = "http://127.0.0.1:9080/";
      proxyWebsockets = true;
    };
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
    shell = pkgs.zsh;
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

  system.stateVersion = "25.11";
}

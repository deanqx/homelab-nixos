{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  environment.systemPackages = with pkgs; [
    tmux
    curl
    wget
    htop
    docker
  ];

  networking.hostName = "dean-homelab";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  users.users.dean = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable `sudo` for the user.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+E5ey8cjpUlHALMBFbDy9ijCd0M+w0iz0VIIE5cM77 dean_home_linux"
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [
    ];
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
  environment.variables.VIMINIT = "source /etc/vimrc";
  environment.etc."vimrc".text = ''
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

  programs.zsh.enable = true;
  programs.zsh.ohMyZsh = {
    enable = true;
    plugins = [ "sudo" ];
    theme = "robbyrussell";
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

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
}

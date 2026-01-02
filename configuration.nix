{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "dean-homelab";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    # keyMap = "us";
    useXkbConfig = true;
  };

  users.users.dean = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
  };

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

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    zsh
    tmux
    curl
    wget
    htop
  ];

  system.stateVersion = "25.11";
}

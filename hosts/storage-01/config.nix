{ config, pkgs, ... }:

{
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "storage-01";
  networking.wireless.iwd.enable = true;

  systemd.network.networks = {
    "10-ethernet" = {
      matchConfig.Name = "enp0s25";
      networkConfig.DHCP = "yes";
      dhcpV4Config.RouteMetric = 10; # priority
    };
    "20-wlan" = {
      matchConfig.Name = "wlp0s29f7u4";
      networkConfig.DHCP = "yes";
      dhcpV4Config.RouteMetric = 20; # priority
    };
  };
}

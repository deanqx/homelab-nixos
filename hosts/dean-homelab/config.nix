{ config, lib, pkgs, ... }:

{
  networking.hostName = "dean-homelab";
  networking.wireless.iwd.enable = true;

  systemd.services."home_assistant_backup" = {
    path = with pkgs; [
      bash
      restic
      libvirt
    ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "/usr/local/sbin/home_assistant_backup.sh";
    };
  };

  systemd.timers."home_assistant_backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "home_assistant_backup.service";
      OnCalendar = "*-*-* 03:00:00";
      # run even if system was off at the time
      Persistent = true;
    };
  };

  systemd.network.netdevs = {
    "10-br0" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br0";
      };
    };
  };

  systemd.network.networks = {
    "20-ethernet" = {
      matchConfig.Name = "enp1s0";
      networkConfig.Bridge = "br0";
      linkConfig.RequiredForOnline = "enslaved";
    };

    "30-br0" = {
      matchConfig.Name = "br0";
      networkConfig.DHCP = "yes";
      linkConfig.RequiredForOnline = "routable";
    };
  };

  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      # use embedded etcd datastore
      "--cluster-init"

      # expose for monitoring
      "--kube-controller-manager-arg='bind-address=0.0.0.0'"
      "--kube-scheduler-arg='bind-address=0.0.0.0'"

      # replacing with Cilium
      "--flannel-backend=none"
      "--disable-kube-proxy"
      "--disable-network-policy"

      # disable default ingress and load balancer
      "--disable=traefik"
      "--disable=servicelb"
    ];
  };

  # required for Longhorn
  services.openiscsi.enable = true;
  services.openiscsi.name = "iqn.2026-04.it.kowi.iscsi:home";

  environment.variables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
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

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 5;
    efi.canTouchEfiVariables = true;
  };
}

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Basic system setup
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.devNodes = "/dev/disk/by-id";
  boot.zfs.requestEncryptionCredentials = false;

  # Required for ephemeral root
  boot.initrd.supportedFilesystems = [ "zfs" ];

  boot.initrd.systemd = {
    enable = true;
    services.initrd-rollback-root = {
      after = [ "zfs-import-rpool.service" ];
      wantedBy = [ "initrd.target" ];
      before = [
        "sysroot.mount"
      ];
      path = [ pkgs.zfs ];
      description = "Rollback root fs";
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = "zfs rollback -r rpool/nixos/empty@start";
    };
  };



  networking.hostId = ""; # replace with your 8-hex hostId

  fileSystems."/" = lib.mkForce {
    device = "rpool/nixos/empty";
    fsType = "zfs";
  };

  fileSystems."/nix" = {
    device = "rpool/nixos/nix";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/etc/nixos" = {
    device = "rpool/nixos/config";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/boot" = {
    device = "bpool/nixos/root";
    fsType = "zfs";
  };

  fileSystems."/var/log" = {
    device = "rpool/nixos/var/log";
    fsType = "zfs";
    neededForBoot = true;
  };

  fileSystems."/var/lib" = {
    device = "rpool/nixos/var/lib";
    fsType = "zfs";
    neededForBoot = true;
  };



  # Basic bootloader (UEFI + GRUB with ZFS support)
  #boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efis/virtio-fzsdisk0-part2";;
  
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    zfsSupport = true;
    devices = [ "nodev" ];
  };


  # Minimal packages
  environment.systemPackages = with pkgs; [ vim git ];

  # Networking
  networking.hostName = "nixos";

  # Users
  users.users.root.initialPassword = "root";
}

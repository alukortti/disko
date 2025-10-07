{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader (UEFI + systemd-boot)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Filesystems (compact format)
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-id/virtio-zfsdisk0-part2";
      fsType = "btrfs";
      options = [ "subvol=@root" "compress=zstd" ];
    };

    "/nix" = {
      device = "/dev/disk/by-id/virtio-zfsdisk0-part2";
      fsType = "btrfs";
      options = [ "subvol=@nix" "compress=zstd" "noatime" ];
      neededForBoot = true;
    };

    "/var/log" = {
      device = "/dev/disk/by-id/virtio-zfsdisk0-part2";
      fsType = "btrfs";
      options = [ "subvol=@var_log" "compress=zstd" ];
      neededForBoot = true;
    };

    "/var/lib" = {
      device = "/dev/disk/by-id/virtio-zfsdisk0-part2";
      fsType = "btrfs";
      options = [ "subvol=@var_lib" "compress=zstd" ];
      neededForBoot = true;
    };

    "/etc/nixos" = {
      device = "/dev/disk/by-id/virtio-zfsdisk0-part2";
      fsType = "btrfs";
      options = [ "subvol=@etc_nixos" "compress=zstd" ];
      neededForBoot = true;
    };

    "/persistent" = {
      device = "/dev/disk/by-id/virtio-zfsdisk0-part2";
      fsType = "btrfs";
      options = [ "subvol=@persistent" "compress=zstd" ];
      neededForBoot = true;
    };

    "/boot/efi" = {
      device = "/dev/disk/by-id/virtio-zfsdisk0-part1";
      fsType = "vfat";
    };
  };

  # Optional: impermanence-style root recreation before mount
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir -p /btrfs_tmp
    mount -t btrfs -o subvolid=5 /dev/disk/by-id/virtio-zfsdisk0-part2 /btrfs_tmp

    if [[ -e /btrfs_tmp/@root ]]; then
      mkdir -p /btrfs_tmp/old_roots
      timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@root)" "+%Y-%m-%d_%H-%M-%S")
      btrfs subvolume snapshot -r /btrfs_tmp/@root "/btrfs_tmp/old_roots/$timestamp" || true
      btrfs subvolume delete /btrfs_tmp/@root || true
    fi

    find /btrfs_tmp/old_roots -mindepth 1 -maxdepth 1 -mtime +30 -print0 \
      | xargs -0r -I{} btrfs subvolume delete "{}" || true

    btrfs subvolume create /btrfs_tmp/@root
    umount /btrfs_tmp
  '';

  # Impermanence
  environment.persistence."/persistent" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
    ];
    files = [
      "/etc/machine-id"
      { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
    ];
    users.alukortti = {
      directories = [
        "Downloads"
        "Music"
        "Pictures"
        "Documents"
        "Videos"
        "VirtualBox VMs"
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".nixops"; mode = "0700"; }
        { directory = ".local/share/keyrings"; mode = "0700"; }
        ".local/share/direnv"
      ];
      files = [ ".screenrc" ];
    };
  };

  networking.hostName = "nixos";
  time.timeZone = "Europe/Helsinki";

  users.users.root.initialPassword = "root";
  users.users.alukortti = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "alukortti";
  };

  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}

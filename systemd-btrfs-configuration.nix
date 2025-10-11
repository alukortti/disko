{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader (UEFI + systemd-boot)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  networking.networkmanager.enable = true;
  networking.useDHCP = false;
  systemd.services.systemd-udev-settle.enable = false;
  systemd.services.NetworkManager-wait-online.enable = false;

  services = {
    greetd = {
      enable = true;
      useTextGreeter = true;
      settings = {
        initial_session = {
          command = "uwsm start hyprland-uwsm.desktop";
          user = "alukortti";
        };
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet -w 69 -t --time-format '%B, %A %d @ %H:%M:%S' -r --remember-session --asterisks --user-menu --container-padding 1 --prompt-padding 0 --theme 'border=magenta;text=white;prompt=cyan;time=green;action=yellow;button=red;container=black;input=white'";
          user = "greeter";
        };
      };
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_with_Heatsink_4TB_S7HRNJ0X102024V_1-part2";
    fsType = "btrfs";
    options = ["subvol=root"];
  };

  boot.initrd.postResumeCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount nvme-Samsung_SSD_990_PRO_with_Heatsink_4TB_S7HRNJ0X102024V_1-part2 /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  fileSystems."/persistent" = {
    device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_with_Heatsink_4TB_S7HRNJ0X102024V_1-part2";
    neededForBoot = true;
    fsType = "btrfs";
    options = ["subvol=persistent"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_with_Heatsink_4TB_S7HRNJ0X102024V_1-part2";
    fsType = "btrfs";
    options = ["subvol=nix"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_with_Heatsink_4TB_S7HRNJ0X102024V_1-part1";
    fsType = "vfat";
  };

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
      {
        directory = "/var/lib/colord";
        user = "colord";
        group = "colord";
        mode = "u=rwx,g=rx,o=";
      }
    ];
    files = [
      "/etc/machine-id"
      {
        file = "/var/keys/secret_file";
        parentDirectory = {mode = "u=rwx,g=,o=";};
      }
    ];
    users.alukortti = {
      directories = [
        "Downloads"
        "Music"
        "Pictures"
        "Documents"
        "Videos"
        {
          directory = ".gnupg";
          mode = "0700";
        }
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".nixops";
          mode = "0700";
        }
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
        ".local/share/direnv"
      ];
      files = [".screenrc"];
    };
  };

  networking.hostName = "alukortti";
  time.timeZone = "Europe/Helsinki";

  users.users.root.initialPassword = "root";
  users.users.alukortti = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    initialPassword = "alukortti";
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}

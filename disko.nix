{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          bios = {
            size = "1M";
            type = "EF02";
          };
          efi = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
            };
          };
          bpool = {
            size = "4G";
            content = {
              type = "zfs";
              pool = "bpool";
            };
          };
          rpool = {
            end = "-1M";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    zpool.bpool = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
        compatibility = "grub2";
      };
      rootFsOptions = {
        acltype = "posixacl";
        canmount = "off";
        compression = "lz4";
        devices = "off";
        normalization = "formD";
        relatime = "on";
        xattr = "sa";
        "com.sun:auto-snapshot" = "false";
      };
      datasets = {
        nixos = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "nixos/root" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/boot";
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        acltype = "posixacl";
        canmount = "off";
        compression = "zstd";
        dnodesize = "auto";
        normalization = "formD";
        relatime = "on";
        xattr = "sa";
        "com.sun:auto-snapshot" = "false";
      };

      datasets = {
        nixos = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };

        # empty template dataset, not mounted
        "nixos/empty" = {
          type = "zfs_fs";
          options.mountpoint = "none";
          postCreateHook = "zfs snapshot rpool/nixos/empty@start";
        };

        # real root dataset (cloned manually from empty@start)
        #"nixos/root" = {
        #  type = "zfs_fs";
        #  options.mountpoint = "legacy";
        #  mountpoint = "/";
        #};

        "nixos/home" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/home";
        };
        "nixos/data" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/mnt/user";
        };
        "nixos/var" = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        "nixos/var/lib" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/var/lib";
        };
        "nixos/var/log" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/var/log";
        };
        "nixos/config" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/etc/nixos";
        };
        "nixos/persist" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/persist";
        };
        "nixos/nix" = {
          type = "zfs_fs";
          options.mountpoint = "legacy";
          mountpoint = "/nix";
        };
      };
    };
  };
}

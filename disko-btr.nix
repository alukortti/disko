let
  diskMain = "virtio-zfsdisk0";
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/${diskMain}";
        content = {
          type = "gpt";
          partitions = {
            efi = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
              };
            };
            root = {
              end = "-1M";
              content = {
                type = "btrfs";
                subvolumes = {
                  "/@root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "relatime" "ssd" "discard=async" ];
                  };
                  "/@var_log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "relatime" "ssd" "discard=async" ];
                  };
                  "/@var_lib" = {
                    mountpoint = "/var/lib";
                    mountOptions = [ "compress=zstd" "relatime" "ssd" "discard=async" ];
                  };
                  "/@etc_nixos" = {
                    mountpoint = "/etc/nixos";
                    mountOptions = [ "compress=zstd" "relatime" "ssd" "discard=async" ];
                  };
                  "/@persistent" = {
                    mountpoint = "/persistent";
                    mountOptions = [ "compress=zstd" "relatime" "ssd" "discard=async" ];
                  };
                  "/@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "relatime" "ssd" "discard=async" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}

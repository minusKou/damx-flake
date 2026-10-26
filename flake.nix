{
  description = "Div Acer Manager Max (DAMX) for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    linuwu-sense-src = {
      url = "github:0x7375646F/Linuwu-Sense";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, linuwu-sense-src, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Source for the DAMX suite GUI & Daemon
      damx-source = pkgs.fetchzip {
        url = "https://github.com/PXDiv/Div-Acer-Manager-Max/releases/download/v0.9.1/DAMX-0.9.1.tar.xz";
        hash = "sha256-XU8BC3KrgRRoXrTc1tYFFxqsKhZQVX6u4ch6b57Y7bs=";
      };
    in
    {
      # Expose packages so you can build them independently with `nix build`
      packages.${system} = {
        damx-suite = pkgs.callPackage ./pkgs/damx-suite.nix { src = damx-source; };
        # Use official upstream 0x7375646F/Linuwu-Sense source
        linuwu-sense = pkgs.callPackage ./pkgs/linuwu-sense.nix { src = linuwu-sense-src; };
        default = self.packages.${system}.damx-suite;
      };

      # Expose the NixOS Module
      nixosModules.default = { config, lib, pkgs, ... }: {
        options.programs.damx = {
          enable = lib.mkEnableOption "Div Acer Manager Max (DAMX)";
        };

        config = lib.mkIf config.programs.damx.enable {
          # Install the GUI and Daemon
          environment.systemPackages = [ self.packages.${system}.damx-suite ];

          # Compile and load kernel module directly from upstream repository
          boot.extraModulePackages = [
            (config.boot.kernelPackages.callPackage ./pkgs/linuwu-sense.nix { src = linuwu-sense-src; })
          ];
          boot.kernelModules = [ "linuwu_sense" ];

          # Setup the Daemon background service
          systemd.services.damx-daemon = {
            description = "DAMX Daemon for Acer laptops";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = "${self.packages.${system}.damx-suite}/bin/DAMX-Daemon";
              Restart = "on-failure";
              RestartSec = 5;
              User = "root";
              StandardOutput = "journal";
              StandardError = "journal";
            };
          };
        };
      };
    };
}

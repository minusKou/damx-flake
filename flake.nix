{
  description = "Div Acer Manager Max (DAMX) for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # 1. Expose the GUI and Daemon packages
      packages.${system} = {
        damx-suite = pkgs.callPackage ./pkgs/damx-suite.nix {};
        default = self.packages.${system}.damx-suite;
      };

      # 2. Expose the NixOS Module (The magic 1-liner for users)
      nixosModules.default = { config, lib, pkgs, ... }: {
        options.programs.damx = {
          enable = lib.mkEnableOption "Div Acer Manager Max (DAMX)";
        };

        config = lib.mkIf config.programs.damx.enable {
          # Install the GUI and Daemon
          environment.systemPackages = [ self.packages.${system}.damx-suite ];

          # Compile and load the kernel module for their specific kernel
          boot.extraModulePackages = [
            (config.boot.kernelPackages.callPackage ./pkgs/linuwu-sense.nix {})
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

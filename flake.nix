{
  description = "Div Acer Manager Max (DAMX) for NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # 1. Define the source ONCE here. Nix will cache this single download 
      # and share it between both the suite and the kernel module!
      damx-source = pkgs.fetchzip {
        url = "https://github.com/PXDiv/Div-Acer-Manager-Max/releases/download/v0.9.1/DAMX-0.9.1.tar.xz";
        hash = "sha256:d9a9ad5a4661f8048f98dea9e9a956a3cb219eba72ec076144694075ced69484";
      };
    in
    {
      # Expose packages so you can build them independently with `nix build`
      packages.${system} = {
        # Pass the pre-downloaded source directly into both package derivations
        damx-suite = pkgs.callPackage ./pkgs/damx-suite.nix { src = damx-source; };
        linuwu-sense = pkgs.callPackage ./pkgs/linuwu-sense.nix { src = damx-source; };
        default = self.packages.${system}.damx-suite;
      };

      # Expose the NixOS Module (The magic 1-liner for users)
      nixosModules.default = { config, lib, pkgs, ... }: {
        options.programs.damx = {
          enable = lib.mkEnableOption "Div Acer Manager Max (DAMX)";
        };

        config = lib.mkIf config.programs.damx.enable {
          # Install the GUI and Daemon
          environment.systemPackages = [ self.packages.${system}.damx-suite ];

          # Compile and load the kernel module targeting the user's running kernel
          boot.extraModulePackages = [
            (config.boot.kernelPackages.callPackage ./pkgs/linuwu-sense.nix { src = damx-source; })
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

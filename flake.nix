{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    wine-overlays = {
      url = "github:clemenscodes/wine-overlays";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
  };
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        (inputs.wine-overlays.overlays.wine)
        (self.overlays.${system}.default)
      ];
    };
    inherit (pkgs) lib;
  in {
    nixosModules = {
      ${system} = {
        default = import ./nix/modules {inherit self inputs pkgs lib;};
      };
    };
    overlays = {
      ${system} = {
        default = import ./nix/overlays {inherit self;};
      };
    };
    packages = {
      ${system} = {
        inherit (pkgs) warcraft-install-scripts warcraft-scripts;
        default = self.packages.${system}.warcraft-install-scripts;
      };
    };
    formatter = {
      ${system} = pkgs.alejandra;
    };
    devShells = {
      ${system} = {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            curl
            protonplus
            wine # using custom wine from overlay
            winetricks-compat # symlinked wine from overlay to wine64
            winetricks # works normally thanks to overlay
            warcraft-install-scripts
            warcraft-scripts
          ];
          shellHook = ''
            export WINEPATH="$HOME/Games"
            export WINEPREFIX="$WINEPATH/W3Champions"
          '';
        };
      };
    };
  };
}

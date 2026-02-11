{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    warcraft-vulkan-overlay = {
      url = "github:clemenscodes/warcraft-vulkan-overlay";
    };
    wine-overlays = {
      url = "github:clemenscodes/wine-overlays";
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
        (self.overlays.${system}.default)
        (final: prev: let
          inherit (inputs.wine-overlays.packages.${system}) wine-11_2 winetricks-compat-11_2;
        in {
          wine = wine-11_2;
          winetricks-compat = winetricks-compat-11_2;
        })
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
        inherit (inputs.warcraft-vulkan-overlay.packages.${system}) warcraft-vulkan-overlay;
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
            export VK_LOADER_DEBUG="none"
            export DXVK_LOG_LEVEL="none"
            export WINEDEBUG="-all"
            export WINEPATH="$HOME/Games"
            export WINEPREFIX="$WINEPATH/W3Champions"
            export W3="$WINEPREFIX/drive_c/Program Files (x86)/Warcraft III/_retail_/x86_64/Warcraft III.exe"
            export W3_CASC="$WINEPREFIX/drive_c/Program Files (x86)/Warcraft III/Data"
            export W3C="$WINEPREFIX/drive_c/Program Files/W3Champions/W3Champions.bat"
          '';
        };
      };
    };
  };
}

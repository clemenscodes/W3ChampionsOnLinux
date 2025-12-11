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
        inherit (pkgs) warcraft-install-scripts;
        default = self.packages.${system}.warcraft-install-scripts;
      };
    };
    formatter = {
      ${system} = pkgs.alejandra;
    };
    devShells = {
      ${system} = {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.curl
            pkgs.protonplus
            pkgs.wine # using custom wine from overlay
            pkgs.winetricks-compat # symlinked wine from overlay to wine64
            pkgs.winetricks
            self.packages.${system}.warcraft-install-scripts
          ];
          shellHook = ''
            export DOWNLOADS="$HOME/Downloads"
            export WINEPATH="$HOME/Games"
            export WINEPREFIX="$WINEPATH/W3Champions"

            export DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"
            export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
            export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
            export APPDATA="$WINEPREFIX/drive_c/users/$USER/AppData"
            export APPDATA_LOCAL="$APPDATA/Local"
            export APPDATA_ROAMING="$APPDATA/Roaming"

            export BNET_HOME="$PROGRAM_FILES86/Battle.net"
            export BNET_EXE="$BNET_HOME/Battle.net.exe"

            export WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"
            export WARCRAFT_CONFIG_HOME="$DOCUMENTS/Warcraft III"

            export W3C_SETUP_EXE="$DOWNLOADS/W3Champions_latest_x64_en-US.msi"
            export W3C_EXE="$PROGRAM_FILES/W3Champions/W3Champions.exe"
            export W3C_APPDATA="$APPDATA_LOCAL/com.w3champions.client"
          '';
        };
      };
    };
  };
}

{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    lutris-overlay = {
      url = "github:clemenscodes/lutris-overlay";
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
        (inputs.lutris-overlay.overlays.lutris)
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
          buildInputs = [
            pkgs.curl
            self.packages.${system}.warcraft-install-scripts
            self.packages.${system}.warcraft-scripts
          ];
          shellHook = ''
            export WINEPATH="$HOME/Games"
            export WINEPREFIX="$WINEPATH/W3Champions"
            export WINEARCH="win64"
            export WINEDEBUG="-all"

            export PROTON_VERB=run

            export DOWNLOADS="$WINEPREFIX/drive_c/users/$USER/Downloads"
            export DOCUMENTS="$WINEPREFIX/drive_c/users/$USER/Documents"
            export PROGRAM_FILES="$WINEPREFIX/drive_c/Program Files"
            export PROGRAM_FILES86="$WINEPREFIX/drive_c/Program Files (x86)"
            export APPDATA="$WINEPREFIX/drive_c/users/$USER/AppData"
            export APPDATA_LOCAL="$APPDATA/Local"
            export APPDATA_ROAMING="$APPDATA/Roaming"

            export WARCRAFT_HOME="$PROGRAM_FILES86/Warcraft III"
            export WARCRAFT_CONFIG_HOME="$DOCUMENTS/Warcraft III"

            export WEBVIEW2_SETUP_EXE="$DOWNLOADS/MicrosoftEdgeWebview2Setup.exe"
            export WEBVIEW2_HOME="$PROGRAM_FILES86/Microsoft/EdgeCore"
            export WEBVIEW2_URL="https://go.microsoft.com/fwlink/?linkid=2124703"

            export W3C_LEGACY_SETUP_EXE="$DOWNLOADS/w3c-setup.exe"
            export W3C_LEGACY_EXE="$APPDATA_LOCAL/Programs/w3champions/w3champions.exe"
            export W3C_DATA="$APPDATA_LOCAL/com.w3champions.client"
            export W3C_LEGACY_URL="https://update-service.w3champions.com/api/launcher/win"

            export W3C_SETUP_EXE="$DOWNLOADS/W3Champions_latest_x64_en-US.msi"
            export W3C_EXE="$PROGRAM_FILES/W3Champions/W3Champions.exe"
            export W3C_APPDATA="$APPDATA_LOCAL/com.w3champions.client"
            export W3C_URL="https://update-service.w3champions.com/api/launcher-e"

            echo "NOTE: Warcraft III will not run when using umu-launcher. GPU crashes. Please help fix."
          '';
        };
      };
    };
  };
}

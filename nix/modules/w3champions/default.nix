{
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: {
  imports = [(import ./warcraft {inherit inputs pkgs lib;})];
  options = {
    w3champions = {
      enable = lib.mkEnableOption "Enable W3Champions" // {default = false;};
      name = lib.mkOption {
        type = lib.types.str;
        example = "player";
        description = "The name of the user to install scripts for";
      };
      prefix = lib.mkOption {
        type = lib.types.str;
        default = "Games/W3Champions";
        example = ".local/share/games/W3Champions";
        description = "Where the wineprefix will be for W3Champions, relative to $HOME";
      };
    };
  };
}

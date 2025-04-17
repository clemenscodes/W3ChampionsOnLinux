{
  self,
  inputs,
  pkgs,
  lib,
  ...
}: {
  config,
  system,
  ...
}: let
  cfg = config.w3champions.flo;
in {
  imports = [inputs.flo.nixosModules.flo];
  options = {
    w3champions = {
      flo = {
        enable = lib.mkEnableOption "Enable W3Champions FLO" // {default = false;};
      };
    };
  };
  config = lib.mkIf (cfg.enable) {
    services = {
      flo = {
        inherit (cfg) enable;
      };
    };
  };
}

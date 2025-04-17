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
  config = lib.mkIf (cfg.enable) {
    services = {
      flo = {
        inherit (cfg) enable;
      };
    };
  };
}

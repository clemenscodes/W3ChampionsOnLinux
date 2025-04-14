{
  self,
  inputs,
  pkgs,
  lib,
  ...
}: {...}: {
  imports = [
    (import ./w3champions {
      inherit
        self
        inputs
        pkgs
        lib
        ;
    })
  ];
}

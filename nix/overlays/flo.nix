{
  self,
  pkgs,
  ...
}: {
  inherit (self.inputs.flo.packages.x86_64-linux) flo;
}

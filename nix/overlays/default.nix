{self, ...}: (final: pkgs: {
  inherit (import ./warcraft-install-scripts.nix {inherit self pkgs;}) warcraft-install-scripts;
})

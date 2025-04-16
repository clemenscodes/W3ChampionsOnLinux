{self, ...}: (final: pkgs: {
  inherit (import ./warcraft-scripts.nix {inherit self pkgs;}) warcraft-scripts;
  inherit (import ./warcraft-install-scripts.nix {inherit self pkgs;}) warcraft-install-scripts;
})

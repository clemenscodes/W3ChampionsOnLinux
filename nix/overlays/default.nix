{self, ...}: (final: pkgs: {
  inherit
    (import ./warcraft-scripts.nix {
      inherit self;
      pkgs = final;
    })
    warcraft-scripts
    ;
  inherit
    (import ./warcraft-install-scripts.nix {
      inherit self;
      pkgs = final;
    })
    warcraft-install-scripts
    ;
})

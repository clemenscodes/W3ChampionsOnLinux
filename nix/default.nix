{
  self,
  pkgs,
  ...
}: {
  warcraft-install-scripts = let
    scripts = import ./scripts {inherit self pkgs;};
  in
    pkgs.symlinkJoin {
      name = "warcraft-install-scripts";
      paths = with scripts; [
        webview2
        w3champions
        w3champions-legacy
        bonjour
        install-warcraft
        warcraft
        warcraft-copy
        warcraft-settings
        w3c-login-bypass
      ];
    };
}

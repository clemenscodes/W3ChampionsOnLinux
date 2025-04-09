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
        install-webview2
        install-w3champions
        install-w3champions-legacy
        bonjour
        install-warcraft
        warcraft-copy
        warcraft-settings
        w3c-login-bypass
        focus-warcraft-game
      ];
    };
}

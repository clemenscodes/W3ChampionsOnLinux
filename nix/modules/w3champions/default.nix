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
  cfg = config.w3champions;
  inherit (self.packages.${system}) warcraft-scripts warcraft-install-scripts;
  inherit (cfg) name;
in {
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
  config = lib.mkIf (cfg.enable) {
    networking = {
      firewall = {
        # TODO: figure out which firewall config permits LAN games in WC3
        # Default firewall configuration blocks the traffic for hosting LAN games
        # and thus prevents W3C from working whatsoever
        enable = lib.mkForce false;
      };
    };
    environment = {
      systemPackages = [
        warcraft-scripts
        warcraft-install-scripts
        pkgs.protonplus
      ];
    };
    home-manager = {
      users = {
        ${name} = {
          home = {
            sessionVariables = {
              WARCRAFT_WINEPREFIX = "$HOME/${cfg.prefix}";
              WARCRAFT_HOME = let
                prefix = config.home-manager.users.${name}.home.sessionVariables.WARCRAFT_WINEPREFIX;
              in "${prefix}/drive_c/users/${name}/Documents/Warcraft III";
            };
          };
          xdg = {
            desktopEntries = {
              kill-games = {
                name = "Kill Games";
                type = "Application";
                categories = ["Game"];
                genericName = "Kills all running games";
                icon = "lutris";
                exec = "${warcraft-scripts}/bin/kill-games";
                terminal = false;
              };
              "Battle.net" = {
                name = "Battle.net";
                type = "Application";
                categories = ["Game"];
                genericName = "Blizzard Game Launcher";
                icon = "${self}/assets/Battle.net.png";
                exec = "${warcraft-scripts}/bin/battlenet";
                terminal = false;
              };
              "W3Champions" = {
                name = "W3Champions";
                type = "Application";
                categories = ["Game"];
                genericName = "The Warcraft III Ladder";
                icon = "${self}/assets/W3Champions.png";
                exec = "${warcraft-scripts}/bin/w3champions";
                terminal = false;
              };
              "Warcraft III" = {
                name = "Warcraft III";
                type = "Application";
                categories = ["Game"];
                genericName = "The godfather of RTS";
                icon = "${self}/assets/Warcraft.png";
                exec = "${warcraft-scripts}/bin/battlenet";
                terminal = false;
              };
            };
          };
          wayland = {
            windowManager = {
              hyprland = {
                extraConfig = ''
                  bind = CTRL, W, exec, ${warcraft-scripts}/bin/warcraft-mode-start
                  submap = WARCRAFT
                  bind = ALT, W, exec, ${warcraft-scripts}/bin/warcraft-mode-stop
                  bind = SHIFT, Q, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey Q
                  bind = SHIFT, W, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey W
                  bind = SHIFT, E, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey E
                  bind = SHIFT, R, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey R
                  bind = SHIFT, A, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey A
                  bind = SHIFT, S, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey S
                  bind = SHIFT, D, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey D
                  bind = SHIFT, F, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey F
                  bind = SHIFT, Y, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey Y
                  bind = SHIFT, X, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey X
                  bind = SHIFT, C, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey C
                  bind = SHIFT, V, exec, ${warcraft-scripts}/bin/warcraft-autocast-hotkey V
                  bind = , RETURN, exec, ${warcraft-scripts}/bin/warcraft-chat-open
                  bind = SHIFT, mouse:272, exec, ${warcraft-scripts}/bin/warcraft-edit-unit-control-group
                  bind = , 1, exec, ${warcraft-scripts}/bin/warcraft-write-control-group 1
                  bind = , 2, exec, ${warcraft-scripts}/bin/warcraft-write-control-group 2
                  bind = , 3, exec, ${warcraft-scripts}/bin/warcraft-write-control-group 3
                  bind = , 4, exec, ${warcraft-scripts}/bin/warcraft-write-control-group 4
                  bind = , 5, exec, ${warcraft-scripts}/bin/warcraft-write-control-group 5
                  bind = $mod, 1, exec, ${warcraft-scripts}/bin/warcraft-write-control-group 6
                  bind = $mod, 2, exec, ${warcraft-scripts}/bin/warcraft-write-control-group 7
                  bind = $mod, 3, exec, ${warcraft-scripts}/bin/warcraft-write-control-group 8
                  bind = $mod, 4, exec, ${warcraft-scripts}/bin/warcraft-write-control-group 9
                  bind = $mod, 5, exec, ${warcraft-scripts}/bin/warcraft-write-control-group 0
                  bind = , mouse:276, submap, BTN_EXTRA
                  bind = , mouse:275, submap, BTN_SIDE
                  binde = , XF86AudioRaiseVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
                  binde = , XF86AudioLowerVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
                  submap = BTN_EXTRA
                  bind = , 1, exec, ${warcraft-scripts}/bin/warcraft-create-control-group 1
                  bind = , 2, exec, ${warcraft-scripts}/bin/warcraft-create-control-group 2
                  bind = , 3, exec, ${warcraft-scripts}/bin/warcraft-create-control-group 3
                  bind = , 4, exec, ${warcraft-scripts}/bin/warcraft-create-control-group 4
                  bind = , 5, exec, ${warcraft-scripts}/bin/warcraft-create-control-group 5
                  bind = $mod, 1, exec, ${warcraft-scripts}/bin/warcraft-create-control-group 6
                  bind = $mod, 2, exec, ${warcraft-scripts}/bin/warcraft-create-control-group 7
                  bind = $mod, 3, exec, ${warcraft-scripts}/bin/warcraft-create-control-group 8
                  bind = $mod, 4, exec, ${warcraft-scripts}/bin/warcraft-create-control-group 9
                  bind = $mod, 5, exec, ${warcraft-scripts}/bin/warcraft-create-control-group 0
                  bind = , Tab, exec, ${warcraft-scripts}/bin/warcraft-inventory-hotkey 1
                  bind = , Q, exec, ${warcraft-scripts}/bin/warcraft-inventory-hotkey 2
                  bind = , W, exec, ${warcraft-scripts}/bin/warcraft-inventory-hotkey 3
                  bind = , E, exec, ${warcraft-scripts}/bin/warcraft-inventory-hotkey 4
                  bind = , R, exec, ${warcraft-scripts}/bin/warcraft-inventory-hotkey 5
                  bind = , T, exec, ${warcraft-scripts}/bin/warcraft-inventory-hotkey 6
                  bind = , ESCAPE, exec, ${warcraft-scripts}/bin/warcraft-select-unit 1
                  bind = , A, exec, ${warcraft-scripts}/bin/warcraft-select-unit 2
                  bind = , S, exec, ${warcraft-scripts}/bin/warcraft-select-unit 3
                  bind = , D, exec, ${warcraft-scripts}/bin/warcraft-select-unit 4
                  bind = , F, exec, ${warcraft-scripts}/bin/warcraft-select-unit 5
                  bind = , G, exec, ${warcraft-scripts}/bin/warcraft-select-unit 6
                  bind = , ESCAPE, submap, WARCRAFT
                  bind = , A, submap, WARCRAFT
                  bind = , S, submap, WARCRAFT
                  bind = , D, submap, WARCRAFT
                  bind = , F, submap, WARCRAFT
                  bind = , G, submap, WARCRAFT
                  bind = , catchall, submap, WARCRAFT
                  submap = BTN_SIDE
                  bind = , ESCAPE, exec, ${warcraft-scripts}/bin/warcraft-select-unit 7
                  bind = , A, exec, ${warcraft-scripts}/bin/warcraft-select-unit 8
                  bind = , S, exec, ${warcraft-scripts}/bin/warcraft-select-unit 9
                  bind = , D, exec, ${warcraft-scripts}/bin/warcraft-select-unit 10
                  bind = , F, exec, ${warcraft-scripts}/bin/warcraft-select-unit 11
                  bind = , G, exec, ${warcraft-scripts}/bin/warcraft-select-unit 12
                  bind = , ESCAPE, submap, WARCRAFT
                  bind = , A, submap, WARCRAFT
                  bind = , S, submap, WARCRAFT
                  bind = , D, submap, WARCRAFT
                  bind = , F, submap, WARCRAFT
                  bind = , G, submap, WARCRAFT
                  bind = , catchall, submap, WARCRAFT
                  submap = CHAT
                  bind = , RETURN, exec, ${warcraft-scripts}/bin/warcraft-chat-send
                  bind = , ESCAPE, exec, ${warcraft-scripts}/bin/warcraft-chat-close
                  submap = CONTROLGROUP
                  bind = $mod, Q, submap, WARCRAFT
                  bind = $mod SHIFT, Q, submap, reset
                  submap = reset

                  windowrule = content game,class:(steam_app_default),title:(Battle.net)
                  windowrule = content game,class:(steam_app_default),title:(W3Champions)
                  windowrule = content game,class:(steam_app_default),title:(Warcraft III)
                  windowrule = content game,class:(steam_app_0),title:(Battle.net)
                  windowrule = content game,class:(steam_app_0),title:(W3Champions)
                  windowrule = content game,class:(steam_app_0),title:(Warcraft III)
                  windowrule = content game,class:(battle.net.exe),title:(Battle.net)
                  windowrule = content game,class:(w3champions.exe),title:(W3Champions)
                  windowrule = content game,class:(warcraft iii.exe),title:(Warcraft III)
                  windowrule = workspace 2,class:(steam_app_default),title:(Battle.net)
                  windowrule = workspace 2,class:(steam_app_default),title:(W3Champions)
                  windowrule = workspace 2,class:(steam_app_0),title:(Battle.net)
                  windowrule = workspace 2,class:(steam_app_0),title:(W3Champions)
                  windowrule = workspace 3,class:(steam_app_default),title:(Warcraft III)
                  windowrule = workspace 3,class:(steam_app_0),title:(Warcraft III)
                  windowrule = workspace 2,class:(battle.net.exe),title:(Battle.net)
                  windowrule = workspace 2,class:(w3champions.exe),title:(W3Champions)
                  windowrule = workspace 3,class:(warcraft iii.exe),title:(Warcraft III)
                  windowrule = tile,class:(steam_app_default),title:(Battle.net)
                  windowrule = tile,class:(steam_app_0),title:(Battle.net)
                  windowrule = tile,class:(battle.net.exe),title:(Battle.net)
                  windowrule = fullscreen,class:(steam_app_default),title:(Warcraft III)
                  windowrule = fullscreen,class:(steam_app_0),title:(Warcraft III)
                  windowrule = fullscreen,class:(warcraft iii.exe),title:(Warcraft III)
                  windowrule = size 1600,class:(steam_app_default),title:(W3Champions)
                  windowrule = size 1600,class:(steam_app_0),title:(W3Champions)
                  windowrule = size 1600,class:(w3champions.exe),title:(W3Champions)
                  windowrule = center 1,class:(steam_app_default),title:(W3Champions)
                  windowrule = center 1,class:(steam_app_0),title:(W3Champions)
                  windowrule = center 1,class:(w3champions.exe),title:(W3Champions)
                  windowrule = noinitialfocus,class:(steam_app_default),title:(Warcraft III)
                  windowrule = noinitialfocus,class:(steam_app_0),title:(Warcraft III)
                  windowrule = noinitialfocus,class:(warcraft iii.exe),title:(Warcraft III)
                  windowrule = workspace 1,class:^(com\.obsproject\.Studio)$
                  windowrule = noinitialfocus,class:^(com\.obsproject\.Studio)$
                '';
              };
            };
          };
        };
      };
    };
  };
}

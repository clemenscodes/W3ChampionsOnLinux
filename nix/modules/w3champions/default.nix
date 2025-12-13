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
        allowedTCPPorts = [3550 3551 3552];
        allowedUDPPorts = [3552 5353];
        extraInputRules = ''
          ip daddr 224.0.0.251 udp dport 5353 accept
        '';
      };
    };
    environment = {
      systemPackages = [
        warcraft-scripts
        warcraft-install-scripts
      ];
    };
    programs = {
      ydotool = {
        enable = lib.mkForce true;
      };
    };
    users = {
      users = {
        "${config.modules.users.name}" = {
          extraGroups = [config.programs.ydotool.group];
        };
      };
    };
    home-manager = {
      users = {
        ${name} = {
          home = {
            sessionVariables = {
              W3C_AUTH_DATA = "$HOME/Documents/com.w3champions.client";
              WARCRAFT_PATH = "$HOME/Public/Warcraft III";
              WARCRAFT_WINEPREFIX = "$HOME/${cfg.prefix}";
              WARCRAFT_HOME = let
                prefix = config.home-manager.users.${name}.home.sessionVariables.WARCRAFT_WINEPREFIX;
              in "${prefix}/drive_c/users/${name}/Documents/Warcraft III";
            };
          };
          xdg = {
            desktopEntries = {
              "Battle.net" = {
                name = "Battle.net";
                type = "Application";
                categories = ["Game"];
                genericName = "Blizzard Game Launcher";
                icon = "${self}/assets/Battle.net.png";
                exec = "${warcraft-install-scripts}/bin/battlenet";
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
                exec = "${warcraft-install-scripts}/bin/warcraft";
                terminal = false;
              };
            };
          };
          wayland = {
            windowManager = {
              hyprland = {
                extraConfig = ''
                  bind   = CTRL        , W         , exec, ${warcraft-scripts}/bin/warcraft-mode-start

                  submap = WARCRAFT
                  bind   = ALT         , W         , exec, ${warcraft-scripts}/bin/warcraft-mode-stop
                  bind   = SHIFT       , mouse:276 , exec, ${warcraft-scripts}/bin/warcraft-set-selection-control-group
                  bind   = SHIFT       , mouse:275 , exec, ${warcraft-scripts}/bin/warcraft-back-to-base
                  bind   =             , 1         , exec, ${warcraft-scripts}/bin/warcraft-write-control-group 1
                  bind   =             , 2         , exec, ${warcraft-scripts}/bin/warcraft-write-control-group 2
                  bind   =             , 3         , exec, ${warcraft-scripts}/bin/warcraft-write-control-group 3
                  bind   =             , 4         , exec, ${warcraft-scripts}/bin/warcraft-write-control-group 4
                  bind   =             , 5         , exec, ${warcraft-scripts}/bin/warcraft-write-control-group 5
                  bind   = $mod        , 1         , exec, ${warcraft-scripts}/bin/warcraft-write-control-group 6
                  bind   = $mod        , 2         , exec, ${warcraft-scripts}/bin/warcraft-write-control-group 7
                  bind   = $mod        , 3         , exec, ${warcraft-scripts}/bin/warcraft-write-control-group 8
                  bind   = $mod        , 4         , exec, ${warcraft-scripts}/bin/warcraft-write-control-group 9
                  bind   = $mod        , 5         , exec, ${warcraft-scripts}/bin/warcraft-write-control-group 0
                  bind   = $mod        , Q         , exec, ${warcraft-scripts}/bin/warcraft-select-first-hero
                  bind   = $mod        , A         , exec, ${warcraft-scripts}/bin/warcraft-select-second-hero
                  bind   = $mod        , Y         , exec, ${warcraft-scripts}/bin/warcraft-select-third-hero
                  bind   = $mod        , W         , exec, ${warcraft-scripts}/bin/warcraft-select-first-item
                  bind   = $mod        , E         , exec, ${warcraft-scripts}/bin/warcraft-select-second-item
                  bind   = $mod        , S         , exec, ${warcraft-scripts}/bin/warcraft-select-third-item
                  bind   = $mod        , D         , exec, ${warcraft-scripts}/bin/warcraft-select-fourth-item
                  bind   = $mod        , X         , exec, ${warcraft-scripts}/bin/warcraft-select-fifth-item
                  bind   = $mod        , C         , exec, ${warcraft-scripts}/bin/warcraft-select-sixth-item
                  bind   =             , RETURN    , exec, ${warcraft-scripts}/bin/warcraft-chat-open
                  bind   =             , SPACE     , submap, SELECT

                  submap = SELECT
                  bind   =             , Q         , exec, ${warcraft-scripts}/bin/warcraft-select-unit 1
                  bind   =             , W         , exec, ${warcraft-scripts}/bin/warcraft-select-unit 2
                  bind   =             , E         , exec, ${warcraft-scripts}/bin/warcraft-select-unit 3
                  bind   =             , R         , exec, ${warcraft-scripts}/bin/warcraft-select-unit 4
                  bind   =             , T         , exec, ${warcraft-scripts}/bin/warcraft-select-unit 5
                  bind   =             , mouse:276 , exec, ${warcraft-scripts}/bin/warcraft-select-unit 6
                  bind   =             , A         , exec, ${warcraft-scripts}/bin/warcraft-select-unit 7
                  bind   =             , S         , exec, ${warcraft-scripts}/bin/warcraft-select-unit 8
                  bind   =             , D         , exec, ${warcraft-scripts}/bin/warcraft-select-unit 9
                  bind   =             , F         , exec, ${warcraft-scripts}/bin/warcraft-select-unit 10
                  bind   =             , G         , exec, ${warcraft-scripts}/bin/warcraft-select-unit 11
                  bind   =             , mouse:275 , exec, ${warcraft-scripts}/bin/warcraft-select-unit 12
                  bind   =             , Q         , submap, WARCRAFT
                  bind   =             , W         , submap, WARCRAFT
                  bind   =             , E         , submap, WARCRAFT
                  bind   =             , R         , submap, WARCRAFT
                  bind   =             , T         , submap, WARCRAFT
                  bind   =             , mouse:276 , submap, WARCRAFT
                  bind   =             , A         , submap, WARCRAFT
                  bind   =             , S         , submap, WARCRAFT
                  bind   =             , D         , submap, WARCRAFT
                  bind   =             , F         , submap, WARCRAFT
                  bind   =             , G         , submap, WARCRAFT
                  bind   =             , mouse:275 , submap, WARCRAFT
                  bind   = SHIFT       , Q         , exec, ${warcraft-scripts}/bin/warcraft-autocast Q
                  bind   = SHIFT       , W         , exec, ${warcraft-scripts}/bin/warcraft-autocast W
                  bind   = SHIFT       , E         , exec, ${warcraft-scripts}/bin/warcraft-autocast E
                  bind   = SHIFT       , R         , exec, ${warcraft-scripts}/bin/warcraft-autocast R
                  bind   = SHIFT       , A         , exec, ${warcraft-scripts}/bin/warcraft-autocast A
                  bind   = SHIFT       , S         , exec, ${warcraft-scripts}/bin/warcraft-autocast S
                  bind   = SHIFT       , D         , exec, ${warcraft-scripts}/bin/warcraft-autocast D
                  bind   = SHIFT       , F         , exec, ${warcraft-scripts}/bin/warcraft-autocast F
                  bind   = SHIFT       , Y         , exec, ${warcraft-scripts}/bin/warcraft-autocast Y
                  bind   = SHIFT       , X         , exec, ${warcraft-scripts}/bin/warcraft-autocast X
                  bind   = SHIFT       , C         , exec, ${warcraft-scripts}/bin/warcraft-autocast C
                  bind   = SHIFT       , V         , exec, ${warcraft-scripts}/bin/warcraft-autocast V
                  bind   = SHIFT       , Q         , submap, WARCRAFT
                  bind   = SHIFT       , W         , submap, WARCRAFT
                  bind   = SHIFT       , E         , submap, WARCRAFT
                  bind   = SHIFT       , R         , submap, WARCRAFT
                  bind   = SHIFT       , A         , submap, WARCRAFT
                  bind   = SHIFT       , S         , submap, WARCRAFT
                  bind   = SHIFT       , D         , submap, WARCRAFT
                  bind   = SHIFT       , F         , submap, WARCRAFT
                  bind   = SHIFT       , Y         , submap, WARCRAFT
                  bind   = SHIFT       , X         , submap, WARCRAFT
                  bind   = SHIFT       , C         , submap, WARCRAFT
                  bind   = SHIFT       , V         , submap, WARCRAFT
                  bind   =             , catchall  , submap, WARCRAFT

                  submap = CHAT
                  bind   =             , RETURN    , exec, ${warcraft-scripts}/bin/warcraft-chat-send
                  bind   =             , ESCAPE    , exec, ${warcraft-scripts}/bin/warcraft-chat-close

                  submap = reset

                  windowrule = content game,                         class:(battle.net.exe),   title:(Battle.net)
                  windowrule = tile,                                 class:(battle.net.exe),   title:(Battle.net)

                  windowrule = content game,                         class:(warcraft iii.exe), title:(Warcraft III)
                  windowrule = workspace 3,                          class:(warcraft iii.exe), title:(Warcraft III)
                  windowrule = fullscreen,                           class:(warcraft iii.exe), title:(Warcraft III)
                  windowrule = noinitialfocus,                       class:(warcraft iii.exe), title:(Warcraft III)

                  windowrule = content game,                         class:(w3champions.exe),  title:(W3Champions)
                  windowrule = workspace 2,                          class:(w3champions.exe),  title:(W3Champions)
                  windowrule = center 1,                             class:(w3champions.exe),  title:(W3Champions)
                  windowrule = float,                                class:(w3champions.exe),  title:(W3Champions)
                  windowrule = size (monitor_w*0.8) (monitor_h*0.8), class:(w3champions.exe),  title:(W3Champions)
                '';
              };
            };
          };
        };
      };
    };
  };
}

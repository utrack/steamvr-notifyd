# Desktop notifications (KDE Connect, Firefox, Xpra's from hal2, ...) as clickable panels in
# VR: vr-notifyd serves org.freedesktop.Notifications on the user bus and shows each
# notification as a SteamVR overlay, fixed in the room below and right of where you looked
# when it came in. The laser clicks its buttons (the app gets ActionInvoked), the body (the
# app's default action) or its X. A toast stays while the laser is on it.
#
# It replaces SteamOS's steam_notif_daemon (steam-notif-daemon.service, masked here), which
# hands each notification to Steam with `~/.steam/root/ubuntu12_32/steam steam://...`: an
# x86 program that can't run on the Frame, and a URL this Steam client ignores, so nothing
# showed at all.
#
# Without SteamVR running, notifications wait (up to 50) and show once it starts; vr-notifyd
# never starts SteamVR itself. Apps in the nested desktop have their own D-Bus and Plasma's
# notifications, so this doesn't see theirs.
#
# Placement and size: see `vr-notifyd --help`, set with `services.steamvr-notifyd.args`.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.steamvr-notifyd;
  fonts = pkgs.makeFontsConf { fontDirectories = cfg.fontDirectories; };
in {
  options.services.steamvr-notifyd = {
    enable = lib.mkEnableOption "desktop notifications as clickable SteamVR overlays";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The vr-notifyd package.";
    };
    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--width" "0.3" "--right" "12" "--down" "18" ];
      description = "Extra arguments for vr-notifyd (placement and size, see `vr-notifyd --help`).";
    };
    fontDirectories = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.path lib.types.str);
      # SteamOS's fonts (Noto, with color emoji), DejaVu if there are none
      default = [ "/usr/share/fonts" pkgs.dejavu_fonts ];
      defaultText = lib.literalExpression ''[ "/usr/share/fonts" pkgs.dejavu_fonts ]'';
      description = "Font directories vr-notifyd's fontconfig searches.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.vr-notifyd = {
      Unit = {
        Description = "Desktop notifications in VR";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        # takes over its bus name in a running session; masked below for the next ones
        Conflicts = [ "steam-notif-daemon.service" ];
      };
      Service = {
        Environment = [ "FONTCONFIG_FILE=${fonts}" ];
        ExecStart = lib.escapeShellArgs ([ (lib.getExe cfg.package) ] ++ cfg.args);
        Restart = "on-failure";
        RestartSec = 3;
        Slice = "session.slice";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xdg.configFile."systemd/user/steam-notif-daemon.service".source =
      config.lib.file.mkOutOfStoreSymlink "/dev/null";
  };
}

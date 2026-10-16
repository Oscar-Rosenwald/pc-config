# This file describes the home-manager configuration.
# It is called by a util function which passes to it all the
# arguments. The util function is called by the nixos configuration flake,
# which calls the util function repeatedly, once for every hostname defined
# in the config flake (i.e., my config repository) under the hardware
# attribute.
#
# - specialArgs:
#     - configFiles: Files which are guaranteed to exist in the config repo.
#     - configValues: Values defined by the config repo.
#
# - pkgs: The result of [import nixpkgs {...}]

{
  config, # == self
  specialArgs,
  pkgs,
  ...
}:

let
  # Path to my directory of configurations (in the nix store, because duh).
  configFiles = specialArgs.configFiles;
  configValues = specialArgs.configValues;
  lib = pkgs.lib;
in {
  home.username = "william";
  home.homeDirectory = "/home/william";
  home.stateVersion = "26.05";

  # This comes from carapace's docs. We must produce the init.nu file for
  # nushell so that it can call it with command-line arguments.
  home.file.".cache/nushell/carapace/init.nu".source = pkgs.runCommand "carapace-init" {} ''
    ${pkgs.carapace}/bin/carapace _carapace nushell > $out
  '';

  # Nushell configuration
  programs.nushell = {
    enable = true;

    configFile.text =
      let
        files = configFiles.nushell;
      in ''
        source ${files.loadEnv}
        source ${files.updatePath}

        source ${files.misc}
        source ${files.chdir}
        source ${files.docker}
        source ${files.vms}
        source ${files.external}

        use ${files.git} *
        use ${files.grep} *
        use ${files.testsMod} *
        use ${files.screens} *
        use ${files.resiliency} *
        use ${files.jj} *
        use ${files.ssh} *
        use ${files.kubectl} *

        source ${files.aliases}
      '';

    # This completion config comes from carapace's docs. See above for where
    # init.nu comes from.
    extraConfig = "source ($nu.cache-dir | path join carapace/init.nu)";
    environmentVariables.CARAPACE_BRIDGES = "'zsh,fish,bash,inshellisense'";

    settings = {
      show_banner = false;
      history = {
        file_format = "sqlite";
        isolation = true;
      };
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;

    # TODO Do we need to do this?
    # Configuring right alt to be the compose key. There are a few issues with it,
    # so we need to do it in this weird way. Blame Gemini for this mess.
    profileExtra = ''
      export GTK_IM_MODULE=none
      export QT_IM_MODULE=xim
      export XMODIFIERS="@im=none"
    '';

    shellAliases = {
      "ls" = "ls --color=auto -G";
      "ll" = "ls -alFvG";
      "la" = "ls -Av";
      "l"  = "ls -CFv";
      "l1" = "ls -1vt";
      "lt" = "ls -1vt";
      "mv" = "mv -i";
      "beep" = "paplay -n synth 0.2 sine 1000 vol 0.2";
      "fireb" = "firefox -p blabla 2>/dev/null &";
      "phones" = "bluetooth connect 2C:27:9E:71:45:69";
    };
  };

  home.file.".config/jj/config.toml" = {
    enable = true;
    source = configFiles.jujutsu;
  };

  programs.vim = {
    enable = true;
    settings = {
      tabstop = 4;
      shiftwidth = 4;
      expandtab = true;
    };
  };

  programs.ssh = {
    enable = true;

    settings = {
      # Credentials for my personal GitHub account.
      "oscar.github.com" = {
        HostName = "github.com";
        IdentityFile = configValues.ssh.workIdentity;
        ForwardAgent = "yes";
      };

      # Credentials for my work GitHub account.
      "tom.github.com" = {
        HostName = "github.com";
        PreferredAuthentications = "publickkey";
        IdentityFile = configValues.ssh.defaultIdentity;
      };

      # Default credentials.
      "*" = {
        IgnoreUnknown = "UseKeychain";
        AddKeysToAgent = "yes";
        IdentityFile = configValues.ssh.defaultIdentity;
        StrictHostKeyChecking = "no";
      };
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        email = "cyril.saroch@motorolasolutions.com";
        name = [ "cyril.saroch" "Cyril" ];
      };
      url."git@repo.jazznetworks.com:".insteadOf = "https://repo.jazznetworks.com/";
      core.editor = "emacsclient --create-frame";
      # TODO git/contrib won't be in this path.
      # credential.helper = /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret;
      pull.rebase = false;
      push.recurseSubmodules = false;
      submodule.recurse = true;
      init.defaultBranch = "master";
    };
  };

  home.file.".sqliterc".text = ''
    .m box
  '';

  home.file.".config/dunst/".source = configFiles.dunst;

  home.file.".config/terminator".source = configFiles.terminator;

  wayland.windowManager.sway = {
    enable = true;
    config =
      let
        modifier = "Mod4";
        terminal = "${pkgs.terminator}/bin/terminator";
        fuzzel = "${pkgs.fuzzel}/bin/fuzzel";
      in {
        inherit modifier;
        focus.followMouse = true;

        keybindings =  lib.attrsets.mergeAttrsList [
          # Workspace navigation
          (lib.attrsets.mergeAttrsList
            (map
              (num: let ws = toString num; in {
                "${modifier}+${ws}" = "workspace ${ws}";
                "${modifier}+Shift+${ws}" = "move container to workspace ${ws}";
              })
              [ 1 2 3 4 5 6 7 8 9 ]
            )
          )

          # Window navigation / movement
          (lib.attrsets.concatMapAttrs
            (direction: key: {
              "${modifier}+${key}" = "focus ${direction}";
              "${modifier}+Shift+${key}" = "move ${direction}";
              "${modifier}+Ctrl+Shift+${key}" = "move workspace to output ${direction}";
            })
            {
              up = "k";
              down = "l";
              left = "j";
              right = "apostrophe";
            }
          )
          # Using arrows
          (lib.attrsets.mergeAttrsList
            (map
              (direction: {
                "${modifier}+${direction}" = "focus ${direction}";
                "${modifier}+Shift+${direction}" = "move ${direction}";
                "${modifier}+Ctrl+Shift+${direction}" = "move workspace to output ${direction}";
              })
              [ "up" "down" "left" "right" ]
            )
          )

          # Generic window manipulation
          {
            "${modifier}+Return" = "exec --no-startup-id foot";
            "${modifier}+y" = "kill";
            "${modifier}+f" = "fullscreen toggle";
            "${modifier}+Alt+f" = "floating toggle";
            "${modifier}+Shift+f" = "focus mode_toggle";
            "${modifier}+s" = "sticky toggle";
          }

          # Window layout
          {
            "${modifier}+h" = "split h";
            "${modifier}+v" = "split v";
            "${modifier}+i" = "layout stacking";
            "${modifier}+o" = "layout tabbed";
            "${modifier}+p" = "layout toggle split";
          }

          # Scratchpad
          {
            "${modifier}+Shift+minus" = "move scratchpad";
            "${modifier}+minus" = "scratchpad show";
          }

          # Sway session management
          {
            "${modifier}+Shift+c" = "reload";
            "${modifier}+Shift+r" = "restart";
            "${modifier}+semicolon" = "menu";
            "${modifier}+Shift+e" = "swaymsg exit";
            "${modifier}+n" = "exec ${fuzzel}";
          }
        
          # Misc
          {
            "Print" = "exec --no-startup-id flameshot gui";
          }
        ];

        # TODO:
        # - mod+x
        # - mod+z
        # - mod+Shift+x
        # - resizing
        # - status bar setup
        # - keyboard layouts (example):
        #     input type:keyboard {
        #       xkb_layout us,latam
        #     }
        #     bindsym $mod+0 input type:keyboard xkb_switch_layout next
        # - window/border colours
      };
  };
}

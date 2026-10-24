# Shell stack: fish, zsh, starship, and the CLI tools from
# manifests/packages/shell.
#
# Replaces link_dotfiles() in 1-install-shell.sh (the stow calls for zshrc, fish,
# starship, thefuck) and the per-distro package install in install_with_yay() /
# install_on_ubuntu().
#
# The design rule applied throughout: where home-manager has a native module for
# a tool, use the module and let Nix generate the integration; where the config
# is a large hand-maintained file in a format Nix cannot round-trip, deploy the
# file verbatim as a store path. Neither is a workaround — `xdg.configFile` with
# a `source` is a first-class home-manager feature.

{
  config,
  lib,
  pkgs,
  jbRoles,
  jbHomelab,
  ...
}:

let
  root = ../../..;

  # Read a directory out of the flake at evaluation time. This is pure (no
  # import-from-derivation) because the path is inside the flake, and it means
  # new files are picked up automatically — the same property the stow packages
  # had, without a script enumerating them.
  dirOf = rel: builtins.readDir (root + "/${rel}");
  isFishFile = n: builtins.match ".*\\.fish" n != null;

  # fish/.config/fish/functions/*.fish — excluding the tracked
  # quick-share.fish.bak, which stow deployed alongside the real file.
  fishFunctions = lib.filterAttrs (n: _: isFishFile n) (dirOf "fish/.config/fish/functions");
  fishCompletions = lib.filterAttrs (n: _: isFishFile n) (dirOf "fish/.config/fish/completions");

  shellEnabled = jbRoles.shell;
in
{
  config = lib.mkIf shellEnabled {
    # -------------------------------------------------------------------------
    # Environment variables
    # -------------------------------------------------------------------------
    # Was: `set -gx` block in fish/.config/fish/config.fish and the matching
    # `export` block in zshrc/.zshrc — the same five variables maintained in two
    # files that could silently disagree. Declared once here, they reach fish,
    # zsh, systemd user units and ssh sessions alike.
    home.sessionVariables = {
      FZF_DEFAULT_OPTS = "--height 60% --layout reverse --border top";
      EDITOR = "micro";
      VISUAL = "micro";
      PAGER = "bat --style=header,grid";
      MANPAGER = "bat --language=man --style=header,grid";
      BAT_STYLE = "header,grid";
    };

    # Was: the `fish_add_path` calls at the bottom of config.fish, plus
    # `fish_add_path -gm /home/joe/go/bin` — and, separately,
    # configure_npm_user_prefix() in 1-install-shell.sh which set npm's prefix to
    # ~/.local. home.sessionPath is shell-agnostic, so zsh gets the same PATH
    # without a second edit.
    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.filen-cli/bin"
      "$HOME/.npm-global/bin"
      "$HOME/go/bin"
    ];

    # Was: `mkdir -p "$HOME/Pictures/Screenshots"` in 3-install-dots.sh.
    # tmpfiles is the declarative form: it re-creates the directory if something
    # deletes it, and it does not need an activation-time shell command.
    systemd.user.tmpfiles.rules = [ "d %h/Pictures/Screenshots 0755 - - -" ];

    # -------------------------------------------------------------------------
    # fish
    # -------------------------------------------------------------------------
    programs.fish = {
      enable = true;

      # The parts of config.fish that are genuinely shell-init rather than
      # environment. Everything else from that file moved to sessionVariables,
      # sessionPath, shellAliases, or a native module below.
      shellInit = ''
        # History ###################################################################
        # Fish handles dedup and sharing natively; this mirrors SAVEHIST=1000 from
        # zshrc/.zshrc.
        set -g fish_history_max_commands 1000
        set -g fish_greeting

        # Key bindings ##############################################################
        # Fish uses `bind`, not zsh's `bindkey`. Autosuggestions are built in, so
        # no plugin is needed here (contrast with programs.zsh below).
        bind \e\[F end-of-line           # End
        bind \e\[H beginning-of-line     # Home
        bind \e\[3~ delete-char          # Delete
        bind \t  complete                # Tab
        bind \e\[Z accept-autosuggestion # Shift+Tab

        # Ghostty terminfo guard ####################################################
        # Kept from config.fish. On NixOS ghostty's terminfo lives in the store and
        # is registered for local sessions, but an `ssh` hop to a non-NixOS host
        # still lands on a machine that has never heard of xterm-ghostty. Falling
        # back to xterm-256color in that case is correct, not a workaround.
        if test "$TERM" = xterm-ghostty
            if not infocmp xterm-ghostty >/dev/null 2>&1
                set -gx TERM xterm-256color
            end
        end
      '';

      # Was: the `alias` lines in config.fish.
      shellAliases = {
        serve = "python -m http.server";
        hermes-tui = "ssh -t hermes.home 'hermes --tui'";
        # `ls` was a function override in config.fish (see functions below); the
        # tree alias is a plain alias and belongs here.
        tree = "eza --tree --icons";
      };

      # The `ping` and `ls` overrides in config.fish were defined as functions
      # *after* sourcing /etc/grc.fish so they would win. That ordering
      # dependency is fragile and unnecessary: declaring them here puts them in
      # fish's function autoloader, which always takes precedence over anything a
      # sourced init file defines.
      functions = {
        ls = ''
          eza --icons=always --group-directories-first --mounts $argv
        '';
        ping = ''
          if isatty 1; and command -q grc
              grc ping -c 5 $argv
          else
              command ping -c 5 $argv
          end
        '';
      };
    };

    # fish/.config/fish/functions/*.fish — one function per file, which is
    # exactly fish's autoload convention. Deployed as-is so the fish files stay
    # fish files instead of being re-embedded as Nix strings.
    xdg.configFile =
      (lib.mapAttrs' (
        n: _:
        lib.nameValuePair "fish/functions/${n}" {
          source = root + "/fish/.config/fish/functions/${n}";
        }
      ) fishFunctions)
      // (lib.mapAttrs' (
        n: _:
        lib.nameValuePair "fish/completions/${n}" {
          source = root + "/fish/.config/fish/completions/${n}";
        }
      ) fishCompletions)
      // {
        # fish/.config/grc/conf.lsof — a grc colour rule, shipped next to the fish
        # config in the old stow package.
        "grc/conf.lsof".source = root + "/fish/.config/grc/conf.lsof";
      };

    # -------------------------------------------------------------------------
    # zsh
    # -------------------------------------------------------------------------
    # The Arch shell manifest installed zsh-autosuggestions and
    # zsh-syntax-highlighting as *packages*, relying on Arch's /etc/zsh/zshrc to
    # source them. Nothing in the repo declared that dependency; on a distro
    # without that hook the plugins silently did nothing. home-manager wires them
    # explicitly, and zshrc/.zshrc's `bindkey '^[[Z' autosuggest-accept` now has
    # a guaranteed plugin behind it.
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      # zshrc/.zshrc is a hand-maintained file (history options, keybinds,
      # functions). programs.zsh owns ~/.zshrc, so the tracked file is injected
      # as its init content rather than deployed as a second, colliding
      # ~/.zshrc. It sets HISTFILE/HISTSIZE/SAVEHIST and the share_history
      # family itself, so no `history` options are repeated here.
      initContent = lib.mkMerge [
        (builtins.readFile (root + "/zshrc/.zshrc"))
        (lib.mkAfter ''
          if [[ -r ${pkgs.grc}/etc/grc.zsh ]]; then
            source ${pkgs.grc}/etc/grc.zsh
          fi
          if command -v pay-respects >/dev/null 2>&1; then
            eval "$(${pkgs.pay-respects}/bin/pay-respects zsh --alias)"
          fi
        '')
      ];
    };

    # -------------------------------------------------------------------------
    # starship
    # -------------------------------------------------------------------------
    # starship/.config/starship.toml is 624 lines and carries a dozen named
    # palettes plus their comments. Rewriting it as a Nix attrset would lose the
    # comments and make the file far harder to read, so it is parsed at eval time
    # and handed to home-manager's TOML generator. The tracked file stays the
    # single source of truth; the deployed config is derived from it.
    programs.starship = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile (root + "/starship/.config/starship.toml"));
    };

    # starship/.config/update-noctalia-starship.py is NOT ported, deliberately.
    #
    # It read ~/.config/noctalia/colors.json and wrote ~/dotfiles/starship/
    # .config/starship.toml — i.e. it mutated the checkout in place. Under Nix
    # the checkout is a read-only store path, so that design cannot work at all.
    # It was already dead code: config.fish had the invocation commented out, and
    # starship.toml selects `palette = 'catppuccin_macchiato'`, not noctalia.
    #
    # Starship has no config-include mechanism, so a runtime-generated palette
    # cannot be layered in either. The static palettes in starship.toml are the
    # correct end state. See docs/MIGRATION.md §Starship.

    # -------------------------------------------------------------------------
    # CLI tools — manifests/packages/shell
    # -------------------------------------------------------------------------
    # Tools with a native home-manager module use it, which generates the shell
    # integration instead of hand-writing an `eval "$(... init ...)"` line.
    programs = {
      # Was: `fzf --fish | source`, with a fallback to
      # /usr/share/doc/fzf/examples/key-bindings.fish for Ubuntu's older package.
      # Both branches existed purely because package versions differed between
      # distros; with a pinned nixpkgs there is one fzf and one integration.
      fzf.enable = true;

      # Was: `zoxide init fish --cmd cd | source`. The --cmd cd flag is what made
      # `cd` jump to frecency matches; it is an option here, not shell text.
      zoxide = {
        enable = true;
        options = [
          "--cmd"
          "cd"
        ];
      };

      eza = {
        enable = true;
        # The repo's `ls` override uses --icons --group-directories-first
        # --mounts; enabling them here keeps bare `eza` consistent with it.
        icons = "auto";
        git = true;
      };

      bat.enable = true;
      btop.enable = true;
    };

    home.packages =
      with pkgs;
      [
        fd
        ripgrep
        grc
        micro
        yazi
        fastfetch
        sysz
        isd
        herdr

        # thefuck was REMOVED from nixpkgs: upstream is unmaintained and breaks on
        # Python 3.12+. pay-respects is the maintained successor and provides the
        # same `fuck` alias. This is the one package in the old shell manifest that
        # cannot be ported as-is.
        pay-respects

        # `stow` is intentionally absent. It existed to symlink the checkout into
        # $HOME; that whole mechanism is what home-manager replaces. Keeping it
        # installed would invite two systems managing the same paths.
      ]
      ++ lib.optionals jbHomelab [
        # Homelab Forgejo TUI. Gated on jb.homelab.enable because building it
        # requires reachability of forgejo.home — see nix/overlay.nix.
        pkgs.jbattist.gaze
      ];

    # Shell integration for the two tools that have no home-manager module.
    #
    # grc: config.fish sourced /etc/grc.fish, a path that exists on Arch because
    # the package installs into /etc. Nix packages have no /etc, so the file is
    # referenced through the store path instead. This is the same content, just
    # addressed the way Nix addresses things.
    #
    # pay-respects: replaces `thefuck --alias | source`. Its CLI is
    # `pay-respects <shell> [--alias]`, so the shell name is a positional
    # argument rather than a separate output binary.
    programs.fish.interactiveShellInit = lib.mkAfter ''
      if test -r ${pkgs.grc}/etc/grc.fish
          source ${pkgs.grc}/etc/grc.fish
      end

      if command -q pay-respects
          ${pkgs.pay-respects}/bin/pay-respects fish --alias | source
      end
    '';
  };
}

# Editors: neovim and micro.
#
# Replaces the `nvim` and `micro` stow packages from link_dotfiles() in
# 1-install-shell.sh, including micro's `.stow-local-ignore` (which existed to
# stop stow from adopting the `buffers`, `backups` and `plugins` directories that
# micro writes at runtime).

{
  config,
  lib,
  pkgs,
  jbRoles,
  ...
}:

let
  root = ../../..;
  microSchemes = lib.filterAttrs (n: _: builtins.match ".*\\.micro" n != null) (
    builtins.readDir (root + "/micro/.config/micro/colorschemes")
  );
in
{
  config = lib.mkIf jbRoles.shell {
    # -------------------------------------------------------------------------
    # neovim
    # -------------------------------------------------------------------------
    # nvim/.config/nvim is a lazy.nvim configuration: init.lua bootstraps
    # lazy.nvim by cloning it into ~/.local/share/nvim/lazy, then loads
    # lua/config/* and lua/plugins/*.
    #
    # The config directory is deployed read-only. That is correct for Nix —
    # config is code — and lazy.nvim's *plugin* state still lives in the mutable
    # ~/.local/share/nvim, so installing and updating plugins keeps working.
    #
    # Two consequences worth knowing:
    #
    #   * lazy-lock.json is gitignored ("each machine resolves its own
    #     versions"). On NixOS it cannot be rewritten in place, because
    #     ~/.config/nvim is a store symlink. `:Lazy update` still updates
    #     plugins; it just cannot persist the lock.
    #
    #   * The fully declarative end state is to express the 17 plugin specs as
    #     `programs.neovim.plugins = [ pkgs.vimPlugins.… ]`, which pins plugins
    #     in flake.lock and removes the runtime git clone. That is a mechanical
    #     but sizeable rewrite, so it is listed as a follow-up in
    #     docs/MIGRATION.md rather than done silently here.
    #
    # `programs.neovim` is deliberately NOT enabled: that module generates its
    # own init.lua from `extraConfig`/`plugins`, which would collide with the
    # tracked init.lua below. Adding the package directly avoids two systems
    # claiming the same path.
    home.packages = with pkgs; [
      neovim
      micro
      # lazy.nvim clones plugin repositories at first start.
      git
    ];

    xdg.configFile = {
      nvim = {
        source = root + "/nvim/.config/nvim";
        # `recursive = true` is required for directories: without it,
        # ~/.config/nvim becomes a single symlink to the store directory and
        # nothing inside can be overridden or added to.
        recursive = true;
      };

      # micro: individual files rather than the whole directory. This
      # reproduces micro/.stow-local-ignore exactly — `buffers`, `backups` and
      # `plugins` are micro's runtime state and must stay writable, which a
      # directory symlink into the read-only store would prevent.
      "micro/settings.json".source = root + "/micro/.config/micro/settings.json";
      "micro/bindings.json".source = root + "/micro/.config/micro/bindings.json";
    }
    # Colorschemes are enumerated rather than globbed so the deployment is
    # visible in `nix eval`, and a new scheme cannot enter the repo without
    # appearing in the flake's file list.
    // (lib.mapAttrs' (
      n: _:
      lib.nameValuePair "micro/colorschemes/${n}" {
        source = root + "/micro/.config/micro/colorschemes/${n}";
      }
    ) microSchemes);
  };
}

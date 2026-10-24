# Replaces 4-git-config.sh entirely.
#
# The script ran eight `git config --global` commands and ended with
# `git config --global --list --show-origin`. Two things about it are worth
# noting now that it is declarative:
#
#   * It was not idempotent-by-construction — it was idempotent by luck, because
#     `git config --global k v` overwrites. It also contained a duplicated
#     push.autoSetupRemote / push.default block (lines 20-23 and 25-28), which
#     is invisible in a script and impossible here.
#   * It wrote to ~/.gitconfig, a real file that any other tool could silently
#     edit. Under home-manager it is a generated store path; local drift becomes
#     a visible `nixos-rebuild` diff instead of a mystery.
#
# The script's header said "inspect before running" because it embeds personal
# identity. That identity is now in one obvious place, below.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.git = {
    enable = true;

    # Every line of 4-git-config.sh, as data (home-manager `settings` maps
    # one-to-one onto `git config --global <section>.<key>`).
    settings = {
      user = {
        name = "Joe Battistello";
        email = "17577908+jbattist@users.noreply.github.com";
      };

      # New repositories
      init.defaultBranch = "main";

      # Multi-machine synchronization
      pull.rebase = true;
      rebase.autoStash = true;
      fetch.prune = true;

      # Make first push of a new branch set its upstream automatically
      push.autoSetupRemote = true;
      push.default = "simple";
    };

    # `git config --global --list --show-origin` was the script's final step,
    # used to eyeball the result. The declarative equivalent:
    #   nix eval .#nixosConfigurations.<host>.config.home-manager.users.joe.programs.git.settings
    # or just read the generated file:
    #   cat ~/.config/git/config
  };
}

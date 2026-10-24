# Passes the role/desktop options declared on the NixOS side down into the
# home-manager evaluation.
#
# home-manager modules run in a *separate* module system instance, so they cannot
# read `config.jb.…` directly. Rather than duplicating every option declaration
# or gating packages twice (once in `environment.systemPackages`, once in
# `home.packages`), the subtrees the home modules actually need are handed
# over as module arguments.
#
# These are read lazily and none of them depend on home-manager's own output, so
# there is no evaluation cycle.

{ config, lib, ... }:

{
  home-manager.sharedModules = [
    (
      { ... }:
      {
        _module.args = {
          jbRoles = config.jb.roles;
          jbOpts = config.jb.opts;
          jbDesktop = config.jb.desktop;
          jbHomelab = config.jb.homelab.enable;
        };
      }
    )
  ];
}

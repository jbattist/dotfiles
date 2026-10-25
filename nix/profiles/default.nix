# Generic package/service selection. Profiles only vary desktop layout; this
# common role set is suitable for a typical personal desktop or laptop.
# Disable expensive/optional roles after install if not needed.
{ lib, ... }:
{
  jb.roles = {
    shell = true;
    fonts = true;
    audio = true;
    bluetooth = true;
    printing = true;
    desktop-niri = true;
    # Noctalia's Quickshell fork currently fails against pinned Qt 6.12. Use
    # greetd/tuigreet to start Umbriel directly until upstream is compatible.
    noctalia-greeter = false;
    # Keep the first-boot profile small enough for a 32 GiB test VM. The full
    # application suite (Chrome, Obsidian, VS Code, Zed, Kiro, Claude Code,
    # OpenCode) is enabled by nix/profiles/full.nix.
    interactive = lib.mkDefault false;
    work-apps = lib.mkDefault false;
    gaming = false;
    snapshots = false;
    container = false;
    mango = false;
  };
}

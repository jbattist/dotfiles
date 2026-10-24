# Generic package/service selection. Profiles only vary desktop layout; this
# common role set is suitable for a typical personal desktop or laptop.
# Disable expensive/optional roles after install if not needed.
{
  jb.roles = {
    shell = true;
    fonts = true;
    audio = true;
    bluetooth = true;
    printing = true;
    desktop-niri = true;
    noctalia-greeter = true;
    interactive = true;
    work-apps = false;
    gaming = false;
    snapshots = false;
    container = false;
    mango = false;
  };
}

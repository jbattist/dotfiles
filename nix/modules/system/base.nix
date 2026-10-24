# Fleet baseline. Replaces:
#   manifests/services/common.enable   (sshd.service, systemd-resolved.service)
#   manifests/services/common.disable  (NetworkManager-wait-online.service)
#   configure_systemd_resolved()       in 1-install-shell.sh
#   the /etc/nsswitch.conf sed         in 1-install-shell.sh
#   configure_npm_user_prefix()        in 1-install-shell.sh
#   choose_default_shell()/chsh        in 1-install-shell.sh
#
# The Arch-specific pieces that have no NixOS equivalent are gone rather than
# ported: pacman colours, the multilib stanza, and the yay bootstrap all exist
# only because pacman/AUR are imperative. `nix.gc` below is the closest thing to
# a cache-cleaning concern and it is declarative.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ---------------------------------------------------------------------------
  # Nix itself
  # ---------------------------------------------------------------------------
  nix = {
    settings = {
      # Deduplicate identical store paths. pacman had no equivalent; this is why
      # a NixOS root partition stays small despite keeping generations around.
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "joe"
      ];
    };

    # Replaces the "@pkg" btrfs subvolume + manual `paccache` hygiene: the store
    # is collected on a timer instead of growing without bound.
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # ---------------------------------------------------------------------------
  # Boot
  # ---------------------------------------------------------------------------
  # hermes currently boots via systemd-boot on UEFI (verified with `bootctl`).
  # Hosts override this in hosts/<name>/hardware-configuration.nix if they differ.
  boot.loader = {
    systemd-boot.enable = lib.mkDefault true;
    efi.canTouchEfiVariables = lib.mkDefault true;
  };

  # ---------------------------------------------------------------------------
  # Networking
  # ---------------------------------------------------------------------------
  networking.networkmanager = {
    enable = true;

    # Was: /etc/NetworkManager/conf.d/dns.conf containing `dns=systemd-resolved`,
    # written by configure_systemd_resolved().
    dns = "systemd-resolved";

    # Was: a `nmcli con show --active` loop that set ipv4.dns-search /
    # ipv6.dns-search per connection, skipped link-local IPv6 profiles, and
    # cleared manual ipv4.dns/ipv6.dns. Every line of that loop existed to push
    # one search domain onto every uplink. With resolved owning the search
    # domain globally (below) the loop has nothing left to do.
    #
  };

  # common.disable: NetworkManager-wait-online.service — desktop boot must not
  # block on NetworkManager reporting online.
  systemd.services.NetworkManager-wait-online.enable = false;

  services.resolved = {
    enable = true;

    # Was: [Resolve] Domains=home  in /etc/systemd/resolved.conf.d/dns.conf
    # Was: [Resolve] Domains=home / FallbackDNS= / DNSStubListener=yes in
    # /etc/systemd/resolved.conf.d/dns.conf. FallbackDNS is empty so homelab-only
    # names never leak to hardcoded public resolvers; the stub listener is the
    # NixOS default, and NixOS owns the /etc/resolv.conf symlink that
    # configure_systemd_resolved() created by hand.
    settings.Resolve = {
      Domains = [ "home" ];
      FallbackDNS = [ "" ];
      DNSOverTLS = "opportunistic";
    };
  };

  # Was: `sed -i 's/^hosts:.*/hosts: files dns resolve myhostname mymachines/'`
  # on /etc/nsswitch.conf. NixOS generates nsswitch.conf from the enabled
  # modules; editing it by hand is both unnecessary and reverted on every
  # rebuild.

  # ---------------------------------------------------------------------------
  # SSH — common.enable: sshd.service
  # ---------------------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings = {
      # The fleet relied on key auth and the `hermes.home` / `heimdallama.home`
      # hop pattern in fish functions; password auth is not used.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ---------------------------------------------------------------------------
  # Locale / time
  # ---------------------------------------------------------------------------
  time.timeZone = lib.mkDefault "America/New_York";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # ---------------------------------------------------------------------------
  # User
  # ---------------------------------------------------------------------------
  users.users.joe = {
    isNormalUser = true;
    description = "Joe Battistello";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "input"
    ]
    ++ lib.optionals config.jb.roles.container [ "docker" ];

    # Was: choose_default_shell() prompting 1/2/3 and then `sudo chsh -s`.
    # On NixOS the shell is an attribute; there is no chsh and no prompt, and
    # `DEFAULT_SHELL=skip` is expressed by not setting this.
    shell = pkgs.fish;
  };

  # No password material is committed. `hashedPassword`/`initialHashedPassword`
  # are secrets-adjacent and do not belong in a public flake. On first boot run
  # `sudo passwd joe`, or wire up sops-nix/agenix and set
  # `users.users.joe.hashedPasswordFile` — that is the native follow-up if you
  # want unattended provisioning. See docs/MIGRATION.md §Secrets.

  security.sudo = {
    enable = true;
    wheelNeedsPassword = lib.mkDefault true;
  };

  # ---------------------------------------------------------------------------
  # Environment
  # ---------------------------------------------------------------------------
  environment = {
    sessionVariables = {
      # Was configure_npm_user_prefix(): `npm config set prefix ~/.local`, which
      # mutated ~/.npmrc imperatively and could disagree between machines.
      NPM_CONFIG_PREFIX = "$HOME/.local";

      # Mirrors the exports in fish/.config/fish/config.fish and zshrc/.zshrc so
      # that non-interactive contexts (systemd units, cron, ssh) see them too.
      EDITOR = "micro";
      VISUAL = "micro";
    };

    systemPackages = with pkgs; [
      # manifests/packages/bootstrap: openssh. The daemon comes from
      # services.openssh; the client tools are wanted interactively.
      openssh
      git
      curl
      wget
      which
      file
      gnumake
      # Replaces the `require_cmd` preflight checks scattered through the
      # installers: on NixOS these are present by construction.
    ];
  };

  # `programs.fish` must be enabled for `users.users.joe.shell = pkgs.fish` to be
  # a valid login shell (it has to appear in /etc/shells).
  programs.fish.enable = true;

  system.stateVersion = lib.mkDefault "25.05";
}

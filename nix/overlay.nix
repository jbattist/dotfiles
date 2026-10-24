# Packages that are not available in nixpkgs.
#
# Only two of the ~85 packages in the old manifests/ tree need to live here:
#
#   gaze    — personal Rust TUI published on the homelab Forgejo.
#             The old 1-install-shell.sh curl'd the "latest" release and verified
#             it against a downloaded SHA256SUMS file at install time. Here the
#             version and hash are pinned in the flake, so a build is
#             reproducible and works offline once the store path is cached.
#
#   cursor  — proprietary IDE, not packaged in nixpkgs. Disabled by default;
#             see the note at the bottom of this file.
#
# Everything else that used to come from the AUR (noctalia-shell, umbriel,
# vicinae, herdr, isd, sysz, mango, kiro, google-chrome, vscode, zed, slack,
# opencode, claude-code) is now a first-class nixpkgs package. See
# docs/MIGRATION.md for the full mapping.

{ pkgs, lib }:

{
  # ---------------------------------------------------------------------------
  # gaze — homelab Forgejo release binary
  # ---------------------------------------------------------------------------
  #
  # The release asset is a dynamically linked glibc ELF (NEEDED: libgcc_s, libm,
  # libc). NixOS has no /lib64 loader, so the binary is patched with
  # autoPatchelfHook rather than shipped as-is. That is the standard way to
  # package a prebuilt dynamic binary; no FHS container or chroot is involved.
  #
  # To bump: change `version`, then set `hash = lib.fakeHash;` and run
  # `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
  # Nix reports the real hash in the error; paste it back in.
  gaze = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "gaze";
    version = "0.2.5";

    src = pkgs.fetchurl {
      # Homelab-only host. Builds of this package therefore require access to
      # forgejo.home, which is why it is gated behind `jb.homelab.enable`
      # instead of being installed unconditionally.
      url = "http://forgejo.home/joe/gaze/releases/download/v${finalAttrs.version}/gaze-${finalAttrs.arch}-linux";
      hash = "sha256-B6Bt3FrTpFQlm5R+0VHrcm6IQwOsgCyjjbIMp03LdbE=";
    };

    # Matches upstream's own SHA256SUMS-x86_64 asset, verified during the audit:
    #   07a06ddc5ad3a454259b947ed151eb726e884303ac802ca38db20ca74dcb75b1
    arch = "x86_64";

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.installShellFiles
    ];

    buildInputs = [
      pkgs.glibc
      pkgs.gcc.cc.lib
    ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/gaze"
      runHook postInstall
    '';

    meta = {
      description = "Personal Rust terminal UI hosted on the homelab Forgejo";
      homepage = "http://forgejo.home/joe/gaze";
      sourceProvenance = [ pkgs.lib.sources.binaryNativeCode ];
      license = pkgs.lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "gaze";
    };
  });

  # ---------------------------------------------------------------------------
  # cursor — not packaged, deliberately disabled
  # ---------------------------------------------------------------------------
  #
  # `cursor-bin` was in manifests/packages/interactive. Cursor ships a
  # proprietary .deb/.AppImage from a versioned CDN with no published checksum
  # API, so pinning it means hand-maintaining a URL + hash per release, and it
  # still needs autoPatchelf plus a large Electron dependency closure.
  #
  # That is a maintenance liability, not a config improvement, so it is left
  # out of the default set. Turn it on per host with:
  #
  #   jb.roles.interactive.cursor = true;
  #
  # and fill in the derivation below. `zed-editor` and `vscode` cover the same
  # need from nixpkgs today and are enabled by default.
  cursor = pkgs.stdenv.mkDerivation {
    pname = "cursor";
    version = "0";

    # Set to the current AppImage/deb URL, then populate `hash`:
    #   nix-prefetch-url --unpack --type sha256 <url>
    src = null;

    meta = {
      description = "Cursor IDE (proprietary) — packaging intentionally left as a stub";
      license = pkgs.lib.licenses.unfree;
      broken = true;
      knownVulnerabilities = [ "Not packaged: set src and hash, then clear meta.broken" ];
    };
  };
}

{
  description = "Portable NixOS and home-manager configuration migrated from jbattist/dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/02c087f3fe673c9e317f206a627cb6b910336dbe";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      disko,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";

      overlay = final: prev: {
        jbattist = import ./nix/overlay.nix {
          pkgs = final;
          lib = final.lib;
        };
      };

      profiles = {
        generic = [ ./nix/profiles/home.nix ];
        generic-work = [ ./nix/profiles/work.nix ];
        generic-laptop = [ ./nix/profiles/laptop.nix ];
        generic-full = [ ./nix/profiles/home.nix ./nix/profiles/full.nix ];
      };

      mkSystem =
        name: profileModules:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            ./nix/modules
            ./nix/hardware/generic.nix
            ./nix/profiles/default.nix
            {
              imports = profileModules;
            }
            {
              networking.hostName = name;
              nixpkgs.overlays = [ overlay ];

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-bak";
                extraSpecialArgs = { inherit inputs; };
                users.joe.imports = [ ./nix/modules/home ];
              };
            }
          ];
        };

      systems = lib.mapAttrs mkSystem profiles;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      installApp = pkgs.writeShellApplication {
        name = "install-nixos";
        runtimeInputs = with pkgs; [
          nix
          coreutils
          gnugrep
          util-linux
          nixos-install-tools
        ];
        text = ''
          export DOTFILES_FLAKE=${lib.escapeShellArg (toString self)}
          ${builtins.readFile ./nix/install.sh}
        '';
      };
    in
    {
      overlays.default = overlay;

      packages.${system} =
        (lib.mapAttrs' (name: cfg: lib.nameValuePair "${name}-vm" cfg.config.system.build.vm) systems)
        // {
          install = installApp;
          installer-iso = self.nixosConfigurations.installer.config.system.build.isoImage;
        };

      apps.${system} = {
        default = {
          type = "app";
          program = "${installApp}/bin/install-nixos";
          meta.description = "Install the generic NixOS configuration onto one disk";
        };
        install = {
          type = "app";
          program = "${installApp}/bin/install-nixos";
          meta.description = "Install the generic NixOS configuration onto one disk";
        };
      };

      # Installer ISO using the default generic/home profile. It evaluates the
      # same NixOS + home-manager modules, but imports the standard graphical
      # installer hardware layer instead of applying the disko layout at boot.
      nixosConfigurations = systems // {
        installer = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            home-manager.nixosModules.home-manager
            ./nix/modules
            ./nix/profiles/default.nix
            ./nix/profiles/home.nix
            "${nixpkgs.outPath}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
            {
              networking.hostName = "nixos-installer";
              system.stateVersion = lib.mkForce "26.11";
              environment.systemPackages = [ installApp ];
              nixpkgs.overlays = [ overlay ];
              jb.roles.noctalia-greeter = lib.mkForce false;
              jb.disk.device = lib.mkForce "/dev/null";
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-bak";
                extraSpecialArgs = { inherit inputs; };
                users.joe.imports = [ ./nix/modules/home ];
              };
            }
          ];
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          nixos-rebuild
          nixfmt
          nil
          git
        ];
      };
      formatter.${system} = pkgs.nixfmt;

      # A full desktop closure is intentionally not a cheap CI check. Flake
      # evaluation type-checks every profile; these derivations additionally
      # build the machine files that replaced the old sed/copy installers.
      checks.${system} =
        (lib.mapAttrs' (
          name: cfg:
          let
            files = cfg.config.home-manager.users.joe.xdg.configFile;
            pick = n: files.${n}.source;
          in
          lib.nameValuePair "${name}-generated-config" (
            pkgs.linkFarm "${name}-generated-config" [
              { name = "niri/output.kdl"; path = pick "niri/output.kdl"; }
              { name = "niri/machine.kdl"; path = pick "niri/machine.kdl"; }
              { name = "umbriel/output.toml"; path = pick "umbriel/output.toml"; }
              { name = "umbriel/machine.toml"; path = pick "umbriel/machine.toml"; }
            ]
          )
        ) systems)
        // {
          installer-app = pkgs.runCommand "installer-app-check" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
            shellcheck ${./install-nixos} ${./nix/install.sh}
            grep -q 'nixos-install.*--flake' ${./nix/install.sh} || {
              echo "installer must build directly into the target store" >&2
              exit 1
            }
            ! grep -q 'system_path=.*nix build' ${./nix/install.sh}
            touch $out
          '';
        };
    };
}

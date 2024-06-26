{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, flake-utils, self, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          version = "0.1.0";
          pkgs = nixpkgs.legacyPackages.${system};
          crystal = pkgs.crystal;
          llvmPackages = pkgs.llvmPackages;
          openssl = pkgs.openssl;
          makeWrapper = pkgs.makeWrapper;
          lib = pkgs.lib;
          ketchup-server = self.packages.${system}.ketchup-server;
          ketchup-cli = self.packages.${system}.ketchup-cli;

          buildPackage = { pname, description, src, binaryName }: crystal.buildCrystalPackage {
            inherit pname;
            inherit version;
            src = ./.;

            format = "crystal";
            shardsFile = ./shards.nix;

            nativeBuildInputs = [ pkgs.perl llvmPackages.llvm openssl makeWrapper ];

            doCheck = false;
            doInstallCheck = false;

            crystalBinaries."${binaryName}" = {
              inherit src;
              options = [ "--release" "--no-debug" "--progress" "-Dpreview_mt" ];
            };

            postBuild = ''
              make ${binaryName}.1
            '';

            postInstall = ''
              install -Dm644 ${binaryName}.1 $out/share/man/man1/${binaryName}.1
              wrapProgram "$out/bin/${binaryName}" --prefix PATH : '${
                lib.makeBinPath [ llvmPackages.llvm.dev ]
              }'
            '';

            meta = {
              inherit description;
              homepage = "https://github.com/repomaa/ketchup";
              license = lib.licenses.mit;
              maintainers = [ "Joakim Repomaa <nix@pimeys.pm>" ];
            };
          };
        in
        {
          nixosModules.default = { lib, config, ... }:
            let
              cfg = config.services.ketchup;
              settings = cfg.settings;
            in
            {
              options = {
                services.ketchup = {
                  enable = lib.mkEnableOption "Enable ketchup";
                  settings = {
                    host = lib.mkOption {
                      type = lib.types.str;
                      default = "localhost";
                      description = "Host to serve ketchup server on";
                    };
                    port = lib.mkOption {
                      type = lib.types.nullOr lib.types.int;
                      default = null;
                      description = "Port to serve ketchup server on";
                    };
                    pomodoro_duration = lib.mkOption {
                      type = lib.types.int;
                      default = 25;
                      description = "Duration of a single pomodoro in minutes";
                    };
                    short_break_duration = lib.mkOption {
                      type = lib.types.int;
                      default = 5;
                      description = "Duration of a single short break in minutes";
                    };
                    long_break_duration = lib.mkOption {
                      type = lib.types.int;
                      default = 30;
                      description = "Duration of a single long break in minutes";
                    };
                    cycle = lib.mkOption {
                      type = lib.types.int;
                      default = 4;
                      description = "Amount of finished pomodoros before a long break";
                    };
                  };
                  hooks = {
                    task_started = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Script to run when a task is started";
                    };
                    task_stopped = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Script to run when a task is stopped";
                    };
                    pomodoro_finished = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Script to run when a pomodoro is finished";
                    };
                    pomodoro_interrupted = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Script to run when a pomodoro is interrupted";
                    };
                    break_started = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Script to run when a break is started";
                    };
                    break_finished = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                      description = "Script to run when a break is finished";
                    };
                  };
                };
              };

              config = lib.mkIf cfg.enable
                {
                  xdg.configFile = {
                    "ketchup/config.yml".text = ''
                      ${if isNull settings.port then "" else "host: ${settings.host}"}
                      ${if isNull settings.port then "socket: /tmp/ketchup-${config.home.username}.S" else "port: ${toString settings.port}"}
                      pomodoro_duration: ${toString settings.pomodoro_duration}
                      short_break_duration: ${toString settings.short_break_duration}
                      long_break_duration: ${toString settings.long_break_duration}
                      cycle: ${toString settings.cycle}
                    '';
                  } // lib.mapAttrs'
                    (name: value: lib.nameValuePair "ketchup/hooks/${name}" {
                      type = "exec";
                      text = lib.concatLines "#!/usr/bin/env bash" value;
                    })
                    (lib.filterAttrs (name: value: !isNull value) cfg.hooks);

                  systemd.user.services.ketchup = {
                    Install.WantedBy = [ "default.target" ];
                    Service.ExecStart = "${ketchup-server}/bin/ketchup-server";
                  };

                  home.packages = [ ketchup-cli ];
                };
            };

          packages = {
            ketchup-server = buildPackage {
              pname = "ketchup-server";
              description = "Pomodoro timer (server)";
              binaryName = "ketchup-server";
              src = "src/server_cli.cr";
            };

            ketchup-cli = buildPackage {
              pname = "ketchup-cli";
              description = "Pomodoro timer (client)";
              binaryName = "ketchup";
              src = "src/client_cli.cr";
            };
          };
        });
}

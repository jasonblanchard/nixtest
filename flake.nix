{
  description = "A simple Node.js TypeScript program";

  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];

      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          # Build the application package
          # packages.default = pkgs.stdenv.mkDerivation {
          #   pname = "nixtest";
          #   version = "1.0.0";

          #   src = ./.;

          #   buildInputs = with pkgs; [
          #     nodejs_22
          #   ];

          #   buildPhase = ''
          #     # No transpilation needed - Node 22 supports TypeScript natively
          #   '';

          #   installPhase = ''
          #     mkdir -p $out/bin
          #     cp index.ts $out/bin/

          #     # Create a wrapper script to run the TypeScript program directly
          #     cat > $out/bin/nixtest << EOF
          #     #!/usr/bin/env bash
          #     ${pkgs.nodejs_22}/bin/node --experimental-strip-types $out/bin/index.ts
          #     EOF
          #     chmod +x $out/bin/nixtest
          #   '';

          #   meta = with pkgs.lib; {
          #     description = "A simple Node.js TypeScript program";
          #     license = pkgs.lib.licenses.isc;
          #     platforms = pkgs.lib.platforms.all;
          #   };
          # };

          # Docker image
          # packages.docker = pkgs.dockerTools.buildLayeredImage {
          #   name = "nixtest";
          #   tag = "latest";
            
          #   contents = [
          #     self'.packages.default
          #     pkgs.coreutils
          #     pkgs.bash
          #   ];

          #   config = {
          #     Cmd = [ "/bin/nixtest" ];
          #     Env = [
          #       "NODE_ENV=production"
          #     ];
          #     WorkingDir = "/";
          #   };
          # };

          packages.docker = pkgs.dockerTools.buildLayeredImage {
            name = "nixtest";
            tag = "latest";
            
            contents = [
              pkgs.nodejs_22
              pkgs.coreutils
              pkgs.bash
            ];

            config = {
              Cmd = [ "${pkgs.nodejs_22}/bin/node" "./index.ts" ];
              Env = [
                "NODE_ENV=production"
              ];
              WorkingDir = "/";
            };
          };

          # Devenv shell configuration
          devenv.shells.default = {
            # https://devenv.sh/rexference/options/
            
            packages = with pkgs; [
              nodejs_22
            ];

            env = {
              MY_ENV_VAR = "some_value";
              NODE_ENV = "development";
            };

            # enterShell = ''
            #   echo "Welcome to the nixtest dev environment!"
            #   echo "Node version: $(node --version)"
            # '';

            languages.javascript = {
              enable = true;
              package = pkgs.nodejs_22;
            };

            tasks."nixtest:hello" = {
              exec = "node ./index.ts";
            };
          };

          # App for running
          apps.default = {
            type = "app";
            program = "${pkgs.writeShellScript "nixtest" ''
              cd ${./.}
              exec ${pkgs.nodejs_22}/bin/node index.ts
            ''}";
          };
        };
    };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };
}

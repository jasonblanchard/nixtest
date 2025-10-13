{
  description = "A simple Node.js TypeScript program";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs =
    {
      self,
      nixpkgs,
      devenv,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "nixtest";
            version = "1.0.0";

            src = ./.;

            buildInputs = with pkgs; [
              nodejs_22
            ];

            buildPhase = ''
              # No transpilation needed - Node 22 supports TypeScript natively
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp index.ts $out/bin/

              # Create a wrapper script to run the TypeScript program directly
              cat > $out/bin/nixtest << EOF
              #!/usr/bin/env bash
              ${pkgs.nodejs_22}/bin/node --experimental-strip-types $out/bin/index.ts
              EOF
              chmod +x $out/bin/nixtest
            '';

            meta = with pkgs.lib; {
              description = "A simple Node.js TypeScript program";
              license = pkgs.lib.licenses.isc;
              platforms = pkgs.lib.platforms.all;
            };
          };
        }
      );

      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                # https://devenv.sh/reference/options/
                packages = with pkgs; [
                  nodejs_22
                ];

                env = {
                  MY_ENV_VAR = "some_value";
                  NODE_ENV = "development";
                };

                enterShell = ''
                  echo "Welcome to the nixtest dev environment!"
                  echo "Node version: $(node --version)"
                '';

                # Optional: Configure languages
                languages.javascript = {
                  enable = true;
                  package = pkgs.nodejs_22;
                };
              }
            ];
          };
        }
      );

      apps = forEachSystem (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/nixtest";
        };
      });
    };
}

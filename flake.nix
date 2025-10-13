{
  description = "A simple Node.js TypeScript program";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = {
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
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs_22
          ];
          
          # Set environment variables directly
          MY_ENV_VAR = "some_value";
          NODE_ENV = "development";
          
          # Or use shellHook for more complex setup
          # shellHook = ''
          #   export ANOTHER_VAR="hello"
          #   echo "Welcome to the nixtest dev environment!"
          #   echo "Node version: $(node --version)"
          # '';
        };

        # App configuration for easy running
        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/nixtest";
        };
      }
    );
}

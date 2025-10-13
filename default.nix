{
  pkgs ? import <nixpkgs> { },
}:

pkgs.stdenv.mkDerivation {
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
    license = licenses.isc;
    platforms = platforms.all;
  };
}

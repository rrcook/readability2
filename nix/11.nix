# node.nix
with (import <nixpkgs> {});

let otp = pkgs.beam.packages.erlangR23;

in mkShell {
  buildInputs = [
    otp.elixir_1_11
  ];
}

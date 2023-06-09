# node.nix
with (import <nixpkgs> {});

let otp = pkgs.beam.packages.erlangR24;

in mkShell {
  buildInputs = [
    otp.elixir_1_12
  ];
}

{ pkgs ? import <nixpkgs> {}
, pkgsUnfree ? import <nixpkgs> { config = { allowUnfree = true; }; }
}: {
  openwrt = (import ./envs/openwrt/shell.nix { inherit pkgs; }).env;
}

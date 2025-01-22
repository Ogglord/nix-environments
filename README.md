# Nix-environments

Repository to maintain my devShells for nix.
This is originally a fork from github:nix-community/nix-environments where I had to modify the openwrt environment.


## Current available environments

| Name                                            | Attribute             |
|-------------------------------------------------|-----------------------|
| [OpenWRT](envs/openwrt)                         | `openwrt`             |


## How to use

### Nix Flakes

For dropping into the environment for the OpenWRT project, just run:

```
nix develop --no-write-lock-file github:Ogglord/nix-environments#openwrt
```

Two helper scripts are provided

```bash
apply-nix-fixes # this injects the LLVM path and checks for broken symlinks, which might occur since the build system symlinks to the nix store and the flake might update over time
builder # this helps you update feeds, compile, debug
```


## Technical stuff

The last part is a flake URL and is an abbreviation of `github:nix-community/nix-environments#devShells.SYSTEM.openwrt`, where `SYSTEM` is your current system, e.g. `x86_64-linux`.

You can also use these environments in your own flake and extend them:

```nix
{
  inputs.nix-environments.url = "github:Ogglord/nix-environments";

  outputs = { self, nixpkgs, nix-environments }: let
    # Replace this string with your actual system, e.g. "x86_64-linux"
    system = "SYSTEM";
  in {
    devShell.${system} = let
        pkgs = import nixpkgs { inherit system; };
      in nix-environments.devShells.${system}.openwrt.overrideAttrs (old: {
        buildInputs = old.buildInputs ++ [ pkgs.ncdu ];
      });
  };
}
```


### Other resources: 
- generates generic templates for different languages: https://github.com/kampka/nixify
- also templates for different languages: https://github.com/mrVanDalo/nix-shell-mix
- templates for flakes: https://github.com/NixOS/templates

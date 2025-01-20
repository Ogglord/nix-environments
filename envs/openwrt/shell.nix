{ pkgs ? import <nixpkgs> {}
, extraPkgs ? []
}:

let
  fixWrapper = pkgs.runCommand "fix-wrapper" {} ''
    mkdir -p $out/bin
    for i in ${pkgs.gcc.cc}/bin/*-gnu-gcc*; do
      ln -s ${pkgs.gcc}/bin/gcc $out/bin/$(basename "$i")
    done
    for i in ${pkgs.gcc.cc}/bin/*-gnu-{g++,c++}*; do
      ln -s ${pkgs.gcc}/bin/g++ $out/bin/$(basename "$i")
    done
    ln -sf ${pkgs.gcc.cc}/bin/{,*-gnu-}gcc-{ar,nm,ranlib} $out/bin
  '';

  fhs = pkgs.buildFHSUserEnv {
    name = "openwrt-env";
    targetPkgs = pkgs: with pkgs; [
      binutils
      bison
      file
      fixWrapper
      gcc
      git
      glibc.static
      gnumake
      gnupg
      go
      libelf
      llvmPackages_latest.llvm
      ncdu 
      ncurses            
      openssl
      patch
      perl
      pkg-config      
      (python3.withPackages (ps: [ ps.setuptools ps.distutils ps.pip]))
      quilt
      rsync
      squashfsTools
      subversion
      swig
      systemd
      unzip
      util-linux
      wget
      which
      zlib
      zlib.static
      zstd
    ] ++ extraPkgs;
     shellHook = ''
          # Find the most recent LLVM library path
          LLVM_HOST_PATH=${pkgs.llvmPackages_latest.llvm}/bin
          
          # Export the LLVM host path
          export LLVM_HOST_PATH

          echo "OpenWrt development shell"
          echo "LLVM Host Path: $LLVM_HOST_PATH"
          echo "ncurses-dev Path: ${pkgs.ncurses.dev}"
        '';
    multiPkgs = null;
    extraOutputsToInstall = [ "dev" ];
    hardeningDisable = [ "all" ];
    profile = ''
      export hardeningDisable=all
    '';
  };
in fhs

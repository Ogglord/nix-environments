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
    export LLVM_HOST_PATH=${pkgs.llvmPackages_latest.llvm}/bin
    echo LLVM_HOST_PATH=${pkgs.llvmPackages_latest.llvm}/bin > .llvm_info
  '';

  fhs = let
  apply-nix-fixes-script = pkgs.writeShellScriptBin "apply-nix-fixes" (builtins.readFile ./apply-nix-fixes.sh);
    in
    pkgs.buildFHSUserEnv {
    name = "openwrt-env";
    targetPkgs = pkgs: with pkgs; [
      fixWrapper
      apply-nix-fixes-script
      binutils
      bison
      file      
      flex
      cmake
      gcc
      gettext
      git
      glibc.static
      gnumake
      gnupg
      go
      less
      libelf
      llvmPackages_latest.llvm
      ncdu 
      ncurses5           
      openssl
      openssh
      patch
      perl
      pkg-config      
      (python3.withPackages (ps: [ ps.setuptools ps.distutils ps.pip]))
      quilt
      rsync
      sudo
      squashfsTools
      subversion
      swig
      libnl
      systemd
      tree
      tzdata      
      unzip
      util-linux
      wget
      which      
      zlib
      zlib.static
      zstd
    ] ++ extraPkgs;
     shellHook = ''                   
        '';
    multiPkgs = null;
    extraOutputsToInstall = [ "dev" ];
    hardeningDisable = [ "all" ];
    profile = ''
      export hardeningDisable=all
      export LLVM_HOST_PATH=${pkgs.llvmPackages_latest.llvm}/bin
      apply-nix-fixes
    '';
    OGGE = "apa";
  };
in fhs

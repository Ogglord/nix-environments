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

  fhs = let
  apply-nix-fixes-script = pkgs.writeShellScriptBin "apply-nix-fixes" (builtins.readFile ./apply-nix-fixes.sh);
  build-script = pkgs.writeShellScriptBin "build" (builtins.readFile ./build.sh);
    in
    pkgs.buildFHSUserEnv {
    name = "openwrt-env";
    targetPkgs = pkgs: with pkgs; [
      fixWrapper
      apply-nix-fixes-script
      build-script
      ] ++
      [
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
      perl540Packages.CPAN
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
      export PERL5LIB="${pkgs.perl}/lib/perl5/site_perl:${pkgs.perl}/lib/perl5/5.40.0:${pkgs.perl}/lib/perl5/5.40.0/x86_64-linux-thread-multi"
      export LLVM_HOST_PATH=${pkgs.llvmPackages_latest.llvm}/bin      
      ## apply our fixes, i.e. set in .config (CONFIG_BPF_TOOLCHAIN_HOST_PATH=$LLVM_HOST_PATH)
      apply-nix-fixes --verbose
      echo ""
      echo "SCRIPT: You can re-run the nix fix script by executing \"apply-nix-fixes\", or re-enter the devShell";
      echo "SCRIPT: You can use the OpenWRT build helper by executing \"build\"";
      echo ""
    '';
    GIT_SOURCE = "https://github.com/Ogglord/nix-environments";
  };
in fhs

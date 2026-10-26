{ stdenv, lib, kernel, src }:

let
  stdenv' = if kernel ? stdenv then kernel.stdenv else stdenv;
in
stdenv'.mkDerivation {
  pname = "linuwu-sense";
  version = "0.9.1-${kernel.version}";

  inherit src;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernel.makeFlags ++ [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
    "INSTALL_MOD_DIR=extra"
  ] ++ lib.optionals (stdenv'.cc.isClang or false) [
    "LLVM=1"
    "LLVM_IAS=1"
  ];

  buildPhase = ''
    runHook preBuild
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules_install INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=extra
    runHook postInstall
  '';

  # Touch .ko.cer for all installed modules to satisfy NixOS aggregateModules
  postInstall = ''
    find $out -name "*.ko" -exec touch {}.cer \;
  '';

  meta = with lib; {
    description = "Linux kernel module for Acer Predator & Nitro hardware control";
    homepage = "https://github.com/0x7375646F/Linuwu-Sense";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
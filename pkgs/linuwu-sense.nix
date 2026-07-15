{ stdenv, lib, kernel, src }:

let
  stdenv' = if kernel ? stdenv then kernel.stdenv else stdenv;
in
stdenv'.mkDerivation {
  pname = "linuwu-sense";
  version = "0.9.1-${kernel.version}";

  inherit src;

  sourceRoot = "source";

  unpackPhase = ''
    mkdir -p source
    cp -r $src/Linuwu-Sense/* source/
    chmod -R u+w source
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ] ++ lib.optionals (stdenv'.cc.isClang or false) [
    "LLVM=1"
    "LLVM_IAS=1"
  ];

  # Look inside the src/ folder where it was built!
  installPhase = ''
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
    install -Dm644 src/linuwu_sense.ko $out/lib/modules/${kernel.modDirVersion}/extra/linuwu_sense.ko
  '';
}

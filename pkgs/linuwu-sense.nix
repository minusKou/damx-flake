{ stdenv, lib, kernel, src }:

let
  # Grabs kernel compilation stdenv
  stdenv' = if kernel ? stdenv then kernel.stdenv else stdenv;
in

stdenv'.mkDerivation {
  pname = "linuwu-sense";
  version = "0.9.1-${kernel.version}";

  # Re-use the passed source
  inherit src;

  # Tell the builder to use the 'source' folder as the workspace root after unpacking
  sourceRoot = "source";

  # Copy our files into 'source' so the builder can automatically enter it and run 'make'
  unpackPhase = ''
    mkdir -p source
    cp -r $src/Linuwu-Sense/* source/
    chmod -R u+w source
  '';

  # This pulls in everything needed to compile a kernel module
  nativeBuildInputs = kernel.moduleBuildDependencies;

  # Standard Makefiles usually try to build for the running kernel via `uname -r`.
  # This tells make to build for the Nix kernel instead.
  makeFlags = [
    "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ] ++ lib.optionals (stdenv'.cc.isClang or false) [
    "LLVM=1"
    "LLVM_IAS=1"
  ];

  # Copy the resulting .ko file to the output directory
  installPhase = ''
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
    install -Dm644 linuwu_sense.ko $out/lib/modules/${kernel.modDirVersion}/extra/linuwu_sense.ko
  '';
}

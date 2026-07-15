{ stdenv, lib, kernel }:

stdenv.mkDerivation {
  pname = "linuwu-sense";
  version = "0.9.1-${kernel.version}";

  src = fetchzip {
    url = "https://github.com/PXDiv/Div-Acer-Manager-Max/releases/download/v0.9.1/DAMX-v0.9.1.zip";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  sourceRoot = "${src.name}/Linuwu-Sense";

  # This pulls in everything needed to compile a kernel module
  nativeBuildInputs = kernel.moduleBuildDependencies;

  # Standard Makefiles usually try to build for the running kernel via `uname -r`.
  # This tells make to build for the Nix kernel instead.
  makeFlags = [
    "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  # Copy the resulting .ko file to the output directory
  installPhase = ''
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/extra
    install -Dm644 src/linuwu_sense.ko $out/lib/modules/${kernel.modDirVersion}/extra/linuwu_sense.ko
  '';
}

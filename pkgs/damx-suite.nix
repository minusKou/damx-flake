{ lib
, stdenv
, autoPatchelfHook
, makeWrapper
, zlib
, icu
, fontconfig
, libGL
, libx11
, libice
, libsm
, libxext
, libxcursor
, libxrandr
, libxi
, libxrender
, libxcb
, libglvnd
, src
}:

stdenv.mkDerivation {
  pname = "damx-suite";
  version = "0.9.1";

  # Consume the single download passed from your flake
  inherit src;

  # Tell Nix to work out of a folder named 'source'
  sourceRoot = "source";

  # Simply copy the whole structure over so we can work with standard local paths
  unpackPhase = ''
    mkdir -p source
    cp -r $src/* source/
    chmod -R u+w source
  '';

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    icu
    fontconfig
    libGL
    libx11 libice libsm libxext libxcursor libxrandr libxi
    libxrender libxcb libglvnd
  ];

  dontStrip = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/256x256/apps

    install -Dm755 DAMX-Daemon/DAMX-Daemon $out/bin/DAMX-Daemon
    install -Dm755 DAMX-GUI/DivAcerManagerMax $out/bin/DivAcerManagerMax
    install -Dm644 DAMX-GUI/icon.png $out/share/icons/hicolor/256x256/apps/damx.png

    # Wrap the Daemon
    mv $out/bin/DAMX-Daemon $out/bin/.DAMX-Daemon-unwrapped
    makeWrapper $out/bin/.DAMX-Daemon-unwrapped $out/bin/DAMX-Daemon \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ icu fontconfig libGL libx11 libice libsm libxext libxcursor libxrandr libxi libxrender libxcb libglvnd ]}"

    # Wrap the GUI
    mv $out/bin/DivAcerManagerMax $out/bin/.DivAcerManagerMax-unwrapped
    makeWrapper $out/bin/.DivAcerManagerMax-unwrapped $out/bin/DivAcerManagerMax \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ icu fontconfig libGL libx11 libice libsm libxext libxcursor libxrandr libxi libxrender libxcb libglvnd ]}"

    # Create desktop file
    cat > $out/share/applications/damx.desktop << EOF
[Desktop Entry]
Name=DAMX
Comment=Div Acer Manager Max
Exec=$out/bin/DivAcerManagerMax
Icon=damx
Terminal=false
Type=Application
Categories=Utility;System;
Keywords=acer;laptop;system;
EOF

    # Re-create the DAMX shortcut
    makeWrapper $out/bin/DivAcerManagerMax $out/bin/DAMX
  '';
}

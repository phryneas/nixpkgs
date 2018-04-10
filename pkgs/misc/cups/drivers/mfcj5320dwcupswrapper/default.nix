{ pkgs, lib, stdenv, fetchurl, makeWrapper}:

let
  model_full = "MFC-J5320DW";
  model = lib.toLower (builtins.replaceStrings ["-"] [""] model_full);
  version = "3.0.1-1";
  urlChunk = "dlf101608";
  sha256 = "0kz0a496f6cqkl2yia5y8v87g3nl035ycs6s5wg9kz7w0yd77a7c";
  #binpkg = pkgs."${model}lpr";
  binpkg = pkgs.callPackage ../mfcj5320dwlpr/default.nix {};
  cupsConfDir = "brcupsconfig";
in
stdenv.mkDerivation rec {
  name = "${model}-cupswrapper-${version}";

  inherit version;

  src = fetchurl {
    url = "http://download.brother.com/welcome/${urlChunk}/brother_${model}_GPL_source_${version}.tar.gz";
    inherit sha256;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ binpkg ];

  patchPhase = ''
    WRAPPER=cupswrapper/cupswrapper${model}

    substituteInPlace $WRAPPER \
    --replace /opt "${binpkg}/opt" \
    --replace /usr "${binpkg}/usr" \
    --replace /etc "$out/etc"

    substituteInPlace $WRAPPER \
    --replace "\`cp " "\`cp -p " \
    --replace "\`mv " "\`cp -p "
    '';

  buildPhase = ''
    cd ${cupsConfDir}
    make all
    cd ..
    '';

  installPhase = ''
    TARGETFOLDER=$out/opt/brother/Printers/${model}/cupswrapper/
    mkdir -p $out/opt/brother/Printers/${model}/cupswrapper/

    cp ${cupsConfDir}/${cupsConfDir} $TARGETFOLDER
    cp cupswrapper/cupswrapper${model} $TARGETFOLDER/
    cp ppd/brother_${model}_printer_en.ppd $TARGETFOLDER/
    '';

  cleanPhase = ''
    cd ${cupsConfDir}
    make clean
    '';

  meta = {
    homepage = http://www.brother.com/;
    description = "Brother ${model_full} CUPS wrapper driver";
    license = stdenv.lib.licenses.gpl2;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = http://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=mfcj470dw_us_eu_as&os=128;
    maintainers = [ stdenv.lib.maintainers.yochai ];
  };
}

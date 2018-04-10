{ lib, stdenv, fetchurl, cups, dpkg, ghostscript, patchelf, a2ps, coreutils, gnused, gawk, file, makeWrapper }:

let
  model_full = "MFC-J5320DW";
  model = lib.toLower (builtins.replaceStrings ["-"] [""] model_full);
  version = "3.0.1-1";
  urlChunk = "dlf101591";
  sha256 = "14588g71dgxdg6dph8s8x4dsrzh8vkjbw5qk4h0psyla1j5rz232";
in
stdenv.mkDerivation rec {
  name = "${model}-lpr-${version}";

  inherit version;

  src = fetchurl {
    url = "http://download.brother.com/welcome/${urlChunk}/${model}lpr-${version}.i386.deb";
    inherit sha256;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ cups ghostscript dpkg a2ps ];

  unpackPhase = "true";

  installPhase = ''
    dpkg-deb -x $src $out

    substituteInPlace $out/opt/brother/Printers/${model}/lpd/filter${model} \
    --replace /opt "$out/opt" \

    sed -i '/GHOST_SCRIPT=/c\GHOST_SCRIPT=gs' $out/opt/brother/Printers/${model}/lpd/psconvertij2

    patchelf --set-interpreter ${stdenv.glibc.out}/lib/ld-linux.so.2 $out/opt/brother/Printers/${model}/lpd/br${model}filter

    mkdir -p $out/lib/cups/filter/
    ln -s $out/opt/brother/Printers/${model}/lpd/filtermfcj470dw $out/lib/cups/filter/brother_lpdwrapper_${model}

    wrapProgram $out/opt/brother/Printers/${model}/lpd/psconvertij2 \
    --prefix PATH ":" ${ stdenv.lib.makeBinPath [ gnused coreutils gawk ] }

    wrapProgram $out/opt/brother/Printers/${model}/lpd/filter${model} \
    --prefix PATH ":" ${ stdenv.lib.makeBinPath [ ghostscript a2ps file gnused coreutils ] }
    '';

  meta = {
    homepage = http://www.brother.com/;
    description = "Brother ${model_full} LPR driver";
    license = stdenv.lib.licenses.unfree;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = "http://support.brother.com/g/b/downloadlist.aspx?c=us&lang=en&prod=${model}_us_eu_as&os=128";
    maintainers = [ stdenv.lib.maintainers.yochai ];
  };
}

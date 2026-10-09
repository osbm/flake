# Sleep screen for the Xteink X4 (CrossPoint firmware).
# CrossPoint wants an uncompressed 24-bit BMP at 480x800; copy result/sleep.bmp
# to the SD card root (or into /.sleep/ to rotate between several images).
{
  runCommand,
  resvg,
  imagemagick,
  cascadia-code,
  noto-fonts-cjk-sans,
}:
runCommand "xteink-sleep"
  {
    nativeBuildInputs = [
      resvg
      imagemagick
    ];
  }
  ''
    mkdir -p $out
    resvg --skip-system-fonts \
      --use-fonts-dir ${cascadia-code}/share/fonts/truetype \
      --use-fonts-dir ${noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk \
      ${./sleep.svg} $out/sleep.png
    magick $out/sleep.png -background white -flatten -alpha off -type TrueColor BMP3:$out/sleep.bmp
  ''

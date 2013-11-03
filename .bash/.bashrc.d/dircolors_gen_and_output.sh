#!/bin/bash
function dircolors_gen_and_output ()
{
  archives=(.tar .tgz .arj .taz .lzh .lzma .tlz .txz .zip .bz2 .tbz .tbz2 .deb .rpm .jar .war .ear .sar .rar .ace .zoo .cpio)

  images=(.jpg .jpeg .gif .bmp .pbm .pgm .ppm .tga .xbm .xpm .tif .tiff .png .svg .svgz .mng .pcx .mov .mpg .mpeg .m2v .mkv .webm .ogm .mp4 .m4v .mp4v .vob .nuv .wmv .asf .rmvb .flc .avi .fli .flv .xcf .xwd .yuv .cgm .emf)

  mediafiles=(.axv .anx .ogv .ogx)

  videofiles=(.aac .flac .mid .midi .mka .mp3 .mpc .ogg .wav)
}

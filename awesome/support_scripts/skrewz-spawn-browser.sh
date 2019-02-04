#!/bin/bash
private="by default"
url="duckduckgo.com"


while [ "0" != "$#" ]; do
  case "$1" in
    --non-private)
      private="" ;;
    *)
      url="$1"
      break
      ;;
  esac
  shift
done

if [ -n "$private" ]; then
  private_infix="-p "
else
  private_infix="-w "
fi

qutebrowser --qt-flag disable-reading-from-canvas --target window ":open ${private_infix}$url"

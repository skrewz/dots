#!/bin/bash
private="by default"
url="https://dashboards.skrewz.net/newtab"


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

exec ~/repos/qutebrowser-pinusc/qutebrowser.py --qt-flag disable-reading-from-canvas --target window ":open ${private_infix}$url"

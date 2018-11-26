#!/bin/bash

#firefox --private-window
if [ "--non-private" = "$1" ]; then
  qutebrowser --qt-flag disable-reading-from-canvas --target window
else
  qutebrowser --qt-flag disable-reading-from-canvas --target window ':open -p duckduckgo.com'
fi

#!/bin/bash

# Check if the kill file exists, and if it does (and is still relevant), noop out:
if [ -e /tmp/s-productivity-go-black-until ] && (( $(date +%s) < $(stat -c%Y /tmp/s-productivity-go-black-until) )); then
  screen -D # to kill the previous scratch window here.
  /usr/bin/urxvt -background rgba:FFFF/0000/0000/8000 -fn '-*-terminus-*-*-*-*-*-320-*-*-*-*-*-*' -e bash -ic $'echo "\n\n\e[41mYou are not supposed to be here.\n\n\e[0m"; echo "It is now:\n\n    '"$(date +%F\ %T)"$'\n\n/tmp/s-productivity-go-black-until expires:\n\n    '"$(date -d @$(stat -c%Y /tmp/s-productivity-go-black-until) +%F\ %T) (>=$(( ($(date -d @$(stat -c%Y /tmp/s-productivity-go-black-until) +%s)-$(date +%s))/3600 ))h away)"$'.\n\n"; for((i=10;--i;i>0)); do echo -n "\rQuitting in... $i"; sleep 1; done'
  exit 0
fi

#/usr/bin/urxvt -background rgba:0000/0000/0000/F000 -e bash -ic 'ssh -t skrewz@slovener.hosts.skrewz.net screen -xRR weechat'
/usr/bin/urxvt -background rgba:0000/0000/0000/F000 -e bash -ic 'screen -xRR'

#!/bin/bash

# Check if the kill file exists, and if it does (and is still relevant), noop out:
if [ -e /tmp/s-productivity-go-black-until ] && (( $(date +%s) < $(stat -c%Y /tmp/s-productivity-go-black-until) )); then
  screen -D # to kill the previous scratch window here.
  /usr/bin/urxvt -background rgba:0000/0000/0000/F000 -e bash -ic "echo 'You are not supposed to be here.'; echo '/tmp/s-productivity-go-black-until expires at: $(date -d @$(stat -c%Y /tmp/s-productivity-go-black-until) +%F\ %T).'; sleep 2"
  exit 0
fi

#/usr/bin/urxvt -background rgba:0000/0000/0000/F000 -e bash -ic 'ssh -t skrewz@slovener.hosts.skrewz.net screen -xRR weechat'
/usr/bin/urxvt -background rgba:0000/0000/0000/F000 -e bash -ic 'screen -xRR'

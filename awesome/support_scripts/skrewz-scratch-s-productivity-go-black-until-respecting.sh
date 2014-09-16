#!/bin/bash


declare -A todays_ranges=( \
  [morning]="$(date --date "10:20" +%s)-$(date --date "12:10" +%s)"
  [afternoon]="$(date --date "13:00" +%s)-$(date --date "17:00" +%s)"
)


expiration_verbosity_command=$''

#echo "now=$(date +%s)"
periods_of_today_printable=""
inside_silent_period=""
this_silent_period_ends=""
for periodname in "${!todays_ranges[@]}"; do
  #echo "period $periodname's range: $(date --date "@${todays_ranges[$periodname]%%-*}" +%H:%M:%S) (@${todays_ranges[$periodname]%%-*}) - $(date --date "@${todays_ranges[$periodname]##*-}" +%H:%M:%S) (@${todays_ranges[$periodname]##*-})"
  periods_of_today_printable+="$(printf -- "- %10s: %s - %s\n" "$periodname" "$(date --date "@${todays_ranges[$periodname]%%-*}" +%H:%M:%S)" "$(date --date "@${todays_ranges[$periodname]##*-}" +%H:%M:%S)")"$'\n'
  if (( ${todays_ranges[$periodname]%%-*} < $(date +%s) )) && (( ${todays_ranges[$periodname]##*-} > $(date +%s) )); then
    inside_silent_period="$periodname"
    this_silent_period_ends="$(date -d "@${todays_ranges[$periodname]##*-}" +%H:%M)"
  fi
done


if [ -n "$inside_silent_period" ]; then
  expiration_verbosity_command=$'echo "\n\n\e[32;4mWhoa.\e[0m   \e[32;4mBreathe (deeply, perhaps).\n\n- You didn\'t want to check your jabber client.\n- You wanted to remain productive.\e[0m"; echo "You are in the silent period \\"\e[31m'"$inside_silent_period"$'\e[0m\\".\n\n'"$periods_of_today_printable\""
  if [ -p "$HOME/.mcabber-work/fifo" ]; then
    echo "/away (gone black; back at $this_silent_period_ends; http://u.booking.com/RJ)" > .mcabber-work/fifo
  fi
# Check if the kill file exists, and if it does (and is still relevant), noop out:
elif [ -e /tmp/s-productivity-go-black-until ] && (( $(date +%s) < $(stat -c%Y /tmp/s-productivity-go-black-until) )); then
  expiration_verbosity_command=$'echo "\n\n\e[41mYou are not supposed to be here.\n\n\e[0m"; echo "It is now:\n\n    '"$(date +%F\ %T)"$'\n\n/tmp/s-productivity-go-black-until expires:\n\n    '"$(date -d @$(stat -c%Y /tmp/s-productivity-go-black-until) +%F\ %T) (>=$(( ($(date -d @$(stat -c%Y /tmp/s-productivity-go-black-until) +%s)-$(date +%s))/3600 ))h away)"$'.\n\n"'
fi



if [ -n "$expiration_verbosity_command" ]; then
  screen -D # to kill the previous scratch window here.
  /usr/bin/urxvt -background rgba:0000/8080/0000/FFFF -fn '-*-terminus-*-*-*-*-*-320-*-*-*-*-*-*' -e bash -ic "$expiration_verbosity_command;"$'for((i=10;--i;i>0)); do echo -n "\rQuitting in... $i"; sleep 1; done'
  exit 0
else
  #/usr/bin/urxvt -background rgba:0000/0000/0000/F000 -e bash -ic 'ssh -t skrewz@slovener.hosts.skrewz.net screen -xRR weechat'
  # Not in silent period: clear onlineness upon screen opening (every time, too.)
  if [ -p "$HOME/.mcabber-work/fifo" ]; then
    echo "/online -" > .mcabber-work/fifo
  fi
  /usr/bin/urxvt -background rgba:0000/0000/0000/F000 -e bash -ic 'screen -xRR'
fi


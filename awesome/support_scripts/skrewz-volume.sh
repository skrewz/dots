#!/bin/bash
# Licenced under GPL3+. (C) Anders Breindahl <skrewz@skrewz.net>, 2013.
#
# Current implementation: Take the currently-running PulseAudio sink and modify
# its volume.

percent_adjustment="10"

for prog in pactl; do
  if ! which "$prog" >& /dev/null; then
    echo "Needs $prog to be in PATH. Aborting." >&2
    exit 1
  fi
done


verbosemode=""
adjustment="0%"
while [ "0" != "$#" ]; do
  case "$1" in
    -v|--verbose)
      verbosemode="yea" ;;
    --increase)
      adjustment="+${percent_adjustment}%" ;;
    --decrease)
      adjustment="-${percent_adjustment}%" ;;
    *)
      echo "Unrecogized option: \"$1\". Aborting."
      exit 1 ;;
  esac
  shift
done

pactl_list_short_sinks="$(pactl list short sinks)"
if [ -z "$pactl_list_short_sinks" ]; then
  echo "No sinks. Can't proceed. Aborting." >&2
  exit 1
fi

running_sink="$(awk '/RUNNING$/ {print $2}' <<< "$pactl_list_short_sinks")"
if [ -n "$running_sink" ]; then
  pactl -- set-sink-volume "$running_sink" "$adjustment"
else
  echo "No running sinks. No-op'ing out." >&2
  exit 0
fi


# amixer set PCM 2dB+
# amixer set PCM 2dB-
# amixer set Master unmute
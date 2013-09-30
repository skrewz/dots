#!/bin/bash
alias bashcolors='for first in {0..47}; do for second in {0..8}; do printf "  \\e[%u;%um%s[%0.2u;%0.2um\e[0m "  $first $second "\e" $first $second; done; echo; done'

if [ -d ~/repos ]; then
  alias my_local_diffs='for repo in ~/repos/*; do [ -d "$repo" ] && cd "$repo" && git diff --name-only 2>&1 | sed -e "s/^/$(basename "$repo"): /"; cd - >/dev/null; done'
fi


if [ -n "$skrewz_sends_mails_to" -a "$skrewz_sends_mails_as" ]; then
  function s-mailtoself ()
  { # {{{
    local sendmail
    if which sendmail >&/dev/null; then
      sendmail="$(which sendmail)"
    elif [ -x /usr/sbin/sendmail ]; then
      sendmail="/usr/sbin/sendmail"
    else
      echo "No sendmail found, aborting." >&2
      return 1
    fi

    mkdir --mode 0700 -p "$HOME/privtmp"
    local tempfile="$(mktemp --tmpdir="$HOME/privtmp/" mailtoself.XXXXXXXXXX)"
    local starttime="$(date +%s)"
    cat > "$tempfile"
    local endtime="$(date +%s)"

    local from="mailtoskrewz@$(hostname -s)"
    local subject="mailtoskrewz @ $(date +%Y-%m-%d\ %H:%M:%S): $(hostname -s)"

    while [ "0" != "$#" ]; do
      case "$1" in
        --verbatim-subject)
          subject="$2"
          shift ;;
        -s|--short-desc)
          from="$2 @ $(hostname -s)"
          subject="$2 ($(date --date @$starttime +%Y-%m-%d\ %H:%M:%S), took $((endtime-starttime))s)"
          shift ;;
        *)
          echo "Unrecogized parameter: \"$1\". Aborting." >&2
          return 1 ;;
      esac
      shift
    done


    (echo -e "From: $from <$skrewz_sends_mails_as>\nSubject: $subject\n\n"; cat "$tempfile") |
    $sendmail -F "$from" -f "$skrewz_sends_mails_as" "$skrewz_sends_mails_to"
    rm "$tempfile"
  } # }}}
fi


# Detects numeric ranges in stdin, and echoes them as "$start $end" lines for each range:
function s-range-print-numeric-range ()
{ # {{{
  local newval oldval=1
  (cat; echo "_reserved_for_range_detection__end___") |
  while read newval; do
    if [ "_reserved_for_range_detection__end___" == "$newval" ]; then
      echo " $oldval"
    elif ((1 == oldval)); then
      echo -n "$newval"
    elif ((newval != oldval + 1)); then
      echo " $oldval"
      echo -n "$newval"
    fi
    oldval="$newval"
  done
} # }}}

# Meant for timing of commands at a later stage. Poor man's `at`.
function s-wait-until-after ()
{ # {{{
  (($# >= 1))  || echo "s-wait-until-after: Not enough parameters." >&2
  local start="$(date --date "$1" +%s)"
  if ! egrep -q "^[0-9]+$" <<< "$start"; then
    echo "Your supplied timestamp: \"$1\" didn't yield any timestamp. Aborting." >&2
    return 1
  fi
  while (( $(date +%s) <= start)); do
    sleep 1
  done
  return 0
} # }}}


function s-as-sum-of-powers-of-two ()
{ # {{{
  orgval="$1"
  largest_power="0"
  for ((i=n;i<50;i++)); do
    #echo "largest_power=$largest_power; \$i=$i"
    if [ "0" != "$(bc <<< "2^$i > $orgval")" ]; then
      largest_power="$((i-1))"
      break
    fi
  done
  
  string=""
  remainder="$orgval"
  for ((i=largest_power;i>=0;i--)); do
    #echo "largest_power=$largest_power; \$i=$i; remainder=$remainder"
    if [ "0" != "$(bc <<< "2^$i <= $remainder")" ]; then
      #echo "Subtracting 2^$i."
      string="$string${string:+ + }2^$i"
      remainder="$(bc <<< "$remainder - 2^$i")"
    #else
    # echo "Not subtracting 2^$i."
    fi
  done
  if [ "$orgval" != "$(bc <<< "$string")" ]; then
    echo "Something's wrong: $orgval != \$(bc <<< \"$string\")." >&2
  fi
  echo "$string"
} # }}}

function s-sum-numbers ()
{ # {{{
  divisor="1"
  if [ "$1" = "--div" ]; then
    divisor="$2"
  fi
  ( echo -n 'scale=5; ('; sed -e 's/$/ +\\/g' ; echo "0)/$divisor") | bc | sed -re "s/0+$//g"
} # }}}

function s-avg-numbers ()
{ # {{{
  input="$(cat)"
  echo  "scale=5; ($(s-sum-numbers <<< "$input"))/$(wc -l <<< "$input")" | bc | sed -re "s/0+$//g"
} # }}}


#alias taillogs="echo \"skrewz-alias: Running tail -Fs.3 /var/log/{httpd/*/*_log.\$(date +%Y-%m-%d),services/trace.\$(date +%Y-%m-%d).log}:\" >&2; sudo tail -n2 -Fs.3 /var/log/{httpd/*/*_log.\$(date +%Y-%m-%d),services/trace.\$(date +%Y-%m-%d).log}"

alias htop="timeout 24h htop -d 10"
alias g="git"
alias gd="git diff"
# (Who calls `gs` from the CLI anyway?)
alias gs="git status"


alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -lA --full-time'
alias l='ls $LS_OPTIONS -oh'
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"



if [ -e ~/.bash_aliases_local ]; then
  source ~/.bash_aliases_local
fi

# vim: fdm=marker fml=1

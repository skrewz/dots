#!/bin/bash
alias bashcolors='for first in {0..47}; do for second in {0..8}; do printf "  \\e[%u;%um%s[%0.2u;%0.2um\e[0m "  $first $second "\e" $first $second; done; echo; done'

if [ -d ~/repos ]; then
  alias my_local_diffs='echo "Wrong alias. Try s-git-local-diffs"'
  alias s-git-local-diffs='for repo in ~/repos/*; do [ -d "$repo" ] && cd "$repo" && git status >&/dev/null || continue; git diff --name-only 2>&1 | sed -e "s/^/$(basename "$repo"): /"; cd - >/dev/null; done'
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
 ( echo -n 'scale=5; ('; sed -e 's/$/ +\\/g' ; echo "0)/$divisor") | bc | sed -re "s/\.?0+$//g"
} # }}}
function s-avg-numbers ()
{ # {{{
  input="$(cat)"
  echo  "scale=5; ($(s-sum-numbers <<< "$input"))/$(wc -l <<< "$input")" | bc | sed -re "s/0+$//g"
} # }}}

# an attempt at convenient multiline word-delimited blockwise grep; i.e.
# (limited to and output like large egrep -C behaviour.)
# s-mlgrep "delim" <egrep options>
#
#   Yields the output delim-delimited blocks that match the egrep expression
#
function s-mlgrep ()
{ # {{{
  local delim="$1"
  shift
  eval "parallel --gnu --pipe --block 1 --recstart \"$delim\" \"egrep --colour=always -C9999999 $@\"" 2> >(grep --line-buffered -vF "parallel: Warning: A full record was not matched in a block.")
} # }}}

function s-apt-fullupgrade()
{ # {{{

  echo "=> Running \`apt update\`..."
  apt update
  echo "=> Running \`apt full-upgrade\` (a 'y' keypress will be needed)..."
  DEBIAN_FRONTEND=noninteractive apt full-upgrade
  echo "=> Running \`apt autoremove\`"
  DEBIAN_FRONTEND=noninteractive apt autoremove

  i=0
  while [ -n "$(deborphan)" ] && ((i++ < 10)); do
    echo "=> Running \`apt remove \$(deborphan)\`"
    DEBIAN_FRONTEND=noninteractive apt remove $(deborphan)
  done
} # }}}


function s-hex-to-binary-and-decimal ()
{ # {{{
  if ! egrep -q "^(0x)?[0-9A-Fa-f]{2}$" <<< "$1"; then
    echo "That doesn't seem like a hex byte: \"$1\""
  fi
  arg="${1#0x}"
  decimal=$(printf "%u" 0x$arg)
  rest=$decimal
  binary=""
  for i in {7..0}; do 
    #echo "rest:$rest,2**i:$((2**i)),binary:$binary"
    if [ "$rest" != "0" ] && [ $((2**i)) -le $rest ]; then
      binary="${binary}1"
      rest=$((rest - 2**i))
    else
      binary="${binary}0"
    fi
  done
  echo -e "0x$arg == $decimal\n     == 0b$binary"
} # }}}
function s-binary-to-hex-and-decimal ()
{ # {{{
  if ! egrep -q "^(0b)?(0|1){8}$" <<< "$1"; then
    echo "That doesn't seem like a binary byte: \"$1\""
  fi
  arg="${1#0b}"
  sum=0
  for i in {0..7}; do 
    sevenminusi=$((7-i))
    #echo "Your $i'th most significant bit: ${arg:$i:1}"
    if [ "${arg:$i:1}" == "1" ]; then
      sum=$((sum + $((2**sevenminusi))))
      #echo "... counted as $((2**sevenminusi))."
    fi
  done
  echo -e "0b$arg == $sum\n           == 0x$(printf "%x" $sum)"
} # }}}
function s-iostat ()
{ # {{{
  input="$(cat)"
  local map="$(find /dev/mapper -type l -print0 | parallel -0 --gnu echo '$(readlink {1} | sed -e "s|^..\/||") {1}')"

  local IFS_backup="$IFS"
  local IFS=$'\n'
  local map_as_replacements="$(sed -re "s|^([^ ]+) ([^ ]+)$|s#^\1#\2#|g" <<< "$map" | tr "\n" ";")"
  #local map_as_replacements="$(sed -re "s|^([^ ]+) ([^ ]+)$|s#^\1#\2 (\&))#|g" <<< "$map" | tr "\n" ";")"
  local IFS="$IFS_backup"


  local column_formats=( "%-30s" "%8s" "%8s" "\e[1m%6s" "\e[1m%6s" "\e[1m%8s" "\e[1m%8s" "%9s" "%9s" "%6s" "%8s" "%8s" "%6s" "%6s" )
  linenum=0


  while true; do
    echo -ne "\e[1;1H"
    # Generates a one-second I/O breakdown:
    iostat -xmd 1 2 | tac | sed -ne "1,/^Device/ p" | tac | egrep -v "^$" |
    sed -re "$map_as_replacements" | sed "s|^/dev/mapper/||" |
    sed -re "s|\b0\.00\b|-|g" -e "s|([0-9])\.00\b|\1|g" |
    while read line; do
      line_formatting=$( [ "0" != "$((linenum % 2))" ] && echo "\e[33m" || echo "\e[36m")
      line_formatting="\e[3$((linenum % 3 + 2))m"
      field=0
      echo -ne "$line_formatting"

      field=0
      sed -re "s/[[:space:]]+/\n/g" <<< "$line" | while read word; do
        printf "$line_formatting${column_formats[$field]}\e[0m \e[30;1m|\e[0m" "${word}"
        ((field++))
      done
      echo -ne "\e[0m\e[K\n\e[J"
      ((linenum++))
    done
    sleep 1
  done
} # }}}

function s-notetoself ()
{ # {{{
  echo "note to self: $1" >> ~/s-notetoself.log
} # }}}


function s-mac-generate ()
{ # {{{
  # libvirt likes its mac with a 0x52 leading octet (?)
  head -c 5 /dev/urandom | xxd -ps | sed -re 's/(..)/:&/g' -e 's/^:/52:/'
} # }}}

alias rootify="echo 'skrewz-alias: Becoming root through [some complicated bash logic]...' >&2; sudo -i su -l -c 'bash --rcfile $HOME/.bashrc-when-sudo-su-ing'"

#alias taillogs="echo \"skrewz-alias: Running tail -Fs.3 /var/log/{httpd/*/*_log.\$(date +%Y-%m-%d),services/trace.\$(date +%Y-%m-%d).log}:\" >&2; sudo tail -n2 -Fs.3 /var/log/{httpd/*/*_log.\$(date +%Y-%m-%d),services/trace.\$(date +%Y-%m-%d).log}"

alias htop="timeout 24h htop -d 2"
alias g="git"
alias gd="git diff"
# (Who calls `gs` from the CLI anyway?)
alias gs="git status"
alias gp="git pull && git status"

# keystrokes matter:
alias dn="dirname"
alias bn="basename"
alias wh="which"

function c()
{
  [ -d "$1" ] && cd "$1" || cd "$(dirname "$1")"
  ls -ghA --color | (head -n10; lines="$(wc -l)"; echo $'\n'"[ $lines more...]")
}

if which youtube-dl &> /dev/null; then
  function yd() {
    cd /tmp/
    pwd
    if [ "-m" == "$1" ]; then
      filename="$(youtube-dl --continue --title --get-filename "$2")"
      echo "Downloading to ${filename}..."
      youtube-dl --continue --output "$filename" "$2" &
      sleep 1
      echo "sleep 5"
      sleep 4
      echo "Spawning \`mplayer ${filename}*\`..."
      mplayer "$filename"*
    else
      filename="$(youtube-dl --continue --title --get-filename "$1")"
      echo "Downloading to ${filename}..."
      youtube-dl --continue --output "$filename" "$1"
    fi
  }
fi

function cdwh()
{ # {{{
  [ -n "$1" ] || { echo "No parameter given to $FUNCNAME. Giving up."; return 1; }
  cd "$(dirname "$(which "$1")")"
} # }}}
function vimwh()
{ # {{{
  [ -n "$1" ] || { echo "No parameter given to $FUNCNAME. Giving up."; return 1; }
  echo "Spawning \`vim \"$(which "$1")\"..." >&2
  vim "$(which "$1")"
} # }}}
function cpwh()
{ # {{{
  cp -v "$(which "$1")" "$2"
} # }}}

complete -c wh vimwh cdwh cpwh

function s-git-commit-rebase-push()
{ # {{{
  local message=""
  local all=""
  declare -a cmdlineparms
  while [ "0" != "$#" ]; do 
    case "$1" in
      --message)
        message="$2"
        shift ;;
      --all|-a)
        all="mm-hm." ;;
      -*)
        echo "Not recognized, aborting: \"$1\"." >&2
        return 1 ;;
      *)
        cmdlineparms+=( "$1" ) ;;
    esac
    shift
  done

  echo -e "\e[32ms-git-commit-rebase-push: Your stash list, *prior* to doing anything: \n=====================\e[0m" >&2
  git stash list
  echo -e "\e[32ms-git-commit-rebase-push: Your git status, *prior* to doing anything: \n=====================\e[0m" >&2
  git status

  # Make the commit:
  echo -e "\e[32ms-git-commit-rebase-push: Committing with \`git commit -v${message:+ --message \"$message\"}${all:+ -a}${cmdlineparms[@]}\`...\n=====================\e[0m" >&2
  git commit -v${message:+ --message "$message"}${all:+ -a} ${cmdlineparms[@]}

  # Loop over the forceful rebase of it:
  local stashed=""
  while true; do
    echo -e "\e[32ms-git-commit-rebase-push: One iteration of: stashing/rebasing/pop'ing\n=====================\e[0m" >&2
    if [ "0" != "$(git diff | wc -l )" ]; then
      stashed="yes"
      git stash || return 1
    fi

    git pull --no-edit --rebase || return 1

    if [ -n "$stashed" ]; then
      git stash pop || return 1
    fi
    echo -e "\e[32ms-git-commit-rebase-push: Pushing...\n=====================\e[0m" >&2
    git push && break
  done
  echo -e "\e[32ms-git-commit-rebase-push: Pushed.\e[0m" >&2
} # }}}

function s-xclip-pwd ()
{ # {{{
  pwd | xclip -i
} # }}}

function s-today-notes ()
{ # {{{
  vim ~/notes/$(date +%F).notes
} # }}}

function s-ip-get-public ()
{ # {{{
  echo "Good candidates for what the current public ipv4 is:"
  wget -qO- minip.dk | egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}" | sort -u
} # }}}

alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -lA --full-time'
alias l='ls $LS_OPTIONS -oh'
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias s-mutt="TERM=rxvt-256color mutt"

function s-taillogs ()
{ # {{{
  local -a colours=( $'\e[31;1m' $'\e[32;1m' $'\e[33;1m' $'\e[34;1m' $'\e[35;1m' $'\e[36;1m' )
  local -a logfiles=( "/var/log/syslog" "/var/log/messages" )

  echo  "Warning: this function ain't finished. It's leaving nasty jobbitses around after it itself is gone."
  echo "Do you still, you know... want to use it?"
  echo -n "Enter to proceed, SIGINT otherwise:"
  read _

  if [ "root" != "$(whoami)" ]; then
    echo "You're not root. No log-tailing for you." >&2
    return 0
  fi
  for key in "${!logfiles[@]}"; do
    if [ ! -r "${logfiles[$key]}" ]; then
      echo "s-taillogs: Not using logfile \"${logfiles[$key]}\" as it's not readable."
      unset logfiles["$key"]
    fi
  done

  i=0
  local -a pids=()
  for file in "${logfiles[@]}"; do
    echo "s-taillogs: Will be tailing logfile \"$file\"."
    (tail -Fn0 -s0.4 "$file" | sed -u "s/^.*$/$(printf "%-12s" "$(basename "$file")"): ${colours[$i]}&"$'\e[0m/' ) &
    pids+=( "$!" )
    ((i++)) || true
  done

  trap 'for pid in "${pids[@]}"; do echo killing pid $pid; kill $pid; done; exit 0' SIGINT
  wait "${pids[@]}"
  trap - SIGINT
  sudo tail -Fn0 "${logfiles[@]}"
} # }}}


if [ -e ~/.bash_aliases_local ]; then
  source ~/.bash_aliases_local
fi

# vim: fdm=marker fml=1

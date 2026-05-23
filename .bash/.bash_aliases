#!/bin/bash

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


function s-mac-generate ()
{ # {{{
  # libvirt likes its mac with a 0x52 leading octet (?)
  head -c 5 /dev/urandom | xxd -ps | sed -re 's/(..)/:&/g' -e 's/^:/52:/'
} # }}}

alias gd="git diff"
# (Who calls `gs` from the CLI anyway?)
alias gs="git status"
alias gp="git pull && git status"
alias gcd='cd "$(git rev-parse --show-toplevel)"'
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -lA --full-time'
alias l='ls $LS_OPTIONS -oh'
alias grep="grep --color=auto"

if [ -e ~/.bash_aliases_local ]; then
  source ~/.bash_aliases_local
fi

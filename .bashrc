# ~/.bashrc: executed by bash(1) for non-login shells.

export PS1='\h:\w\$ '
umask 0002
#export TERM=rxvt
export EDITOR=vim
export HISTSIZE=100000

skrewz_sends_mails_to="skrewz@skrewz.net"
skrewz_sends_mails_as="skrewz+mailteselfbounces@skrewz.net"
alias rootify="echo 'skrewz-alias: Becoming root through su...' >&2; su"

if [ -d "$HOME/.bashrc.d" ]; then
  for file in "$HOME/.bashrc.d/"*.sh; do
    . "$file"
  done
fi

export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%M: '
export HISTCONTROL=ignorespace
# Line numbers in bash -x output:
export PS4='+(${BASH_SOURCE##*/}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# If you don't use this, you'll get annoyed when you accidentally press
# Control-s and your terminal hangs misearably until you press Control-q, or
# something like that.  Anyway. The phenomenon is called XON/XOFF-control.

# And I'm turning it off.
stty -ixon


function set_title ()
{
  local word_blacklist=$'vim\nbash\nhistory\nsed\nsort\ntail\necho\negrep\ngrep'
  local words="$(HISTTIMEFORMAT="" history | sed -re "s/^\s*[0-9]*\s*//"  | uniq | tail -n60 | tr " " "\n" | sort -u | egrep '^[A-Za-z0-9_.-]+$' | grep -vF "$word_blacklist" | sort -u | tr "\n" " ")"
  echo -ne "\\e]0;$USER@$HOSTNAME: $words\\007"
}

function print_bash_bt ()
{
  echo "BASH_SOURCE:"
  for key in "${!BASH_SOURCE[@]}"; do
    echo "key:$key, value ${BASH_SOURCE[$key]}:${BASH_LINENO[$key]}."
  done

  echo "BASH_ARGV's:"
  for key in "${!BASH_ARGV[@]}"; do
    echo "key:$key, value \"${BASH_ARGV[$key]}\"."
  done
}
export -f print_bash_bt set_title

# Initial attempts at making grep-friendly urxvt titles:
export PROMPT_COMMAND="set_title; history -a; "


# Change the window title of X terminals 
if egrep -q "^.*(xterm|rxvt).*$" <<< "$TERM"; then
  set -o functrace
  #trap 'env > /tmp/env' DEBUG
  #trap "echo -e \"\e]0;$BASH_COMMAND\\007\"" DEBUG
  #trap "set_title" DEBUG
fi

# TMOUT be default to noon next day
# Annoying.
# export TMOUT="$(($(date --date "$(date --date tomorrow +%Y-%m-%d) 12:00:00" +%s) - $(date +%s)))"

# Alias ssh-add to be timeout'ing out-of-hours on the following day. Kind of
# convenient when you know it works this way.
alias ssh-add='ssh-add -t $(($(date --date "$(date --date tomorrow +%Y-%m-%d) 6:00:00" +%s) - $(date +%s))) $HOME/.ssh/id_rsa_private_use $HOME/.ssh/id_rsa_work'

export LS_OPTIONS='--color=auto'
eval "`dircolors`"


# Failed history completion doesn't execute by default.
# (That being said, C-^ for completion makes this almost unneeded.)
shopt -s histreedit



if [ -e "$(dirname "${BASH_SOURCE[0]}")/all_bash_aliases.sh" ]; then
  source "$(dirname "${BASH_SOURCE[0]}")/all_bash_aliases.sh"
fi
# Using vim as a pager:
export PAGER="/bin/sh -c \"unset PAGER;col -b -x | \
  vim -R -c 'set ft=man nomod nolist' -c 'map q :q<CR>' \
  -c 'set nonumber' \
  -c 'map <SPACE> <C-D>' -c 'map b <C-U>' \
  -c 'nmap K :Man <C-R>=expand(\\\"<cword>\\\")<CR><CR>' -\""




# Not needed, needs to happen before screen is spawned anyway:
#[ -e "$SSH_AUTH_SOCK" ] && ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/auth-sock"

#
# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'

basedigit=4
color=3$basedigit
invcolor=4$basedigit
hl_color_of_choice=

for path in \
  $HOME/sdks/arm-cs-tools/bin \
  $HOME/bin; do
  [ ! -d "$path" ] || PATH="$PATH:$path"
done

for file in \
  $HOME/.bash_aliases \
  $HOME/.bash_colors \
  $HOME/.bash_colors_autogen \
  /etc/bash_completion; do
  [ ! -r "$file" ] || source "$file"
done

# Treat screen sessions as login profiles.
#if [[ "$TERM" =~ screen ]] && [ -f ~/.bash_profile ]; then
#  source ~/.bash_profile
#fi

# E.g. ls /tmp/notexist* doesn't expand to "/tmp/notexist*", but to nothing:
#shopt -s nullglob

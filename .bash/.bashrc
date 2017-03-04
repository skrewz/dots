# ~/.bashrc: executed by bash(1) for non-login shells.

# Should get overruled later on:
export PS1='\h:\w\$ '
umask 0002
#export TERM=rxvt
export EDITOR=vim
export HISTSIZE=100000

skrewz_sends_mails_to="skrewz@skrewz.net"
skrewz_sends_mails_as="skrewz+mailteselfbounces@skrewz.net"
alias rootify="echo 'skrewz-alias: Becoming root through su...' >&2; su"

if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

if [ -d "$HOME/.bashrc.d" ]; then
  # Allow more .d directories (or symlinks, ahem) in there:
  for file in "$HOME/.bashrc.d/"*.sh "$HOME/.bashrc.d/"*.d/*.sh; do
    [ -r "$file" ] || continue
    . "$file"
  done
fi
for file in \
  $HOME/.bash/.bash_aliases \
  $HOME/.bash/.bashprompt \
  /etc/bash_completion; do
  [  -r "$file" ] || continue
  . "$file"
done

export HISTTIMEFORMAT='%Y-%m-%d %H:%M:%M: '
export HISTCONTROL=ignorespace
# Line numbers in bash -x output:
export PS4='+${BASH_SOURCE##*/}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'


export LS_OPTIONS='--color=auto'
if [ -e "$HOME/.dircolors" ]; then
  eval "$(dircolors "$HOME/.dircolors")"
else
  eval "$(dircolors)"
fi



# If you don't use this, you'll get annoyed when you accidentally press
# Control-s and your terminal hangs misearably until you press Control-q, or
# something like that.  Anyway. The phenomenon is called XON/XOFF-control.

# And I'm turning it off.
stty -ixon > /dev/null 2>&1


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

export -f print_bash_bt
export PYTHONSTARTUP=~/.pystartup


if [ "rxvt-unicode-256color" = "$TERM" ]; then
  export TERM="rxvt-256color"
fi


trap 'source ~/.bash_colors_autogen' USR1

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
alias s-ssh-add='/usr/bin/ssh-add -t $(($(date --date "$(date --date tomorrow +%Y-%m-%d) 6:00:00" +%s) - $(date +%s))) $HOME/.ssh/id_rsa_private_use'
alias ssh-add='echo "ssh-add (alias): spawning s-ssh-add instead." >&2; s-ssh-add'


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

for path in \
  $HOME/sdks/arm-cs-tools/bin \
  $HOME/repos/projects/shoutcast_ripperscripts \
  $HOME/repos/projects/bin-of-bins/* \
  $HOME/repos/*/bin \
  $HOME/bin; do
  [ ! -d "$path" ] || PATH="$PATH:$path"
done


# Treat screen sessions as login profiles.
#if [[ "$TERM" =~ screen ]] && [ -f ~/.bash_profile ]; then
#  source ~/.bash_profile
#fi

# E.g. ls /tmp/notexist* doesn't expand to "/tmp/notexist*", but to nothing:
#shopt -s nullglob

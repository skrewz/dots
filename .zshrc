# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/repos/dots/ohmyzsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="skrewz"
VIRTUAL_ENV_DISABLE_PROMPT="set to something"

source ~/repos/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM="$HOME/repos/dots/zsh_custom"
SAVEHIST=1000000

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git git-auto-fetch last-working-dir timer colored-man-pages colorize)



source $ZSH/oh-my-zsh.sh


if [[ -d $HOME/bin ]]; then
  export PATH="$HOME/bin:$PATH"
fi
# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export EDITOR='nvim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Prefer readline bindings for word-rubout
stty werase ^= > /dev/null 2>&1

bindkey -v # Vim bindings

# modified vim bindings for Dvorak (and shifted off
# from hjkl to htns, under the index finger):

bindkey -M vicmd 'h' vi-backward-char
bindkey -M vicmd 's' vi-forward-char

() {
   local -a prefix=( '\e'{\[,O} )
   local -a up=( ${^prefix}A '^p' ) down=( ${^prefix}B '^n' )
   local key=
   for key in $up[@]; do
      bindkey -M viins "$key" up-line-or-search
      #bindkey -M viins "$key" history-beginning-search-backward
   done
   for key in $down[@]; do
      bindkey -M viins "$key" down-line-or-search
      #bindkey -M viins "$key" history-beginning-search-forward
   done
}
# From https://github.com/marlonrichert/zsh-autocomplete#first-insert-the-common-substring
# all Tab widgets
zstyle ':autocomplete:*complete*:*' insert-unambiguous yes

# all history widgets
zstyle ':autocomplete:*history*:*' insert-unambiguous yes

# This has a whole zshzle manpage section to itself:
# also consider vi-history-search-backward (/) in vicmd mode
#bindkey -M viins '^r' history-incremental-search-backward

# old habits die hard:
bindkey '\e.' insert-last-word

for sourceable in \
  ~/.bash/.bash_aliases \
  ~/.bash_aliases_local \
  ~/.zshrc_local \
  ; do
  if [ -f "$sourceable" ]; then
    source "$sourceable"
  fi
done


# make bat never use a pager:
export BAT_PAGER=''
alias bat='batcat'
alias cat='bat --pager=None --plain --tabs 0'
alias icat="kitty +kitten icat --align=left"

eval "$(dircolors ~/repos/dots/.dircolors )"
export LS_OPTIONS='--color=auto'
alias ll='exa -lga'
alias l='exa -l'
alias ls='exa'
alias gs='git status'
alias gr='cd "$(git rev-parse --show-toplevel)"'
alias gd='git diff'
# https://opensource.com/article/18/9/tips-productivity-zsh
alias -g G='| grep -i'
alias -g B='& disown; exit'

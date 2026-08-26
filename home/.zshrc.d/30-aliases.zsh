#
# Core shell aliases
#
# This is the surviving third of the 2022 aliases.zsh, which opened with the
# comment "a bunch of hangover stuff from prezto — do I need it?". Answer,
# mostly: no. Dropped wholesale, recorded here so it's clear the removal was
# deliberate rather than an oversight:
#
#   Ruby/Rails    rails c, script/console, thin, mongrel, 10 zeus aliases,
#                 7 rspec/spring aliases, rake db:migrate variants, sgi
#   Tooling gone  sprintly/spb, hpr (hub), todo (NValt), portforward (ipfw,
#                 removed from macOS years ago)
#   Docker        dps/dis/dnuke/dbash and the commented docker-machine and
#                 dinghy archaeology — reinstate from git history if wanted
#   Finder        showFiles/hideFiles toggles
#   brewu         brew update && upgrade && cleanup && doctor
#   TRAPHUP       a SIGHUP trap that re-sourced the alias file
#
# The platform detection the old file used is gone too: this repo is macOS-only,
# so the Linux branch was dead code.
#

# --- process inspection ------------------------------------------------------
alias psa='ps aux'
alias psg='ps aux | grep '

# --- human-readable sizes ----------------------------------------------------
alias df='df -h'
alias du='du -h -d 2'

# --- listing -----------------------------------------------------------------
# eza is installed and is what you'll usually want, but these keep the BSD ls
# behavior the muscle memory expects. Swap to `eza -al --git` if you prefer.
alias ll='ls -alGh'
alias ls='ls -Gh'
alias lsg='ll | grep'
alias lh='ls -alt | head'   # most recently modified

# --- paging ------------------------------------------------------------------
alias less='less -r'        # pass through color escapes
alias l='less'

# --- misc --------------------------------------------------------------------
alias cl='clear'
alias tf='tail -f'
alias gz='tar -zcvf'
alias k9='kill -9'
alias ka9='killall -9'

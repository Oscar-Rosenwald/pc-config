#!/usr/bin/env nu

# Navigation

alias : = cd
alias :d = cd ~/Downloads/
alias :v = enter_vaion
alias :p = enter_private
alias :c = cd ~/cease/
alias :l = cd ~/log-viewer
alias ~~ = enter_home


# Git and friends

alias g = git
alias gs = git status
alias :gup = git-update.sh
def :grm [] { scream { git fm; git pull --rebase origin master } "Git Rebase" }
alias gp = git_push
def gps [] { scream { git_push --simple } "Git Push" }
alias glg = git lg
alias cmt = commit-today.sh
alias j   = jj
alias js  = jj st
alias jl  = jj log -r '::@'
alias jla = jj log -r 'all()'
alias j1  = jj log -n 10
alias jn  = jj new
alias jd  = jj describe
alias jss = jj show -s
alias jsh = jj show
alias jbl = jj bookmark list
alias "jj copy" = jj duplicate
alias "j clone" = jj duplicate
def jgp [...rest] { ^jj git push -b ...$rest }
def jgf [...rest] { ^jj git fetch -b ...$rest }


# Emacs

alias ed = emacs --daemon
def em [ file = "~/Private/org-roam/Things/Things.org" ] {
  job spawn { emacsclient --create-frame $file }
  | ignore
}


# ls

alias la = ls -a
alias ll = ls -l
def lt [] { ls | sort-by modified } 


# Building code

def :mbp [component: string] { scream { make $"build_($component)_protobuf" } "protogen" }
def :mba [] { scream { make build_apis } "APIGen" }
def :mbf [] { scream { make build_frontend } "FEGen" }
def :mbq [] { scream { make build_querygen } "querygen" }
def :mbA [] { scream { make build_audrgen } "audrgen" }
def :mbd [] { scream { make build_dbmodels } "modelgen" }
def gaz  [] { scream { bazel run //:gazelle } "Gazelle" }


# Misc

def claude [] { cowsay "We didn't use to need AI for shit. Do better. AI is killing humanity." | lolcat }
def beep [] { ^play -n synth 0.2 sine 1000 vol 0.2 }
alias pgt = postgrestest
alias gpt = globalprotect launch-ui
alias lg = log-viewer
alias ___ = grep ___
alias b = bat

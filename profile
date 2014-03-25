# LS Alias
alias ls='ls -FG'
alias hgrep='history | grep $1'

# export PATH=~/bin:.rvm/bin:/opt/local/bin:/opt/local/sbin:/Users/rcollins/.gem/ruby/1.8/bin:$PATH
export PATH=/opt/local/bin:/usr/local/sbin:/usr/local/bin:~/bin:.rvm/bin:$PATH


#DEVELOPER SHORTS
alias sc='WTF=true script/server --debugger'
alias nolocal='mv config/yacht/local.yml config/yacht/local.yml.bak'
alias relocal='mv config/yacht/local.yml.bak config/yacht/local.yml'

#RVM Env
alias rvm-doctor='rvm requirements'
alias rvmgu='rvm gemset use'
alias rvmgl='rvm gemset list'
alias rvmgn='rvm gemset name'
alias rvmgc='rvm gemset create'
alias rvmgd='rvm gemset delete'
alias rvmge='rvm gemset empty'


#EDITORS
#export EDITOR="/usr/local/bin/mate -w"
#export EDITOR="/usr/bin/vim"
export EDITOR="/usr/local/bin/atom"

#VIM
# source ~/.vim/vimrc

#GIT FUNCTIONALITY AND HELPERS

  #GIT COMPLETION
  source ~/.git-completion

  #GIT-FLOW COMPLETION
  source ~/.git-flow-completion


# COLOR DEFINITIONS
        RED="\[\033[0;31m\]"
     YELLOW="\[\033[0;33m\]"
 	  GREEN="\[\033[0;32m\]"
       BLUE="\[\033[0;34m\]"
  LIGHT_RED="\[\033[1;31m\]"
LIGHT_GREEN="\[\033[1;32m\]"
      WHITE="\[\033[1;37m\]"
 LIGHT_GRAY="\[\033[0;37m\]"
 COLOR_NONE="\[\e[0m\]"

#  FOR GIT VERSION 1.9.1+
function parse_git_branch {

  git rev-parse --git-dir &> /dev/null
  git_status="$(git status 2> /dev/null)"
  branch_pattern="^On branch ([^${IFS}]*)"
  remote_pattern="Your branch is (.*) of"
  diverge_pattern="Your branch and (.*) have diverged"
  if [[ ! ${git_status}} =~ "working directory clean" ]]; then
    state="${RED}⚡"
  fi
  # add an else if or two here if you want to get more specific
  if [[ ${git_status} =~ ${remote_pattern} ]]; then
    if [[ ${BASH_REMATCH[1]} == "ahead" ]]; then
      remote="${YELLOW}↑"
    else
      remote="${YELLOW}↓"
    fi
  fi
  if [[ ${git_status} =~ ${diverge_pattern} ]]; then
    remote="${YELLOW}↕"
  fi
  if [[ ${git_status} =~ ${branch_pattern} ]]; then
    branch=${BASH_REMATCH[1]}
    echo " (${branch})${remote}${state}"
  fi
}

function prompt_func() {
    previous_return_value=$?;
    # prompt="${TITLEBAR}$BLUE[$RED\w$GREEN$(__git_ps1)$YELLOW$(git_dirty_flag)$BLUE]$COLOR_NONE "
    prompt="${TITLEBAR}${BLUE}[${RED}\w${GREEN}$(parse_git_branch)${BLUE}]${COLOR_NONE} "
    if test $previous_return_value -eq 0
    then
        PS1="${prompt}➔ "
    else
        PS1="${prompt}${RED}➔${COLOR_NONE} "
    fi
}

PROMPT_COMMAND=prompt_func

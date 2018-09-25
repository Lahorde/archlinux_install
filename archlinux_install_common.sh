#!/bin/sh
##################################################################
# This scripts provided comm functions, variables used by
# projects scripts
##################################################################

RED='\e[0;31m'
GREEN='\e[32m'
BOLD='\e[1m'
NORMAL='\e[0m' # Reset all
CONFIRM='[ Y(es)/s(kip)/Q(uit) ]'

function show_text
{
  echo -e "  > "$1"" 
}

function show_error
{
  echo -e "${RED}${BOLD}$1${NORMAL}" 
}

function show_warning
{
  echo -e "${RED}$1${NORMAL}" 
}

function show_main_step
{
  echo -e "${BOLD}${GREEN}$1${NORMAL}" 
}

function confirm_main_step
{
  echo -e "${BOLD}${GREEN}$1 $CONFIRM ${NORMAL}" 
  read -s -n1 confirm

  if [[ ${confirm^^} == "S" ]]
  then
    return 1
  elif [[ ${confirm^^} == "Q" ]]
  then
    end
    exit 1
  fi
}

function run_command 
{
  if [ "$#" -eq 2 ]
  then
    echo -n "  > " 
    eval "echo $2"
  fi
  
  if ! eval "$1" 
  then
    echo "Error when executing $1 - exiting"
    end
    exit 1
  fi
}

function confirm_command 
{
  if [ "$#" -ne 2  ]
  then
    show_error "A command and its description must be given"
    end
    exit 1
  fi

  echo -n "  > " 
  eval "echo -ne "$2""
  echo $CONFIRM
  read -s -n1 confirm

  if [[ ${confirm^^} == "Y" ]]
  then
    if ! eval "$1" 
    then
      show_error "Error when executing $1 - exiting"
      end
      exit 1
    fi
  elif [[ ${confirm^^} == "Q" ]]
  then
    end
    exit 1
  fi
}

function run_command 
{
  if [ "$#" -eq 2 ]
  then
    echo -n "  > " 
    eval "echo -e "$2""
  fi
  
  if ! eval "$1" 
  then
    show_error "Error when executing $1 - exiting"
    end
    exit 1
  fi
}

function get_host_arch 
{
  if cat /proc/device-tree/model 2> /dev/null |grep -qi 'raspberry pi'
  then
    run_command 'res=$(uname -a)' 
    if [[ "$res" =~ ^.*[[:space:]]armv6l[[:space:]].* ]]
    then
      echo 'rpi_armv6'
    elif [[ "$res" =~ ^.*[[:space:]]armv7l[[:space:]].* ]]
    then
      echo 'rpi_armv7'
    elif [[ "$res" =~ ^.*[[:space:]]aarch64[[:space:]].* ]]
    then
      echo'rpi_armv8'
    else
      echo 'na'
    fi
  elif uname -a |grep -q 'x86_64' 
  then
    echo 'x86_64'
  else
    echo 'na'
  fi
}

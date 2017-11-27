#!/bin/sh
##################################################################
# This scripts provided comm functions, variables used by
# projects scripts
##################################################################

RED='\e[0;31m'
GREEN='\e[32m'
BOLD='\e[1m'
NORMAL='\e[0m' # Reset all

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

function run_command 
{
  if [ "$#" -eq 2 ]
  then
    echo -n "  > " 
    eval "echo -e "$2""
  fi
  
  if ! eval "$1" 
  then
    echo "Error when executing $1 - exiting"
    end
    exit 1
  fi
}



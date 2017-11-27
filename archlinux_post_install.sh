#!/bin/sh
##################################################################
# This scripts post installs needed files. It must be run by user.
# It must be run on target system. It cannot be run in a chrooted 
# env because it needs dbus running
##################################################################

source "$(dirname "$0")/archlinux_install_common.sh"
###################################
#  Add here your configuration    #
###################################
DOT_FILES_URL="https://github.com/Lahorde/dotfiles"
AUR_PACKAGES=('hci-attach-rpi3' 'pi-bluetooth')

function end
{
  show_main_step 'end of post install'
}

function install_aur_package
{
  show_text "compile locally $1"
  run_command "wget -P /tmp/ https://aur.archlinux.org/cgit/aur.git/snapshot/$1.tar.gz"
  run_command "tar -C /tmp/ -zxf /tmp/$1.tar.gz"
  run_command "pushd /tmp/$1"
  run_command "makepkg -cs"
  run_command "sudo pacman -U $1*.tar.gz"
  run_command "popd /tmp/$1"
}

INSTALLED_FILES=("$(dirname "$0")/archlinux_install_common.sh" "$(dirname "$0")/archlinux_initial_install.sh" "$0")

show_main_step 'Doing post install - add your dotfiles'

arch=""
if cat /proc/device-tree/model |grep -i "raspberry pi"
then
  show_text 'target is a raspberry'
  run_command 'res=$(uname -a)' 
  if [[ "$res" =~ ^.*[[:space:]]armv6l[[:space:]].* ]]
  then
    arch='rpi_armv6'
  elif [[ "$res" =~ ^.*[[:space:]]armv7l[[:space:]].* ]]
  then
    arch='rpi_armv7'
  elif [[ "$res" =~ ^.*[[:space:]]aarch64[[:space:]].* ]]
  then
    arch='rpi_armv8'
  fi
  show_text "rasperry target architecture is $arch"
fi
  
run_command 'mkdir ~/projects'
run_command 'git clone $DOT_FILES_URL ~/projects/dotfiles' 'Cloning dot files'
run_command '~/projects/dotfiles/install.sh'

if [ -n "$arch" ] && [ ${arch:0:3} == 'rpi' ]
then
  show_main_step 'compile locally some packages for raspberry'
  for package in "${AUR_PACKAGES[@]}" 
  do 
    echo $package
    install_aur_package $package 
  done
fi

show_main_step 'Doing other post install steps...'
run_command 'sudo timedatectl set-ntp true' 'enable ntp synchro'

show_main_step 'Remove scripts from system'
run_command 'for script in "${INSTALLED_FILES[@]}" ; do show_text "removing $script"; sudo rm $script; done;'


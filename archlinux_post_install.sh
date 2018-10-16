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
RPI3_BT_PACKAGES=('hciattach-rpi3' 'pi-bluetooth')
AUR_PACKAGES=('octoprint-venv')
KEYBOARD_LAYOUT='fr'

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
  run_command "sudo pacman -U $1*.tar.xz"
  run_command "popd"
}

INSTALLED_FILES=("$(dirname "$0")/archlinux_install_common.sh" "$(dirname "$0")/archlinux_initial_install.sh" "$0")

show_main_step 'Doing post install - add your dotfiles'

host_arch=$(get_host_arch)
if [ $host_arch == 'na' ]
then
  show_error 'host architecture not handled'
  end
  exit 1
fi
show_text "host architecture is $host_arch"

  
if confirm_main_step 'Add dotfiles' 
then
  run_command 'mkdir -p ~/projects'
  run_command 'git clone $DOT_FILES_URL ~/projects/dotfiles' 'Cloning dot files'
  run_command '~/projects/dotfiles/install.sh'
fi

if cat /proc/device-tree/model 2> /dev/null |grep -i "pi 3"
then
  show_main_step 'enable bluetooth on raspberry 3'
  for package in "${RPI3_BT_PACKAGES[@]}" 
  do 
    install_aur_package "$package" 
  done
  run_command 'sudo gpasswd -a $USER lp' 'add user $USER to lp group'
  run_command 'sudo systemctl enable brcm43438' 'enable brcm43428 service' 
fi 

if [ -n "$host_arch" ] && [ ${host_arch:0:3} == 'rpi' ]
then
  if confirm_main_step 'Add defined AUR packages on raspberry'
  then
    show_main_step 'compile locally some packages for raspberry'
    for package in "${AUR_PACKAGES[@]}" 
    do 
      install_aur_package "$package"
    done
  fi
else
  run_command 'localectl --no-convert set-x11-keymap $KEYBOARD_LAYOUT' 'set X11 keyboard layout'
  if confirm_main_step 'install yaourt'
  then
    run_command 'pushd /tmp'
    run_command 'git clone https://aur.archlinux.org/package-query.git && cd package-query'
    run_command 'makepkg -si && cd ..'
    run_command 'git clone https://aur.archlinux.org/yaourt.git && cd yaourt'
    run_command 'makepkg -si && popd'
  fi
  confirm_command "yaourt -S ${AUR_PACKAGES[@]}"
fi

show_main_step 'Doing other post install steps...'
run_command 'sudo timedatectl set-ntp true' 'enable ntp synchro'

if confirm_main_step 'Remove scripts from system' 
then
  run_command 'for script in "${INSTALLED_FILES[@]}" ; do show_text "removing $script"; sudo rm $script; done;'
fi


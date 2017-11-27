#!/bin/sh
##################################################################
# This scripts post installs needed files. It must be run by user.
# It must be run on target system. It cannot be run in a chrooted 
# env because it needs dbus running
##################################################################

source "$(dirname "$0")/archlinux_install_common.sh"

INSTALLED_FILES=("$(dirname "$0")/archlinux_install_common.sh" "$(dirname "$0")/archlinux_initial_install.sh" "$0")

show_main_step 'Doing post install - add your dotfiles'
run_command 'mkdir ~/projects'
run_command 'git clone https://github.com/Lahorde/dotfiles ~/projects/dotfiles' 'Cloning dot files'
run_command '~/projects/dotfiles/install.sh'

show_main_step 'Doing other post install steps...'
run_command 'sudo timedatectl set-ntp true' 'enable ntp synchro'

show_main_steps 'Remove scripts from system'
run_command 'for script in "${INSTALLED_FILES[@]}" ; do show_text "removing $script"; sudo rm $script; done;'


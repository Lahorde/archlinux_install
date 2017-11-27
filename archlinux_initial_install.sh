#!/bin/sh

source "$(dirname "$0")/archlinux_install_common.sh"
###################################
#  Add here your configuration    #
###################################
KEYMAP=fr
LOCALES=('en_US.UTF-8 UTF-8' 'fr_FR.UTF-8 UTF-8')
LANG='en_US.UTF-8'
DOT_FILES_URL='https://github.com/Lahorde/dotfiles'
declare -A CONFIG_FILES
CONFIG_FILES=(['../config_files/netctl/a4h_creativity_lab_wlan0']='/etc/netctl' \
  ['../config_files/samba/smb.conf']='/etc/samba/' \
)

function end
{
  if [[ $(ls -di) =~ ^2[[:space:]].*$ ]]
  then
    umount /boot  
  fi 
  sync 
}

show_main_step 'Doing initial archlinux installation'

target_arch='default'
if [ $# -eq 1 ]
then
  show_text "Target architecture is $1"
  target_arch="$1"
else
  show_text 'No target architecture specified - default installation will be done'
fi

###################################
#  Prepare chrooting              #
###################################
if ! [[ $(ls -di) =~ ^2[[:space:]].*$ ]] 
then
  run_command 'read resp' 'Do you want to do initial installation in a chrooted environment? \(y\)es / \(n\)o\)?'
  chroot=0
  if [ "$resp" == 'y' ]
  then
    # Do all needed operations before chrooting
    show_main_step 'Prepare chroot environment' 
    show_text 'Copy all config files'
    for config_file in ${!CONFIG_FILES[*]}
    do
      if [ ! -e "./root${CONFIG_FILES[${config_file}]}" ]
      then
        run_command 'sudo mkdir -p "./root${CONFIG_FILES[${config_file}]}"' 'Creating directory "./root${CONFIG_FILES[${config_file}]}"'
      fi 
      run_command 'sudo cp ${config_file} ./root${CONFIG_FILES[${config_file}]}' 'Copying ${config_file} to ./root${CONFIG_FILES[${config_file}]}'
    done 

    run_command 'sudo cp $0 ./root/bin' 'Copying install script to chroot image'
    run_command 'sudo cp "$(dirname "$0")/archlinux_install_common.sh" ./root/bin' 'Copying install script to chroot image'
    run_command 'sudo cp ../archlinux_post_install.sh ./root/bin' 'Copying post-install script to chroot image'

    if [ ${target_arch:0:3} == 'rpi' ]
    then
      show_main_step '\nChrooting into newly created system...'
      if [ "$target_arch" == 'rpi_armv8' ]
      then
        run_command 'sudo update-binfmts --enable qemu-aarch64 > /dev/null'
        run_command 'sudo cp /usr/bin/qemu-aarch64-static root/usr/bin'
      elif [[ "$target_arch" =~ ^rpi_armv[6,7]^ ]]
      then 
        run_command 'sudo update-binfmts --enable qemu-arm'
        run_command 'sudo cp /usr/bin/qemu-arm-static archlinux-rpi/usr/bin'
      fi 
      run_command 'sudo  arch-chroot root/ /bin/archlinux_initial_install.sh $target_arch' 'Chrooting...'
    else
      show_warning "target ${target_arch} not handled"
    fi
    exit 0 
  else
    show_text 'No config file to copy'
  fi 
else 
  show_warning '\n!!!!!!!!!!YOU ARE IN A CHROOTED ENVIRONMENT!!!!!!!!\n'
fi

##########################################################
#  All following commands run in newly created system    #
##########################################################

run_command 'mount /boot' 'Mounting /boot'         

run_command 'passwd' 'Changing root password' 

run_command  'echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf' 'Changing keymap to FR'

run_command 'ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime' 'Set timezone to Paris' 

run_command 'dircolors --print-database > /etc/DIR_COLORS' 'Get colors for ls'

run_command 'read machine_name' 'Please give a machine name :'
run_command 'echo $machine_name > /etc/hostname' 'Set machine name'
run_command 'sed -r -i -e "/127\.0\.0\.1[[:space:]]+localhost\.localdomain[[:space:]]+localhost/s/$/ $machine_name/" /etc/hosts'


run_command 'echo LANG=$LANG  > /etc/locale.conf' 'Set LANG'
run_command 'for loc in "${LOCALES[@]}"; do sed -i -e "s/#$loc/$loc/" /etc/locale.gen ; echo "Set locale $loc"; done;'
run_command 'for loc in "${LOCALES[@]}" ; do echo "$loc" | awk -F "[[:space:]]+" "{file=\"/usr/share/i18n/charmaps/\"\$2\".gz\"; system(\"gunzip --keep \"file)}" ; done;' 'BUG in locale-gen when using QEMU, unzip it manually - refer https://www.reddit.com/r/bashonubuntuonwindows/duplicates/65e36z/psa_localegen_is_bugged_solution_extract_the/' 
run_command 'locale-gen' 'Generating locale' 


run_command 'pacman-key --init' 'Update pacman key'
run_command 'pacman -Syu' 'Updating packages'
run_command 'pacman -S vim python python-pip python2 python2-pip avahi samba tmux wpa_actiond git bluez bluez-utils nss-mdns binutils base-devel distcc alsa-utils xorg-xauth opencv sudo' 'Installing some useful packages...'

run_command 'sed -i "s/#X11Forwarding.*$/X11Forwarding yes/" /etc/ssh/sshd_config' 'Enable X11 forwarding over ssh'
run_command 'sed -i "s/#AllowTcpForwarding.*$/AllowTcpForwarding yes/" /etc/ssh/sshd_config'
run_command 'sed -i "s/#X11UseLocalhost.*$/X11UseLocalhost yes/" /etc/ssh/sshd_config'
run_command 'sed -i "s/#X11DisplayOffset.*$/X11DisplayOffset 10/" /etc/ssh/sshd_config'

run_command 'userdel -r alarm' 'Delete user alarm'

run_command 'read username' 'Please give your user name'
run_command 'useradd -m -G wheel -s /bin/bash $username'
run_command 'passwd $username'
run_command 'sed -i -e "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers' 'allow members of group wheel to execute any command'

run_command 'sed -e "s/^hosts: files mymachines resolve \[!UNAVAIL=return\] dns myhostname$/hosts: files mdns_minimal \[NOTFOUND=return\] dns/" /etc/nsswitch.conf' 'Configure nsswitch.conf for avahi'
run_command 'smbpasswd -a $username' 'add user $username to samba users'

# RPI specific
if [ ${target_arch:0:3} == 'rpi']
then
  show_main_step 'Do Raspberry specific installation'
  run_command 'pacman -S i2c-tools' 'Install Raspberry specific packages'    
  if [[ $target_arch =~ ^rpi_armv[6,7]^ ]]
  then 
    run_command 'pacman -S wiringpi' 'Install Raspberry armv6/v7 specific packages'
  fi
  
  run_command 'echo -e "#Enable I2C\ni2c-dev" >> /etc/modules-load.d/raspberrypi.conf'
  run_command 'echo -e "#Enable SPI\ndtparam=spi=on" >> /boot/config.txt' 'Enable SPI'
  run_command 'echo -e "#Enable onboard PWM for sound\nsnd-bcm2835" >> /etc/modules-load.d/raspberrypi.conf'
  run_command 'echo -e "#Enable onboard PWM for sound\ndtparam=audio=on" >> /boot/config.txt'
  run_command 'echo -e "#Enable SPI\ndtparam=spi=on" >> /boot/config.txt' 'Enable SPI'
  run_command 'echo -e "#Enable camera\nstart_x=1\nMin GPU mem for camera\ngpu_mem=128" >> /boot/config.txt' 'Enable Camera'
  run_command 'echo -e "#Enable camera\nbcm2835-v412 >> /etc/modules-load.d/raspberrypi.conf"' 'Add v4l2 driver for camera' 
fi


show_main_step 'Enable systemd services'
run_command 'systemctl enable netctl-auto@wlan0.service' 'Enable netctl auto connection using wlan0'
run_command 'systemctl enable avahi-daemon.service' 'Enable mdns'
run_command 'systemctl enable smbd'

end

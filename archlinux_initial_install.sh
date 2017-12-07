#!/bin/sh

source "$(dirname "$0")/archlinux_install_common.sh"
###################################
#  Add here your configuration    #
###################################
KEYMAP=fr
LOCALES=('en_US.UTF-8 UTF-8' 'fr_FR.UTF-8 UTF-8')
LANG='en_US.UTF-8'
declare -A CONFIG_FILES
CONFIG_FILES=()

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
if [ $# -ge 1 ]
then
  show_text "Target architecture is $1"
  target_arch="$1"
else
  show_warning 'No target architecture specified'
  end
  exit 1
fi

# In some cases, testing whether we are in chroot with ls -di does not work
# https://unix.stackexchange.com/questions/14345/how-do-i-tell-im-running-in-a-chroot
# give chroot info using an chroot arg
is_chroot=0
if [ $# -eq 2 ] && [ "$2" == 'chroot' ]
then
  is_chroot=1
fi


###################################
#  Prepare chrooting              #
###################################
if [ $is_chroot -eq 0 ]
then
  run_command 'read resp' 'Do you want to do initial installation in a chrooted environment? \(y\)es / \(n\)o\)?'
  if [ "$resp" == 'y' ]
  then
    root_dir='root'
    chroot_cmd='arch_chroot'
    if [ $target_arch == 'x86_64' ]
    then
      root_dir='root.x86_64'
      chroot_cmd="${root_dir}/bin/arch-chroot"
    fi

    # Do all needed operations before chrooting
    show_main_step 'Prepare chroot environment'
    show_text 'Copy all config files'
    for config_file in ${!CONFIG_FILES[*]}
    do
      if [ ! -e "./${root_dir}${CONFIG_FILES[${config_file}]}" ]
      then
        run_command 'sudo mkdir -p "./${root_dir}${CONFIG_FILES[${config_file}]}"' 'Creating directory "./${root_dir}${CONFIG_FILES[${config_file}]}"'
      fi
      run_command 'sudo cp ${config_file} ./${root_dir}${CONFIG_FILES[${config_file}]}' 'Copying ${config_file} to ./${root_dir}${CONFIG_FILES[${config_file}]}'
    done

    run_command 'sudo cp $0 ./${root_dir}/bin' 'Copying install script to chroot image'
    run_command 'sudo cp "$(dirname "$0")/archlinux_install_common.sh" ./${root_dir}/bin' 'Copying install script to chroot image'
    run_command 'sudo cp ../archlinux_post_install.sh ./${root_dir}/bin' 'Copying post-install script to chroot image'

    if [ ${target_arch:0:3} == 'rpi' ]
    then
      show_main_step '\nChrooting into newly created system...'
      if [ "$target_arch" == 'rpi_armv8' ]
      then
        run_command 'sudo update-binfmts --enable qemu-aarch64 > /dev/null'
        run_command 'sudo cp /usr/bin/qemu-aarch64-static ${root_dir}/usr/bin'
      elif [[ "$target_arch" =~ ^rpi_armv[6,7]$ ]]
      then
        run_command 'sudo update-binfmts --enable qemu-arm'
        run_command 'sudo cp /usr/bin/qemu-arm-static ${root_dir}/usr/bin'
      else
        show_warning  "raspberry target $target_arch not handled"
        end
        exit 1
      fi
    elif [ $target_arch == 'x86_64' ]
    then
      show_text "target is $target_arch"
    else
      show_warning "target ${target_arch} not handled"
      end
      exit 1
    fi
    run_command 'sudo  $chroot_cmd ${root_dir}/ /bin/archlinux_initial_install.sh $target_arch chroot' 'Chrooting...'
    end
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
show_main_step 'initialize pacman'
run_command  ' pacman-key --init'                                                        ' Update pacman key'
run_command  ' pacman-key --populate archlinux'
run_command  ' pacman -Syu'                                                              ' Updating packages'
run_command  ' pacman --needed -S sed less awk gzip'                                          ' Installing required packages for install'
if [ "$target_arch" == 'x86_64' ]
then
  show_text 'all pacman mirrors commented in x86_64 image, rank it by their speed'
  run_command  'cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup'
  run_command  'sed -i "s/^#Server/Server/" /etc/pacman.d/mirrorlist.backup'
  run_command  'rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist'
fi

show_main_step 'configuring locales, machine name...'
if [ ${target_arch:0:3} == 'rpi' ]
then
  run_command  ' mount /boot'                                                                                                         ' Mounting /boot'
fi
#run_command  ' passwd'                                                                                                              ' Changing root password'
run_command  ' echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf'                                                                          ' Changing keymap to FR'
run_command  ' ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime'                                                              ' Set timezone to Paris'
run_command  ' dircolors --print-database > /etc/DIR_COLORS'                                                                        ' Get colors for ls'
run_command  ' read machine_name'                                                                                                   ' Please give a machine name :'
run_command  ' echo $machine_name > /etc/hostname'                                                                                  ' Set machine name'
run_command  ' sed -r -i -e "/127\.0\.0\.1[[:space:]]+localhost\.localdomain[[:space:]]+localhost/s/$/ $machine_name/" /etc/hosts'
run_command  ' echo LANG=$LANG  > /etc/locale.conf'                                                                                 ' Set LANG'
run_command  ' for loc in "${LOCALES[@]}"; do sed -i -e "s/#$loc/$loc/" /etc/locale.gen ; echo "Set locale $loc"; done;'
run_command 'for loc in "${LOCALES[@]}" ; do echo "$loc" | awk -F "[[:space:]]+" "{file=\"/usr/share/i18n/charmaps/\"\$2\".gz\"; system(\"gunzip --keep \"file)}" ; done;' 'BUG in locale-gen when using QEMU, unzip it manually - refer https://www.reddit.com/r/bashonubuntuonwindows/duplicates/65e36z/psa_localegen_is_bugged_solution_extract_the/'
run_command 'locale-gen' 'Generating locale'

show_main_step 'handle users'
run_command  'pacman --needed -S sudo'
if [ ${target_arch:0:3} == 'rpi' ]
then
  run_command  ' userdel -r alarm'                                                         ' Delete user alarm'
fi
run_command  ' read username'                                                            ' Please give your user name'
run_command  ' useradd -m -G wheel -s /bin/bash $username'
run_command  ' passwd $username'
run_command  ' sed -i -e "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers'  ' allow members of group wheel to execute any command'
run_command  ' usermod -a -G audio remi'                                                 ' add user $username to group audio'

show_main_step 'install some useful packages with pacman'
run_command 'pacman --needed -S vim openssh python python-pip python2 python2-pip python-numpy python2-numpy avahi samba tmux wpa_actiond git bluez bluez-utils nss-mdns binutils base base-devel parted distcc alsa-utils xorg-xauth opencv wget grub efibootmgr ifconfig'

show_main_step 'configuring ssh'
run_command 'read enable_x11_forward' 'Do you want to enable X11 forwarding? \(y\)es / \(n\)o\)?'
if [ "$enabl_x11_forward" == 'y' ]
then
  run_command 'sed -i "s/#X11Forwarding.*$/X11Forwarding yes/" /etc/ssh/sshd_config' 'Enable X11 forwarding over ssh'
  run_command 'sed -i "s/#AllowTcpForwarding.*$/AllowTcpForwarding yes/" /etc/ssh/sshd_config'
  run_command 'sed -i "s/#X11UseLocalhost.*$/X11UseLocalhost yes/" /etc/ssh/sshd_config'
  run_command 'sed -i "s/#X11DisplayOffset.*$/X11DisplayOffset 10/" /etc/ssh/sshd_config'
fi

show_main_step 'configuring avahi'
run_command 'sed -i "s/^hosts: files mymachines resolve \[!UNAVAIL=return\] dns myhostname$/hosts: files mdns_minimal \[NOTFOUND=return\] dns/" /etc/nsswitch.conf' 'Configure nsswitch.conf for avahi'

show_main_step 'configuring samba'
run_command 'read enable_samba' 'Do you want to configure and enable samba shares? \(y\)es / \(n\)o\)?'
if [ "$enable_samba" == 'y' ]
then
  run_command 'read samba_group' 'please enter a samba group name'
  run_command 'groupadd $samba_group'
  run_command 'usermod -a -G $samba_group $username' 'add $username to group $samba_group'
  run_command 'smbpasswd -a $username' 'add user $username to samba users'
  run_command 'systemctl enable smbd' 'enable samba'
fi

# RPI specific
if [ "${target_arch:0:3}" == 'rpi' ]
then
  show_main_step 'do Raspberry specific installation'
  run_command 'pacman -S i2c-tools' 'Install Raspberry specific packages'
  if [[ $target_arch =~ ^rpi_armv[6,7]^ ]]
  then
    run_command 'pacman -S wiringpi' 'Install Raspberry armv6/v7 specific packages'
  fi

  if [[ $target_arch =~ ^rpi_armv[7,8]^ ]]
  then
    run_command 'pacman -S wiringpi' 'Install bluetooth packages for Raspberry 3'
    run_command 'systemctl enable brcm43438.service' 'enable rpi3 bluetooth service'
    run_command 'rm /etc/udev/rules.d/50-bluetooth-hci-auto-poweron.rules' 'remove out of date bluetooth rule'
  fi

  run_command 'echo -e "#Enable I2C\ni2c-dev" >> /etc/modules-load.d/raspberrypi.conf'
  run_command 'echo -e "#Enable SPI\ndtparam=spi=on" >> /boot/config.txt' 'Enable SPI'
  run_command 'echo -e "#Enable onboard PWM for sound\nsnd-bcm2835" >> /etc/modules-load.d/raspberrypi.conf'
  run_command 'echo -e "#Enable onboard PWM for sound\ndtparam=audio=on" >> /boot/config.txt'
  run_command 'echo -e "#Enable SPI\ndtparam=spi=on" >> /boot/config.txt' 'Enable SPI'
  run_command 'echo -e "#Enable camera\nstart_x=1\nMin GPU mem for camera\ngpu_mem=128" >> /boot/config.txt' 'Enable Camera'
  run_command 'echo -e "#Enable camera\nbcm2835-v412 >> /etc/modules-load.d/raspberrypi.conf"' 'Add v4l2 driver for camera'
else
  show_main_step 'Do non-Raspberry specific installation'
fi

run_command 'sed -i -e "s/^.*AutoEnable=.*/AutoEnable=true/" /etc/bluetooth/main.conf' 'enable automatic bluetooth power-on after boot'

show_main_step 'Enable systemd services'
run_command 'read wifi_connect' 'Do you want to configure and enable wifi connection using wlan0? \(y\)es / \(n\)o\)?'
if [ "$wifi_connect" == 'y' ]
then
  run_command  ' systemctl enable netctl-auto@wlan0.service'  ' Enable netctl auto connection using wlan0'
fi
run_command  ' systemctl enable avahi-daemon.service'       ' Enable mdns'
run_command  ' systemctl enable bluetooth'                  ' enable bluetooth'
run_command  ' systemctl enable sshd'                       ' enable sshd'

show_main_step 'configuring graphic components'
run_command 'read enable_x' 'Do you want to configure and enable X? \(y\)es / \(n\)o\)?'
if [ "$enable_x" == 'y' ]
then
  run_command 'if pacman -Qs netctl > /dev/null ; then pacman -R netctl; fi;' 'remove netctl'
  run_command 'pacman --needed -S networkmanager xorg xorg-twm xterm xorg-xclock mesa-demos xfce4 xfce4-goodies plank accountsservice lightdm-gtk-greeter xorg-fonts-type1 ttf-dejavu artwiz-fonts font-bh-ttf  font-bitstream-speedo gsfonts sdl_ttf ttf-bitstream-vera  ttf-cheapskate ttf-liberation  ttf-freefont ttf-arphic-uming ttf-baekmuk network-manager-applet meld autofs gvfs adobe-source-sans-pro-fonts' 'installing graphic related packages'
run_command  ' systemctl enable NetworkManager'                       ' enable network manager'
fi

show_main_step 'Successful initial install!!!!'
if [ $is_chroot -eq 1 ]
then
  show_warning    'Post install must be done runing archlinux_post_install.sh on target machine'
fi
end

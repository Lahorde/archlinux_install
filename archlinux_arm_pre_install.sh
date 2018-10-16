#!/bin/sh

##################################################################
# This scripts pre installs archlinux system on an arm target. 
# It downloads official arch release for target architecture and
# copies it on a well partitioned disk.
##################################################################

source "$(dirname "$0")/archlinux_install_common.sh"
function usage
{
  echo 'Description : this scripts install arm image to a disk given as argument'
  echo 'From https://elinux.org/ArchLinux_Install_Guide#Flashing_the_Image'
}

# trap ctrl-c and call ctrl_c()
trap end INT


function end 
{
  if [ -n "$system_disk_path" ]
  then
    if mount | grep ${system_disk_path}p1 > /dev/null
    then 
      sudo umount ${system_disk_path}p1
    fi
    if mount | grep ${system_disk_path}p2 > /dev/null
    then 
      sudo umount ${system_disk_path}p2
    fi
    sync  
  fi
}

RO_PARTITION_CMD='+3G
n
p
3

+1,5G
n
p

+2,8G
'

ro_partitions=1

show_main_step "Prepare disk"
run_command 'run_command lsblk' 'First steps : flashing the image :'
run_command 'read system_disk_path' 'Enter device name :'
system_disk_path="/dev/$system_disk_path"
if [ ! -e "${system_disk_path}" ] 
then
  echo 'Bad disk path'
  exit 1
fi 

run_command 'sudo fdisk $system_disk_path <<EOT
o
p
n
p
1

+100M
t
c
n
p
2


w
EOT' 'Creating partitions...'

run_command 'mkdir -p ./build && cd ./build'
run_command  'sudo mkfs.vfat ${system_disk_path}p1' 'Create and mount the FAT filesystem'

[ -d boot ] && sudo rm -rf boot
run_command 'mkdir boot'
run_command 'sudo mount "${system_disk_path}p1" boot'

run_command 'sudo mkfs.ext4 ${system_disk_path}p2' 'Create and mount the ext4 filesystem'
[ -d ./root ] &&  sudo rm -rf root 
run_command 'mkdir root'
run_command "sudo mount ""${system_disk_path}p2 root"

show_main_step 'Download and extract the root filesystem' 
show_text 'Select image type :'
show_text '       ARMv6     version for RPi1 and 0    (1)'
show_text '       ARMv7     version for RPi2/3        (2)'
show_text '       ARMv8 x64 version for RPi2/3        (3)'

read arm_version
if [[ ! $arm_version =~ ^[1-3]+$ ]]
then 
  show_error 'image type not handled'
  end 
  exit 1
fi

arm_target=('rpi_armv6' \
            'rpi_armv7' \
            'rpi_armv8')
arm_urls=('http://os.archlinuxarm.org/os/' \
          'http://os.archlinuxarm.org/os/' \
          'http://os.archlinuxarm.org/os/')
arm_files=('ArchLinuxARM-rpi-latest.tar.gz' \
          'ArchLinuxARM-rpi-2-latest.tar.gz' \
          'ArchLinuxARM-rpi-3-latest.tar.gz')

img_url=${arm_urls[(($arm_version - 1))]}${arm_files[(($arm_version - 1))]}

if ! wget -nc $img_url 
then
  show_error 'Error when getting last image'
  end 
  exit 1
fi

run_command 'sudo bsdtar -xpf  ${arm_files[(($arm_version - 1))]} -C root' 'Extracting archive ${arm_files[(($arm_version - 1))]} ...'
run_command 'sync' 'syncing'
run_command 'sudo mv root/boot/* boot' 'moving boot folder to boot partition'
run_command 'bash ../archlinux_initial_install.sh ${arm_target[(($arm_version - 1))]}'
end

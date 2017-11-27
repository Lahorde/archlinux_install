# Archlinux installation
## Description
Scripts to install a functional arch distribution according to your needs. Two install types are possible :
dev install : no display, 
graphic session
## Prerequisities
### Raspberry
In order to install Arch quickly, we will install distribution in a chrooted environment running on a powerful HOST. 

On host :
    sudo pacman -S binfmt-support qemu-user-static arch-install-scripts
    

# TODO 
remove password from config files
exit from qemu 
virer /etc/install_config_files
    
## References
[Building ArchLinux ARM packages ona a PC using QEMU Chroot](https://github.com/RoEdAl/linux-raspberrypi-wsp/wiki/Building-ArchLinux-ARM-packages-ona-a-PC-using-QEMU-Chroot)
[Archlinux install](https://wiki.archlinux.org/index.php/installation_guide)
[Archlinux install guide for Raspberry](https://elinux.org/ArchLinux_Install_Guide)

# Archlinux installation
## Description
Scripts to install a functional arch distribution according to your needs.
With these scripts Arch can be installed on some arm, x86_64 targets. In order to facilitate and speed up installation it can perform install in a chrooted environment.

## Intallation steps
Three steps are done during installation :

### preinstall : chroot preparation
#### arm targets
Presinstallation done using `archlinux_arm_pre_install.sh`
It partition disks, download target image file, mounts `/root` `/boot`

#### x86_64
Preinstall must be done manually. All steps from a host linux machine are described [in arch wiki](https://wiki.archlinux.org/index.php/Install_from_existing_Linux#Method_A:_Using_the_bootstrap_image_.28recommended.29)

### initial install
During this step, system, network is configured, some useful packages are installed.
This step is done using `archlinux_initial_install.sh target_arch`. 
Configuration (language, configuration files ... ) must be set in script head according to your needs. 
This step can either be run in a chrooted env or on target system.

### post install
During this step, additional install configuration is done. In chrooted environment, DBUS is not present. So, in this step, done with `archlinux_post_install.sh` must be done in target environment.
    
## References
[Building ArchLinux ARM packages ona a PC using QEMU Chroot](https://github.com/RoEdAl/linux-raspberrypi-wsp/wiki/Building-ArchLinux-ARM-packages-ona-a-PC-using-QEMU-Chroot)
[Archlinux install](https://wiki.archlinux.org/index.php/installation_guide)
[Archlinux install from existing linux](https://wiki.archlinux.org/index.php/Install_from_existing_Linux)
[Archlinux install guide for Raspberry](https://elinux.org/ArchLinux_Install_Guide)

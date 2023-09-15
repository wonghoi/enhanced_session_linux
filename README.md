# enhanced_session_linux
Windows Guest on Hyper-V works out of the box with sound, but not for Linux.
This script sets up the Ubuntu guest for similar out of the box experience

Blog post explaining the science of this script so you can adapt if dependencies change:

[Getting sound to work with Ubuntu VM guests on Hyper-V](https://wonghoi.humgar.com/blog/2023/09/13/getting-sound-to-work-ubuntu-vm-guests-for-hyper-v/)

I confirmed that it works for a fresh install of Ubuntu 23.04 with Cinnamon VM
as of 2023-09-14, specifically on Ubuntu Cinnamon Remix.

## Prerequisites on Windows (Hyper-V Host) side
You need to enable Hyper-V vsocket **for the specific** virtual machine first.
To do so, open Powershell with **administrative rights** and enter this:
```
Set-VM {your VM's name} -EnhancedSessionTransportType HvSocket
```
Replace {your VM's name} with the name you gave to the VM in Hyper-V.
Then **reboot** the Windows (host) computer.

## One-liner if you trust me
```
wget https://raw.githubusercontent.com/wonghoi/enhanced_session_linux/main/setup_enhanced_session.sh -O - | sh
```

Otherwise inspect the code and its dependencies for shenanigans, chmod +x to make the downloaded file executable, and run it

## Intermediary files created
These temporary files/folders are created and destroyed in the process. Make sure nothing gets in its way.
```
~/pulseaudio-module-xrdp 
~/pulseaudio.src 
~/linux-vm-tools;
~/.config/autostart/startonce.desktop
```

## Ubuntu specific lines used in this script
This section provides hints for those who want to adapt this script for different setups

### apt package manager (Debian based)
Ubuntu is Debian based, which uses apt. You'll need to adapt the apt with pacman if you use arch from linux-vm-tools.

### linux-vm-tools
The line
```
wget https://raw.githubusercontent.com/Hinara/linux-vm-tools/ubuntu20-04/ubuntu/22.04/install.sh
```
pulls the version specific to Ubuntu 22.04. They also support arch Linux.

You can go to 
```
https://github.com/Hinara/linux-vm-tools
```
browse for the correct script and replace the instances of install.sh with the intended script (or just rename the downloaded script for another architecture to install.sh)

### Run once on next login/boot
The blob of code containing
'''
[Desktop Entry]
'''
is basically equivalent to creating an icon in the user's start menu folder in Windows except it's for Gnome, and make the icon self-destruct after launch.

If you don't have gnome-terminal, yet you use a XDG desktop specs compatible graphical desktop (aka the syntax above applies), you can replace gnome-terminal  with the GUI terminal you have.

Basically it's just an idea of running a command like ~/linux-vm-tools/install.h once after reboot and clean up any scaffolding after the run.

It's an overly complicated manuever that most people don't want to invest their time to research. If you are fine with manual work rebooting and restarting ~/linux-vm-tools/install.sh the second time. You can simply skip this and delete the files mentioned in the "Intermediary files created" section above after you are done with this script.

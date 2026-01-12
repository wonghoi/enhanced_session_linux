# enhanced_session_linux

Windows Guest on Hyper-V works out of the box with sound, but not for Linux.
This script sets up the Ubuntu guest for similar out of the box experience

Blog post explaining the science of this script so you can adapt if dependencies change:

[Getting sound to work with Ubuntu VM guests on Hyper-V](https://wonghoi.humgar.com/blog/2023/09/13/getting-sound-to-work-ubuntu-vm-guests-for-hyper-v/)

I confirmed that it works for a fresh install of Ubuntu 23.04 with Cinnamon VM
as of 2023-09-14, specifically on Ubuntu Cinnamon Remix.

### Things you need to understand

Typical requirements

- Desktop must be set to X11 (or all hell breaks loose)
- Post-reboot cleanup depends on XDG-based desktops (GNOME, KDE Plasma, XFCE, Cinnamon, MATE, Unity)

Side effects

- pipewire will be removed replaced with pulseaudio (since xrdp only work with pulseaudio)
- xrdp will be installed (obviously) which might interfere with other Remote Desktop mechanisms like krdp
- gnome-terminal will be installed (so I have a known terminal to run post-reboot scripts)

## How this works

TLDR: 

```
Enhanced Session ~ RDP /w audio = xrdp <- pulseaudio-module_xrdp <- pulseaudio
```

VMware and Virtualbox provide guest VM drivers for goodies like sound.
Hyper-V on the other hand relies on RDP (Remote Desktop / Terminal Protocol)
to do all the heavy lifting. 

Hyper-V enhanced session is basically tunneling through RDP (using vsock to 
avoid the overhead of network traffic), so the guest OS has to natively 
support modern RDP (Windows 8.1 and after). 

For Linux guests, there's a stop-gap (riddled with quirks) RDP solution
called xrdp which is tied to X11.

xrdp is not tightly integrated to the shell like Windows' RDP (or GNOME Remote Desktop / krdp). 
There's a minimal Windows-like session talking to the RDP client through sesman
and it launches VNC or X11(Xorg) client on it. Your RDP login only goes to the minimal
Windows-like session and you have to enter the credentials again in the xrdp's 
login dialog box for the desktop streaming (VNC/X11) clients. 

The main reason for this script is that xrdp only works properly with pulseaudio
with [pulseaudio-module-xrdp](https://github.com/neutrinolabs/pulseaudio-module-xrdp)
to redirect the pulseaudio on the Linux to the xrdp session, yet neutrinolabs,
despite they had xdrp on package managers, do not have pulseaudio-module-xrdp and
it's a colossal pain in the butt to compile it without errors if you don't have 
the pre-req set up right.

The main job of [linux-vm-tools](https://github.com/Hinara/linux-vm-tools)
called by this script is to add a bunch of vsock config lines in xrdp and 
setup hv_sock in linux, and fix up the scripts to launch the X11 session
for GNOME (works for Debian despite it's intended for and named as Ubuntu).

## Known linux distro releases that doesn't work with this script out of the box

Ubuntu 25.10 comes with GNOME 49 by default. 
GNOME 49 disabled X11 and used Wayland by default. 
Moving on, X11 will be gone since GNOME 50, which means it's not just Ubuntu,
many modern linux distros will ship without an X11.

xrdp requires X11 to work. So far I've yet to see X11 work on Wayland.

GNOME 49 uses freerdp under the hood but haven't supported vsocks yet.
For now you have to live with enabling network communication with the VM Guest
and use regular RDP (mstsc) to connect to the VM. You still need pipewire
to get sound in RDP:

```
sudo apt install pipewire
```

I tried pulseaudio and it worked for GNOME Desktop too. 

As of 2026 we are in a limbo because GNOME 49+ disabled X11,
which is required to make xrdp the only RDP with vsocks needed
for Enhanced Session, work yet GNOME 49+'s better RDP is not vsocks-ready.
This means more and more new Linux distros out of the box won't work with 
Enhanced Session without much wrestling after installation.

DO NOT ATTEMPT to use this script if your system's Desktop Environment (DE)
is not currently configured to boot into X11 (which is the case with new distros that boots you into Wayland out of the box) as doing so will break your desktop and boot you into a text prompt. 

`linux-vm-tools` uses PKLA to suppress colord (color depth changes)'s auhentication nag. Since PKLA stopped working (will be ignored) since [Ubuntu 23.10](https://c-nergy.be/blog/?p=19242),
[the nag might come back](https://www.reddit.com/r/Ubuntu/comments/15stmwn/how_do_i_suppress_authentication_is_required_to/) 
and you'll have to rewrite the policies in Javascript which is the new format.
I rarely muck with color depths, so I'll wait until I needed it to update this script

If you want to use GNOME 49 and on, I recommend sticking to the modern
GNOME Remote Desktop that's tightly integrated with GNOME and live with
the network protocol overhead.

Cinnamon (based on GNOME 3) still supports X11 (they are still experimenting with Wayland) so xrdp works with it. If you use Linux Mint, UCR (Ubuntu Cinnamon Remix),
or Debian with Cinnamon chosen as the only Desktop Environment in the installer,
you will get X11 out of the box so xrdp and this script would work.

I also tried KDE Plasma 6. By default it's set to Wayland. Please change the Display Manager to X11 (at the bottom of the graphical login) before running my script.

## Prerequisites on Windows (Hyper-V Host) side

You need to enable Hyper-V vsocket **for the specific** virtual machine first.
To do so, open Powershell with **administrative rights** and enter this:

```
Set-VM {your VM's name} -EnhancedSessionTransportType HvSocket
```

Replace {your VM's name} with the name you gave to the VM in Hyper-V.

Changes are not reflected until the Hyper-V's core is restarted. 
The easiest way is to **Reboot** the Windows (host) computer,
but you can just restart Hyper-V Host Compute Service (vmcompute) services
through services.msc or run this line in **Powershell**

```
Restart-Service -Name vmcompute -Force
```

## One-liner if you trust me

```
wget https://raw.githubusercontent.com/wonghoi/enhanced_session_linux/main/setup_enhanced_session.sh -O - | sh
```

Otherwise inspect the code and its dependencies for shenanigans, `chmod +x` to make the downloaded file executable, and run it

## Intermediary files created

These temporary files/folders are created and destroyed in the process. Make sure nothing gets in their way.

```
~/pulseaudio-module-xrdp 
~/pulseaudio.src 
~/linux-vm-tools;
~/.config/autostart/startonce.desktop
```

## Ubuntu specific lines used in this script

This section provides hints for those who want to adapt this script for different setups

### Depends on systemd (systemctl)

Not just my code starting pulseaudio, but linux-vm-tool uses it as well.
Ubuntu defaults to systemd for now

### apt package manager (Debian based)

Ubuntu is Debian based, which uses apt. You'll need to adapt the apt with pacman if you use arch from linux-vm-tools.

### linux-vm-tools

The line

```
wget https://raw.githubusercontent.com/Hinara/linux-vm-tools/refs/heads/master/ubuntu/24.04/install.sh
```

pulls the version specific to Ubuntu 22.04. I diffed the install.h in /24.04 against /22.04 and realized
the only change is making the `cat` output file redirection more robust by making sure the output folder already exist

You can go to 

```
https://github.com/Hinara/linux-vm-tools
```

browse for the correct script and replace the instances of install.sh with the intended script (or just rename the downloaded script for another architecture to install.sh)

`linux-tools-virtual` and `linux-cloud-tools-virtual` is Ubuntu specific. 
Debian doesn't need this as the elements needed are already installed elsewhere like `linux-tools-common` and `linux-tools-generic`, 
so you can ignore the apt error messages trying to find these packages non-existent in Debian. 

### Run once on next login/boot

The blob of code containing
'''
[Desktop Entry]
'''
is basically equivalent to creating an icon in the user's start menu folder in Windows except it's for Gnome, 
and make the icon self-destruct after launch.
The format uses XDG desktop standard.

I installed gnome-terminal to run the shell script instead of guessing what graphical terminals are installed. 

Basically it's just running a command like `~/linux-vm-tools/install.sh` once again after reboot (as required by linux-vm-tools) 
and clean up any scaffolding after the run.

If you are not using an XDG desktop, you can delete (or ignore) anything after the line `sudo ./install.sh`
and manually re-run `sudo ./install.sh` after reboot and delete the files mentioned in the "Intermediary files created" 
section.

### Tested non-Ubuntu distros

- **PopOS**: No go. Gnome crashes when accessed through xrdp. (pop-os_22.04_amd64_intel_34)
- **MX Linux**: No go. It's stuck at with a blank screen after xrdp's sesman login (MX-23_x64)
- **Debian**: magically it worked with sound in a few desktop envrionments before even running a second pass of ~/linux-vm-tools/install.sh. I had to make a lot of change to the robustness of this code to accomodate it
- **Lubuntu**: This one requires source repo to be enabled or else it will choke install_pulseaudio_sources_apt_wrapper.sh and the script moves on silently, leaving sound not working. See the deprecated section about it on my blog

I'm not going to waste my time hacking the distros that do not jive with xrdp at all since Ubuntu/Debian proved that these can be fixed on the linux's end. It's not even a PulseAudio problem (purely xrdp hell) so although my code might accommodate MX Linux, know that out of the box it doesn't work as of 2023-09-15.
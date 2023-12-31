# This script works on Ubuntu 23.04 with Cinnamon as of 2023-09-14
# on freshly installed system.
#
# This script (along with the core dependency in linux-vm-tools), uses
# systemctl which requires systemd.
#
# This script creates the following intermediaries
# ~/pulseaudio-module-xrdp 
# ~/pulseaudio.src 
# ~/linux-vm-tools;
# ~/.config/autostart/startonce.desktop
# then deletes them. Make sure you don't have anything you want to keep named
# as such
#
# This script will force install gnome-terminal
# If you hate its guts, you can do a "sudo apt purge gnome-terminal" later
#
# The VM will shutdown after everything is done.
# I chose to not reboot because I noticed if I reboot too fast
# the Enhanced Session is not ready yet so it needs to be rebooted again
# This quirk does not happen if I simply make you turn the VM on yourself
#
# ON THE WINDOWS SIDE (Hyper-V Host)
# ==================================
# On Host's Powershell, "Set-VM {your VM's name} -EnhancedSessionTransportType HvSocket" AND reboot
#
# Hint for adapting it to other distributions
# ===========================================
# Replace gnome-terminal with graphical emulator that's available in your setup
#
# If you don't use Gnome-based desktop or XDG (base directory specs) compliant,
# you can skip the long 'ecoh -e ...' line at the end that creates the autostart
# icon and just manually reboot and run the ~/linux-vm-tools/install.sh again
# then reboot and clean up the temporary/intermediary folders/files mentioned
# above

if [ $(ps --no-headers -o comm 1) != "systemd" ]; then
	echo "This script depends on systemd (systemctl)"
	echo "If you are using MX Linux, you can switch to systemd by 'sudo apt install systemd-sysv'"
	exit 1
fi

# Change audio server in Ubuntu
sudo apt -y update
sudo apt -y purge pipewire
sudo apt -y install pulseaudio pavucontrol xrdp
systemctl --user enable --now pulseaudio.service pulseaudio.socket

# [Optional] check if PulseAudio was installed correctly
pactl info

# Build pulseaudio-module-xrdp and install the kernel modules
# Stick with official instructions which assumes home folder
cd ~
sudo apt -y install build-essential dpkg-dev libpulse-dev git autoconf libtool
git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
cd pulseaudio-module-xrdp
./scripts/install_pulseaudio_sources_apt_wrapper.sh
./bootstrap && ./configure PULSE_DIR=$HOME/pulseaudio.src
make
sudo make install

# [Optional] check if pulseaudio-module-xrdp was installed correctly
ls $(pkg-config --variable=modlibexecdir libpulse) | grep xrdp

# Install linux-vm-tools which enables Enhanced Session
# Give linux-vm-tools its own folder to avoid confusion
mkdir -p ~/linux-vm-tools 
cd ~/linux-vm-tools 
wget https://raw.githubusercontent.com/Hinara/linux-vm-tools/ubuntu20-04/ubuntu/22.04/install.sh
sudo chmod +x install.sh
sudo ./install.sh

# The last 2 lines of screen output of install.sh tells you to reboot and run this again
# This is automated below by making a icon in Gnome desktop's autostart folder
# that will self-destruct after first launch
#
# Turns out PopOS and debian do not have autostart folder created by default
# but they will honor it if created
mkdir -p ~/.config/autostart/

RUN_ONCE_ICON_FILE=~/.config/autostart/startonce.desktop

# Stopped autodetecting as it's messy to manage different command switches
# Force install gnome-terminal for consistency
sudo apt -y install gnome-terminal

cat > ${RUN_ONCE_ICON_FILE} <<EOF
[Desktop Entry]
Type=Application
Name=startonce.desktop
Exec=gnome-terminal -- sh -c 'sudo ~/linux-vm-tools/install.sh && rm -rf ~/pulseaudio-module-xrdp ~/pulseaudio.src ~/linux-vm-tools ${RUN_ONCE_ICON_FILE} && sudo init 0;\$SHELL'
EOF

sudo reboot


#!/usr/bin/env bash
# Ubuntu counterpart to fedora_setup.sh. Run with sudo from your desktop session.

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo." >&2
    exit 1
fi

# The user who invoked sudo (gsettings changes apply to them, not root)
ACTUAL_USER=${SUDO_USER:?Run with sudo from a regular user account}
ACTUAL_UID=$(id -u "$ACTUAL_USER")

# gsettings needs the user's session D-Bus when run via sudo
user_gsettings() {
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$ACTUAL_UID/bus" gsettings "$@"
}


# System Upgrade
apt update
apt full-upgrade -y


# # System Config
# # Optimize APT. APT has no fastest-mirror or parallel-download settings like DNF;
# # it already downloads from different hosts in parallel.
# # Default Yes
# echo 'APT::Get::Assume-Yes "true";' | tee /etc/apt/apt.conf.d/99assume-yes > /dev/null
# # Retry flaky downloads
# echo 'Acquire::Retries "3";' | tee /etc/apt/apt.conf.d/99retries > /dev/null

# Add Flathub (Ubuntu ships Snap by default, not Flatpak)
apt install -y flatpak gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak repair
flatpak update -y

# Check and apply firmware updates to improve hardware compatibility and performance
apt install -y fwupd
fwupdmgr refresh --force
fwupdmgr get-updates
fwupdmgr update -y

# # Enable universe/multiverse (Ubuntu's equivalent of RPM Fusion) and 32-bit packages (needed by Steam)
# apt install -y software-properties-common
# add-apt-repository -y universe
# add-apt-repository -y multiverse
# dpkg --add-architecture i386
# apt update

# Install multimedia codecs to enhance multimedia capabilities
# Pre-accept the Microsoft core fonts EULA so the install doesn't stop to ask
# echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections
# apt install -y ubuntu-restricted-extras ffmpeg \
#     gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav

# Install Hardware Accelerated Codecs for AMD GPUs. This improves video playback and encoding performance on systems with AMD graphics.
# Unlike Fedora, Ubuntu's Mesa VA-API driver already includes H.264/H.265, so no "freeworld" swap is needed.
apt install -y mesa-va-drivers vainfo

# Install virtualization tools to enable virtual machines and containerization
apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virt-manager bridge-utils
usermod -aG libvirt,kvm "$ACTUAL_USER"

# Configure power settings to prevent system sleep and hibernation
user_gsettings set org.gnome.desktop.session idle-delay 0
user_gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
user_gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
user_gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
user_gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
user_gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'

# Update all Flatpak applications alongside the system upgrade (Flatpak apps are not touched by apt upgrade)
if command -v flatpak &>/dev/null; then
    flatpak update -y
fi


# App Install
# Install essential applications
apt install -y btop curl
# fastfetch is only in the official archive from Ubuntu 25.04; fall back to its PPA on older releases
apt install -y fastfetch 

# Install Internet & Communication applications
flatpak install -y flathub com.brave.Browser
flatpak install -y flathub app.zen_browser.zen

# Install Office Productivity applications
flatpak install -y flathub org.onlyoffice.desktopeditors
flatpak install -y flathub md.obsidian.Obsidian

# Install Coding and DevOps applications
# apt install -y wget gpg apt-transport-https
# wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg --yes
# echo -e "Types: deb
# URIs: https://packages.microsoft.com/repos/code
# Suites: stable
# Components: main
# Architectures: amd64,arm64,armhf
# Signed-By: /usr/share/keyrings/microsoft.gpg" | tee /etc/apt/sources.list.d/vscode.sources > /dev/null
# # Stop the code package from adding a duplicate repo entry
# echo "code code/add-microsoft-repo boolean false" | debconf-set-selections
# apt update
# apt install -y code

# Install Gaming & Emulation applications
apt install -y steam-installer
# Ubuntu's lutris package lags well behind upstream, so use the Flatpak
flatpak install -y flathub net.lutris.Lutris
flatpak install -y flathub com.heroicgameslauncher.hgl

# Install Remote Networking applications
flatpak install -y flathub com.protonvpn.www

# Install System Tools applications
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.usebottles.bottles


# Customization
# A flat colorful design icon theme for linux desktops
apt install -y papirus-icon-theme
user_gsettings set org.gnome.desktop.interface icon-theme "Papirus"


echo "Setup complete. Reboot to apply all changes (group membership, firmware, drivers)."

#!/usr/bin/env bash
# Run with sudo from your desktop session.

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
dnf upgrade -y


# System Config
# Optimize DNF package manager for faster downloads and efficient updates
dnf -y install dnf-plugins-core
# Max Parallel Downloads
echo "max_parallel_downloads=10" | tee -a /etc/dnf/dnf.conf > /dev/null
# Select Fastest Mirror
echo "fastestmirror=True" | tee -a /etc/dnf/dnf.conf > /dev/null
# Default Yes
echo "defaultyes=True" | tee -a /etc/dnf/dnf.conf > /dev/null

# Replace Fedora Flatpak Repo with Flathub for better package management and apps stability
dnf install -y flatpak
flatpak remote-delete fedora --force || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak repair
flatpak update -y

# Check and apply firmware updates to improve hardware compatibility and performance
fwupdmgr refresh --force
fwupdmgr get-updates
fwupdmgr update -y

# Enable RPM Fusion repositories to access additional software packages and codecs
dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf group install core -y

# Install multimedia codecs to enhance multimedia capabilities
dnf swap ffmpeg-free ffmpeg --allowerasing -y
dnf group install multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf group install sound-and-video -y

# Install Hardware Accelerated Codecs for AMD GPUs. This improves video playback and encoding performance on systems with AMD graphics.
# Note: on some AMD GPUs the freeworld VA-API drivers can cause a performance regression in games. If you notice lower FPS afterwards, revert with:
#   sudo dnf swap mesa-va-drivers-freeworld mesa-va-drivers -y && sudo dnf swap mesa-vdpau-drivers-freeworld mesa-vdpau-drivers -y
dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y

# Install virtualization tools to enable virtual machines and containerization
dnf install -y @virtualization

# Configure power settings to prevent system sleep and hibernation
user_gsettings set org.gnome.desktop.session idle-delay 0
user_gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
user_gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
user_gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
user_gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
user_gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'

# Update all Flatpak applications alongside the system upgrade (Flatpak apps are not touched by dnf upgrade)
if command -v flatpak &>/dev/null; then
    flatpak update -y
fi


# App Install
# Install essential applications
dnf install -y btop fastfetch curl

# Install Internet & Communication applications
flatpak install -y flathub com.brave.Browser
flatpak install -y flathub app.zen_browser.zen

# Install Office Productivity applications
flatpak install -y flathub org.onlyoffice.desktopeditors
flatpak install -y flathub md.obsidian.Obsidian

# Install Coding and DevOps applications
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf check-update
dnf install -y code

# Install Gaming & Emulation applications
dnf install -y steam
dnf install -y lutris
flatpak install -y flathub com.heroicgameslauncher.hgl

# Install Remote Networking applications
flatpak install -y flathub com.protonvpn.www

# Install System Tools applications
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub com.usebottles.bottles


# Customization
# A flat colorful design icon theme for linux desktops
dnf install -y papirus-icon-theme
user_gsettings set org.gnome.desktop.interface icon-theme "Papirus"


# Custom Script
# Custom user-defined commands



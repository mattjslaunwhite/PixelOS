#!/bin/bash
# A Grand Tea-Party Script for a Fresh Fedora 44 KDE!

echo "Oh my ears and whiskers! We are tumbling down the rabbit hole to build PixelOS 1.27!"

# 1. Prepare the little pockets and folders
echo "Creating cozy little burrows for your files..."
mkdir -p ~/pixelos/images
mkdir -p ~/Applications
mkdir -p ~/.local/share/applications

# 2. Fetch the magic looking-glass artifacts from GitHub
echo "Catching files from the magic GitHub tree..."
# We will use the /tmp directory so we don't leave a mess for the White Rabbit!
git clone https://github.com/mattjslaunwhite/PixelOS.git /tmp/pixelos_repo
cp -r /tmp/pixelos_repo/* ~/pixelos/images/ 2>/dev/null
chmod -R 755 ~/pixelos

# 3. Enable the extra magical repositories
echo "Painting the roses red with new repositories for codecs and browsers..."
# Fetching RPM Fusion for the full media codecs
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Fetching the Brave Browser map
sudo dnf install -y dnf5-command\(config-manager\)
sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

# 4. Drink the shrinking potion for media codecs
echo "Drinking the potion to understand all the moving pictures and sounds..."
sudo dnf upgrade -y --refresh
# Swap out the Queen's limited ffmpeg for the proper, full-sized one
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf group upgrade -y --with-optional Multimedia
sudo dnf install -y gstreamer1-plugin-openh264 mozilla-openh264 gstreamer1-plugins-{bad-\*,good-\*,base} lame\* ffmpeg ffmpeg-libs

# 5. Invite the guests: VLC, Brave, and Wireshark
echo "Inviting VLC, Brave, and the Packet-Sniffer to the tea party..."
sudo dnf install -y vlc brave-browser wireshark wireshark-qt curl wget

# To let Wireshark capture packets, you must have the Queen's permission!
echo "Granting you permission to peer into the network traffic..."
sudo usermod -aG wireshark $USER

# 6. The Grand Masquerade: PixelOS 1.27 Branding
echo "Eating the 'Drink Me' cake to become PixelOS 1.27..."
sudo hostnamectl set-hostname pixelos

sudo cp /etc/os-release /etc/os-release.bak
sudo sed -i 's/^NAME=.*/NAME="PixelOS"/' /etc/os-release
sudo sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="PixelOS 1.27 by Magic goat studio"/' /etc/os-release
sudo sed -i 's/^ID=.*/ID="pixelos"/' /etc/os-release

if grep -q "^VERSION=" /etc/os-release; then
    sudo sed -i 's/^VERSION=.*/VERSION="1.27"/' /etc/os-release
else
    echo 'VERSION="1.27"' | sudo tee -a /etc/os-release > /dev/null
fi

if grep -q "^VERSION_ID=" /etc/os-release; then
    sudo sed -i 's/^VERSION_ID=.*/VERSION_ID="1.27"/' /etc/os-release
else
    echo 'VERSION_ID="1.27"' | sudo tee -a /etc/os-release > /dev/null
fi

if grep -q "^GRUB_DISTRIBUTOR=" /etc/default/grub; then
    sudo sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="PixelOS 1.27"/' /etc/default/grub
else
    echo 'GRUB_DISTRIBUTOR="PixelOS 1.27"' | sudo tee -a /etc/default/grub > /dev/null
fi
echo "Stirring the teacup to apply the GRUB changes..."
sudo grub2-mkconfig -o /boot/grub2/grub.cfg

# 7. Hang the Looking-Glass Paintings (Wallpaper & Splash)
echo "Hanging the new wallpaper and painting the boot splash..."

# Apply the KDE Wallpaper magically using plasma scripting
if command -v plasma-apply-wallpaperimage &> /dev/null; then
    plasma-apply-wallpaperimage ~/pixelos/images/wallpaper.png
fi

# Build the custom Plymouth Splash
THEME_DIR="/usr/share/plymouth/themes/pixelos"
sudo mkdir -p "$THEME_DIR"
sudo cp -r /usr/share/plymouth/themes/spinner/* "$THEME_DIR"/
sudo mv "$THEME_DIR"/spinner.plymouth "$THEME_DIR"/pixelos.plymouth
sudo sed -i 's/Name=Spinner/Name=PixelOS/g' "$THEME_DIR"/pixelos.plymouth
sudo sed -i 's/spinner/pixelos/g' "$THEME_DIR"/pixelos.plymouth

# Place your custom bootsplash.png over the old watermarks
if [ -f ~/pixelos/images/bootsplash.png ]; then
    sudo cp ~/pixelos/images/bootsplash.png "$THEME_DIR"/watermark.png
    sudo cp ~/pixelos/images/bootsplash.png "$THEME_DIR"/bgrt-fallback.png
fi

# Seal the magic into the initramfs
sudo plymouth-set-default-theme -R pixelos

# 8. Invite the Clever Language Models
echo "Inviting the clever models to the party..."
cd ~/Applications

# LM Studio AppImage
echo "Fetching LM Studio..."
wget -q --show-progress "https://lmstudio.ai/download/latest/linux/x64?format=AppImage" -O LM_Studio.AppImage
chmod +x LM_Studio.AppImage

# Painting a little desktop shortcut for LM Studio
cat <<EOF > ~/.local/share/applications/lm-studio.desktop
[Desktop Entry]
Name=LM Studio
Exec=$HOME/Applications/LM_Studio.AppImage --no-sandbox
Icon=utilities-terminal
Type=Application
Categories=Development;Science;
Comment=Chat with local language models
Terminal=false
EOF
update-desktop-database ~/.local/share/applications &> /dev/null || true

# AnythingLLM Installer
echo "Asking the Cheshire Cat for AnythingLLM..."
curl -fsSL https://cdn.anythingllm.com/latest/installer.sh -o anything_installer.sh
chmod +x anything_installer.sh
./anything_installer.sh

echo "Curiouser and curiouser! Your looking-glass transformation is entirely complete. Simply restart the machine so all the magic settles into place!"

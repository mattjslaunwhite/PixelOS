#!/bin/bash
# A Grand Tea-Party Script for a Fresh Fedora 44 KDE!

echo "Oh my ears and whiskers! We are tumbling down the rabbit hole to build PixelOS 1.27!"

# 1. Ask for the Queen's permission (sudo) upfront
echo "Drink this little potion so you have the authority of the Queen of Hearts..."
sudo -v

# Keep the sudo magic alive in the background while the script runs!
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# 2. Prepare the little pockets and folders
echo "Creating cozy little burrows for your files..."
mkdir -p ~/pixelos/images
mkdir -p ~/Applications
mkdir -p ~/.local/share/applications

# 3. Fetch the magic looking-glass artifacts from GitHub
echo "Catching files from the magic GitHub tree..."
rm -rf /tmp/pixelos_repo # Sweeping the floor just in case!
git clone https://github.com/mattjslaunwhite/PixelOS.git /tmp/pixelos_repo
cp -r /tmp/pixelos_repo/* ~/pixelos/images/ 2>/dev/null
chmod -R 755 ~/pixelos

# 4. Enable the extra magical repositories
echo "Painting the roses red with new repositories for codecs and browsers..."
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sudo dnf install -y dnf5-command\(config-manager\)
sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

# 5. Drink the shrinking potion for media codecs
echo "Drinking the potion to understand all the moving pictures and sounds..."
sudo dnf upgrade -y --refresh
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf group upgrade -y --with-optional Multimedia
sudo dnf install -y gstreamer1-plugin-openh264 mozilla-openh264 gstreamer1-plugins-{bad-\*,good-\*,base} lame\* ffmpeg ffmpeg-libs

# 6. Invite the guests: VLC, Brave, and Wireshark
echo "Inviting VLC, Brave, and the Packet-Sniffer to the tea party..."
sudo dnf install -y vlc brave-browser wireshark wireshark-qt curl wget

echo "Granting you permission to peer into the network traffic..."
sudo usermod -aG wireshark $USER

# 7. The Grand Masquerade: PixelOS 1.27 Branding
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

# 8. Hang the Looking-Glass Paintings (Wallpaper & Splash)
echo "Hanging the new wallpaper and painting the boot splash..."
if command -v plasma-apply-wallpaperimage &> /dev/null; then
    plasma-apply-wallpaperimage ~/pixelos/images/wallpaper.png
fi

THEME_DIR="/usr/share/plymouth/themes/pixelos"
sudo mkdir -p "$THEME_DIR"
sudo cp -r /usr/share/plymouth/themes/spinner/* "$THEME_DIR"/
sudo mv "$THEME_DIR"/spinner.plymouth "$THEME_DIR"/pixelos.plymouth
sudo sed -i 's/Name=Spinner/Name=PixelOS/g' "$THEME_DIR"/pixelos.plymouth
sudo sed -i 's/spinner/pixelos/g' "$THEME_DIR"/pixelos.plymouth

if [ -f ~/pixelos/images/bootsplash.png ]; then
    sudo cp ~/pixelos/images/bootsplash.png "$THEME_DIR"/watermark.png
    sudo cp ~/pixelos/images/bootsplash.png "$THEME_DIR"/bgrt-fallback.png
fi

sudo plymouth-set-default-theme -R pixelos

# 9. Write the Post-Reboot AI Invitation
echo "Leaving a little note on your desk to summon the AI later..."
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo ~/Desktop)"
mkdir -p "$DESKTOP_DIR"

AI_SCRIPT="$DESKTOP_DIR/Invite_AI_Guests.sh"

cat << EOF > "$AI_SCRIPT"
#!/bin/bash
echo "Ah, you are awake! Let us invite the clever language models to the party now..."

mkdir -p ~/Applications
cd ~/Applications

echo "Fetching LM Studio..."
wget -q --show-progress "https://lmstudio.ai/download/latest/linux/x64?format=AppImage" -O LM_Studio.AppImage
chmod +x LM_Studio.AppImage

cat << 'DESK' > ~/.local/share/applications/lm-studio.desktop
[Desktop Entry]
Name=LM Studio
Exec=$HOME/Applications/LM_Studio.AppImage --no-sandbox
Icon=utilities-terminal
Type=Application
Categories=Development;Science;
Comment=Chat with local language models
Terminal=false
DESK
update-desktop-database ~/.local/share/applications &> /dev/null || true

echo "Asking the Cheshire Cat for AnythingLLM..."
curl -fsSL https://cdn.anythingllm.com/latest/installer.sh -o anything_installer.sh
chmod +x anything_installer.sh
./anything_installer.sh

echo "Curiouser and curiouser! All your AI guests have arrived! You may now delete this little note."
EOF

chmod +x "$AI_SCRIPT"

echo "Curiouser and curiouser! Your looking-glass transformation is entirely complete!"
echo "I have left a magic spell called 'Invite_AI_Guests.sh' on your desktop for after you wake up."
echo "----------------------------------------------------------------"

# 10. The Final Question
read -p "Would you like to tumble down the rabbit hole and reboot now? (Highly recommended!) [y/N]: " REBOOT_ANSWER
if [[ "$REBOOT_ANSWER" =~ ^[Yy]$ ]]; then
    echo "Off with its head! Restarting the machine..."
    sudo reboot
else
    echo "Very well! The magic is tucked away safely. It will take effect the next time you wake the system."
fi

#!/bin/bash

echo "Tumbling down the rabbit hole to transform Fedora into PixelOS 1.27..."

# 1. Ask for sudo permissions upfront and keep it refreshed
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$TARGET_USER")

# 2. Make directories
echo "Creating user directories..."
mkdir -p "$USER_HOME/pixelos/images"
mkdir -p "$USER_HOME/Applications"
mkdir -p "$USER_HOME/.local/share/applications"
mkdir -p "$USER_HOME/Desktop"

# 3. Ensure Git and Curl are ready
echo "Installing base tools..."
sudo dnf install -y git curl wget

# 4. Fetch the artwork from GitHub
echo "Pulling artwork from GitHub..."
rm -rf /tmp/pixelos_repo
git clone https://github.com/mattjslaunwhite/PixelOS.git /tmp/pixelos_repo

# Copy repository assets
if [ -d "/tmp/pixelos_repo/images" ]; then
    cp -r /tmp/pixelos_repo/images/* "$USER_HOME/pixelos/images/" 2>/dev/null || true
fi
cp -r /tmp/pixelos_repo/* "$USER_HOME/pixelos/images/" 2>/dev/null || true
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME/pixelos"

echo "Contents of ~/pixelos/images:"
ls -la "$USER_HOME/pixelos/images"

# 5. Enable RPM Fusion the official Fedora way (no hardcoded URL 404s!)
echo "Enabling RPM Fusion..."
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || \
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-rawhide.noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-rawhide.noarch.rpm || true

# 6. Add Brave Browser Repository
echo "Configuring Brave repository..."
sudo curl -fsSLo /etc/yum.repos.d/brave-browser.repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo || true
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc || true

# 7. Install Applications individually so one failure does not halt the others
echo "Installing requested applications..."
sudo dnf install -y vlc || echo "VLC install skipped or failed"
sudo dnf install -y brave-browser || echo "Brave install skipped or failed"
sudo dnf install -y wireshark wireshark-qt || echo "Wireshark install skipped or failed"

# Add target user to Wireshark group
sudo usermod -aG wireshark "$TARGET_USER"

# 8. Codecs and Multimedia
echo "Installing media codecs..."
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing || true
sudo dnf install -y gstreamer1-plugins-bad-free gstreamer1-plugins-good gstreamer1-plugin-openh264 lame || true

# 9. Brand as PixelOS 1.27
echo "Setting system identity to PixelOS 1.27..."
sudo hostnamectl set-hostname pixelos

sudo tee /etc/os-release > /dev/null <<EOF
NAME="PixelOS"
PRETTY_NAME="PixelOS 1.27 by Magic goat studio"
ID="pixelos"
ID_LIKE="fedora"
VERSION="1.27"
VERSION_ID="1.27"
VARIANT="KDE Looking-Glass Edition"
HOME_URL="https://github.com/mattjslaunwhite/PixelOS"
EOF

sudo tee /etc/issue > /dev/null <<EOF
Welcome to PixelOS 1.27 by Magic goat studio (\l)
EOF

if [ -f /etc/default/grub ]; then
    sudo sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="PixelOS 1.27"/' /etc/default/grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
fi

# 10. Configure Boot Splash (Plymouth)
echo "Setting up boot splash..."
sudo dnf install -y plymouth plymouth-scripts plymouth-plugin-two-step

THEME_DIR="/usr/share/plymouth/themes/pixelos"
sudo mkdir -p "$THEME_DIR"

if [ -d /usr/share/plymouth/themes/spinner ]; then
    sudo cp -r /usr/share/plymouth/themes/spinner/* "$THEME_DIR/"
    sudo mv "$THEME_DIR/spinner.plymouth" "$THEME_DIR/pixelos.plymouth" 2>/dev/null || true
    sudo sed -i 's/Name=Spinner/Name=PixelOS/g' "$THEME_DIR/pixelos.plymouth" 2>/dev/null || true
    sudo sed -i 's/spinner/pixelos/g' "$THEME_DIR/pixelos.plymouth" 2>/dev/null || true
fi

if [ -f "$USER_HOME/pixelos/images/bootsplash.png" ]; then
    sudo cp "$USER_HOME/pixelos/images/bootsplash.png" "$THEME_DIR/watermark.png"
    sudo cp "$USER_HOME/pixelos/images/bootsplash.png" "$THEME_DIR/bgrt-fallback.png"
    echo "Placed bootsplash.png into Plymouth theme."
else
    echo "Notice: bootsplash.png was not found in ~/pixelos/images/"
fi

sudo plymouth-set-default-theme -R pixelos 2>/dev/null || true
sudo dracut -f --regenerate-all 2>/dev/null || true

# 11. KDE Wallpaper
echo "Applying wallpaper..."
WALLPAPER_FILE="$USER_HOME/pixelos/images/wallpaper.png"
if [ -f "$WALLPAPER_FILE" ]; then
    # Set the system-wide fallback so KDE loads it
    sudo mkdir -p /usr/share/wallpapers/PixelOS/contents/images
    sudo cp "$WALLPAPER_FILE" /usr/share/wallpapers/PixelOS/contents/images/1920x1080.png
    
    # Also tell plasma directly if we are in the graphical session
    if command -v plasma-apply-wallpaperimage &> /dev/null; then
        sudo -u "$TARGET_USER" plasma-apply-wallpaperimage "$WALLPAPER_FILE" 2>/dev/null || true
    fi
    echo "Wallpaper configured."
fi

# 12. Create Post-Reboot AI Installer on Desktop
AI_SCRIPT="$USER_HOME/Desktop/Invite_AI_Guests.sh"
cat << 'EOF' > "$AI_SCRIPT"
#!/bin/bash
echo "Summoning LM Studio and AnythingLLM..."
mkdir -p ~/Applications
cd ~/Applications

# LM Studio
echo "Downloading LM Studio..."
wget -q --show-progress "https://lmstudio.ai/download/latest/linux/x64?format=AppImage" -O LM_Studio.AppImage
chmod +x LM_Studio.AppImage

mkdir -p ~/.local/share/applications
cat << 'DESK' > ~/.local/share/applications/lm-studio.desktop
[Desktop Entry]
Name=LM Studio
Exec=/home/$USER/Applications/LM_Studio.AppImage --no-sandbox
Icon=utilities-terminal
Type=Application
Categories=Development;Science;
Comment=Chat with local language models
Terminal=false
DESK
update-desktop-database ~/.local/share/applications &> /dev/null || true

# AnythingLLM
echo "Running AnythingLLM installer..."
curl -fsSL https://cdn.anythingllm.com/latest/installer.sh -o anything_installer.sh
chmod +x anything_installer.sh
./anything_installer.sh

echo "AI tools setup complete!"
EOF

chmod +x "$AI_SCRIPT"
chown -R "$TARGET_USER:$TARGET_USER" "$USER_HOME"

echo "----------------------------------------------------------------"
echo "PixelOS 1.27 configuration finished!"
read -p "Would you like to reboot now? [y/N]: " REBOOT_ANSWER
if [[ "$REBOOT_ANSWER" =~ ^[Yy]$ ]]; then
    sudo reboot
fi

#!/usr/bin/env bash
set -e

AUR_HELPER="paru"
PACKAGES=(rsync fastfetch kitty niri neovim obs-studio superfile waybar tofi trmt swww)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
SOURCE_DIR="$SCRIPT_DIR/.config/"
DEST_DIR="$HOME/.config/"

THEME_SRC="$SCRIPT_DIR/themes/Nord/gtk"
ICON_SRC="$SCRIPT_DIR/themes/Nord/icons"
THEME_DEST="$HOME/.local/share/themes/Nord"
ICON_DEST="$HOME/.local/share/icons/Nordzy-dark"

echo "Checking for missing packages..."
if ! command -v "$AUR_HELPER" &>/dev/null; then
    echo "AUR helper '$AUR_HELPER' not found. Install it first."; exit 1
fi

missing=()
for pkg in "${PACKAGES[@]}"; do
    "$AUR_HELPER" -Q "$pkg" &>/dev/null || missing+=("$pkg")
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing packages: ${missing[*]}"
    read -p "Install them? (y/N): " ans
    [[ $ans =~ ^[Yy]$ ]] && "$AUR_HELPER" -S --noconfirm "${missing[@]}"
else
    echo "All packages installed."
fi

echo "Syncing dotfiles..."
rsync -av "$SOURCE_DIR" "$DEST_DIR"

echo "Installing Nordic GTK theme and Nordzy icons..."
mkdir -p "$(dirname "$THEME_DEST")" "$(dirname "$ICON_DEST")"
rsync -av "$THEME_SRC/" "$THEME_DEST/"
rsync -av "$ICON_SRC/" "$ICON_DEST/"

echo "Applying GTK and icon themes..."
gsettings set org.gnome.desktop.interface gtk-theme "Nord"
gsettings set org.gnome.desktop.interface icon-theme "Nordzy-dark" || true

sh ~/.config/walls/toggle-wallpaper.sh


echo "Base ricing done :)"

# --------------------------
# Extra apps prompt
# --------------------------
EXTRA_APPS=("Zen")
echo ""
echo "Optional extra apps available to install:"
for app in "${EXTRA_APPS[@]}"; do
    echo "  - $app"
done

read -p "Do you want to install and configure these extra apps? (y/N): " install_extra
if [[ $install_extra =~ ^[Yy]$ ]]; then
    echo "Installing and configuring extra apps..."
    
    # Zen setup
    ZEN_SRC="$SCRIPT_DIR/themes/Nord/zen/userChrome.css"
    ZEN_DIR="$HOME/.zen"
    if [ -f "$ZEN_SRC" ]; then
        echo "Copying userChrome.css to all Zen profiles..."
        find "$ZEN_DIR" -maxdepth 1 -type d -name "*.Default*" | while read -r PROFILE; do
            mkdir -p "$PROFILE/chrome"
            cp "$ZEN_SRC" "$PROFILE/chrome/userChrome.css"
            echo "Copied to $PROFILE/chrome/"
        done
    else
        echo "No userChrome.css found in $SCRIPT_DIR/zen/"
    fi

else
    echo "Skipping extra apps installation."
fi

echo "Done! Theme, icons, and optional extra apps applied."

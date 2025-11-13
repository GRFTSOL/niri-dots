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

[ -f "$HOME/.config/walls/toggle-wallpaper.sh" ] && sh "$HOME/.config/walls/toggle-wallpaper.sh"

echo "Base ricing done."

# --------------------------
# Extra apps
# --------------------------
EXTRA_APPS=("Zen" "code-oss")

echo ""
echo "Optional apps available:"
for i in "${!EXTRA_APPS[@]}"; do
    echo "  [$((i+1))] ${EXTRA_APPS[$i]}"
done

read -p "Enter numbers of apps to install (e.g. '1 2'), or press Enter to skip: " -a selections
[ ${#selections[@]} -eq 0 ] && echo "Skipping extra apps." && exit 0

for idx in "${selections[@]}"; do
    app="${EXTRA_APPS[$((idx-1))]}"
    case "$app" in
        Zen)
            echo "Setting up Zen..."
            ZEN_SRC="$SCRIPT_DIR/themes/Nord/zen/userChrome.css"
            ZEN_DIR="$HOME/.zen"
            if [ -f "$ZEN_SRC" ]; then
                find "$ZEN_DIR" -maxdepth 1 -type d -name "*.Default*" | while read -r p; do
                    mkdir -p "$p/chrome" && cp "$ZEN_SRC" "$p/chrome/userChrome.css"
                    echo "Copied to $p/chrome/"
                done
            else
                echo "No userChrome.css found."
            fi
            ;;
        code-oss)
            echo "Installing and theming VSCode-OSS..."
            "$AUR_HELPER" -S --noconfirm code-oss || true
            SETTINGS="$HOME/.config/Code - OSS/User/settings.json"
            mkdir -p "$(dirname "$SETTINGS")"
            code-oss --install-extension arcticicestudio.nord-visual-studio-code || true
            echo '{ "workbench.colorTheme": "Nord" }' > "$SETTINGS"
            ;;
        *)
            echo "Unknown selection: $idx"
            ;;
    esac
done

echo "Done. Themes and extras applied."

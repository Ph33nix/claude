#!/bin/bash

# Launch wlogout with blurred wallpaper background
# This script creates a blurred snapshot of the current wallpaper

# Output path for blurred wallpaper
BLUR_IMAGE="/tmp/wlogout-blurred-wallpaper.png"

# Get current wallpaper (adjust path if needed - this works with most wallpaper managers)
# Try different methods to get the current wallpaper
if command -v swww &> /dev/null; then
    # If using swww, get the current wallpaper
    CURRENT_WALLPAPER=$(swww query | grep -oP 'image: \K.*' | head -1)
elif [ -f ~/.cache/current_wallpaper ]; then
    # Check if there's a cached wallpaper path
    CURRENT_WALLPAPER=$(cat ~/.cache/current_wallpaper)
elif [ -f ~/.config/wallpaper ]; then
    CURRENT_WALLPAPER=$(cat ~/.config/wallpaper)
else
    # Fallback: take a screenshot of the current desktop
    grim "$BLUR_IMAGE.temp.png"
    CURRENT_WALLPAPER="$BLUR_IMAGE.temp.png"
fi

# Create blurred version using ImageMagick
if command -v magick &> /dev/null; then
    magick "$CURRENT_WALLPAPER" -blur 0x15 "$BLUR_IMAGE"
elif command -v convert &> /dev/null; then
    convert "$CURRENT_WALLPAPER" -blur 0x15 "$BLUR_IMAGE"
else
    # Fallback: just copy the wallpaper if ImageMagick is not available
    cp "$CURRENT_WALLPAPER" "$BLUR_IMAGE"
fi

# Clean up temp file if created
[ -f "$BLUR_IMAGE.temp.png" ] && rm "$BLUR_IMAGE.temp.png"

# Launch wlogout with 5 columns, 1 row, buttons at bottom
# -b: specify bottom margin (pixels from bottom)
# -c: number of columns
# -r: number of rows
wlogout \
    --layout ~/.config/wlogout/layout \
    --css ~/.config/wlogout/style.css \
    --buttons-per-row 5 \
    --column-spacing 20 \
    --row-spacing 20 \
    --margin-bottom 100 \
    --margin-top 0

# wlogout Configuration

Custom wlogout configuration with blurred wallpaper background and bottom-row layout.

## Features

- 🎨 Matches quickshell theme colors
- 🖼️ Blurred wallpaper background
- 📍 Buttons positioned at bottom in a single row (5x1 grid)
- ✨ Smooth hover animations
- 🔒 Lock screen integration with quickshell IPC

## Installation

1. Copy to your config directory:
   ```bash
   cp -r wlogout ~/.config/
   ```

2. Make the launch script executable (if not already):
   ```bash
   chmod +x ~/.config/wlogout/launch-wlogout.sh
   ```

## Usage

### Method 1: Using the Launch Script (Recommended)

The launch script automatically creates a blurred wallpaper and launches wlogout with correct layout:

```bash
~/.config/wlogout/launch-wlogout.sh
```

### Method 2: Manual Launch with Arguments

```bash
wlogout --layout ~/.config/wlogout/layout \
        --css ~/.config/wlogout/style.css \
        --buttons-per-row 5 \
        --margin-bottom 100
```

## Dependencies

### Required:
- `wlogout` - The logout menu application

### Optional (for blurred wallpaper):
- `imagemagick` (provides `magick` or `convert` command) - For wallpaper blurring
- `grim` - For screenshot fallback if wallpaper can't be detected

## Wallpaper Detection

The launch script tries to detect your current wallpaper using:
1. `swww query` - If using swww wallpaper daemon
2. `~/.cache/current_wallpaper` - Cached wallpaper path
3. `~/.config/wallpaper` - Config wallpaper path
4. `grim` screenshot - Fallback

If you use a different wallpaper manager, edit `launch-wlogout.sh` to add detection for your setup.

## Customization

### Colors

Edit `style.css` to change colors. Current theme matches quickshell:
- Background: `rgba(26, 28, 38, 0.9)`
- Border: `rgba(42, 45, 58, 0.9)`
- Hover accent: `rgba(168, 174, 255, 0.95)`
- Text: `#CACEE2`

### Layout

Adjust button positioning by modifying the launch script arguments:
- `--buttons-per-row 5` - Number of buttons per row
- `--margin-bottom 100` - Distance from bottom (pixels)
- `--column-spacing 20` - Space between columns
- `--row-spacing 20` - Space between rows

### Icons

Custom icons are in `icons/` directory. Replace with your own 100x100 PNG files.

## Files

- `layout` - Button definitions and actions
- `style.css` - Main stylesheet with blurred wallpaper
- `style-bottom-row.css` - Alternative stylesheet
- `launch-wlogout.sh` - Helper script for blurred wallpaper
- `icons/` - Custom icon files

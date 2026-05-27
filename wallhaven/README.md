# Wallhaven

Browse, search, and download wallpapers from Wallhaven inside Noctalia Shell.

## Features

- Search Wallhaven from a panel
- Browse wallpaper thumbnails in a responsive grid
- Download wallpapers to a configurable folder
- Choose SFW, SFW + Sketchy, or All purity modes
- Toggle the panel from the control center or IPC

## Requirements

- Noctalia Shell 4.6.6 or newer
- `curl` or `wget` for downloads
- A Wallhaven API key for NSFW searches

## Settings

- Download Directory: folder where wallpapers are saved
- Default Search Query: optional query used when the panel opens
- API Key: optional Wallhaven API key
- Purity: Wallhaven purity categories to search

## IPC

```bash
qs ipc call plugin:wallhaven toggle
```

## Testing

```bash
qs -c noctalia-shell
```

Verify that the panel opens, search results load, downloads are saved to the configured directory, and settings persist after restarting Noctalia Shell.

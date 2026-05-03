# Adding a New Theme — Skill

This document describes the exact procedure for adding a new color theme to the oxwm desktop environment.

## Overview

Each theme consists of **2 files** in `~/.config/themes/<name>/`. `render-theme.py` reads them, renders shared templates, and writes all config files. Yazi needs a flavor directory — all others are handled automatically.

## Step-by-step

### 1. Create the theme directory

```
mkdir -p dotfiles/.config/themes/<name>/
```

### 2. Create `colors.lua`

15 color keys, all required:

```lua
return {
    -- oxwm (11 keys — copied directly to custom.lua)
    fg = "#bbbbbb",            -- general foreground (oxwm unfocused)
    red = "#f7768e",           -- errors, critical urgency
    bg = "#1a1b26",            -- main background
    sep = "#444b6a",           -- separators in bar
    cyan = "#0db9d7",          -- accent (less prominent)
    green = "#9ece6a",         -- success, quotes
    lavender = "#a9b1d6",      -- rofi border, less prominent UI
    light_blue = "#7aa2f7",    -- commands, terminal blue
    grey = "#bbbbbb",          -- alternative foreground
    blue = "#6dade3",          -- focused borders, cwd, hyperlinks
    purple = "#ad8ee6",        -- magenta, terminals, selection

    -- extended (4 keys — used by templates)
    text = "#c0caf5",          -- main text (rofi, dunst, wezterm foreground)
    surface = "#24283b",       -- elevated surface (rofi surface0, dunst normal bg, terminal black)
    yellow = "#e0af68",        -- ANSI yellow, search match background
    accent = "#bb9af7",        -- emphasis (dunst frame/highlight)
    muted = "#565f89",         -- dim text (fish autosuggestions, pager descriptions)
}
```

**Key derivation rules** (how templates use each key):

| Key | rofi | dunst | wezterm | fish | oxwm | slock |
|---|---|---|---|---|---|---|---|
| `bg` | bg | urgency_low bg | background | — | bg | init (idle bg) |
| `text` | text, entry | foreground | foreground | normal, param, host | — | text (message) |
| `surface` | surface0 | urgency_normal bg | ansi[0] | selection bg | — | — |
| `red` | prompt char | critical fg/frame | ansi[1] | error | red | fail (wrong pw) |
| `green` | — | — | ansi[2] | quote | green | — |
| `yellow` | — | — | ansi[3] | search_match bg | — | — |
| `light_blue` | — | — | ansi[4] | command | light_blue | input (typing) |
| `purple` | mauve | — | ansi[5] | end, escape, pager_prefix | purple | — |
| `cyan` | — | — | ansi[6] | redirection, operator | cyan | — |
| `blue` | — | — | — | cwd, user, pager_progress | blue | — |
| `lavender` | border color | — | — | — | lavender | — |
| `accent` | — | frame_color, highlight | — | — | — | — |
| `fg` | — | — | — | — | fg | — |
| `grey` | — | — | — | — | grey | — |
| `muted` | — | — | — | autosuggestion, pager_description | — | — |
| `sep` | — | — | — | — | sep | — |

### 3. Create `theme.conf`

```ini
rofi_font=JetBrainsMono Nerd Font 11
yazi_flavor=<yazi-flavor-name>
gtk_theme=<gtk-theme-name>
gtk_icon=<gtk-icon-theme-name>
gtk_font=Noto Sans 11
dark_mode=0
```

- `rofi_font`: rofi font string (with size). Quoted in template automatically
- `yazi_flavor`: must match a subdirectory name under `dotfiles/.config/yazi/flavors/`
- `gtk_theme` / `gtk_icon`: must be installed on the system (pacman/AUR). Mint-Y variants
- `dark_mode`: `0` (light) or `1` (dark)
- `gtk_font`: font for GTK apps (Noto Sans 11, etc.)

### 4. Create yazi flavor (if not already in repo)

If the flavor doesn't exist under `dotfiles/.config/yazi/flavors/`, add it:

```
git clone https://github.com/<flavor-repo> dotfiles/.config/yazi/flavors/<name>.yazi
```

Each yazi flavor is a git repo. Existing flavors: `tokyo-night.yazi`, `nord.yazi`, `catppuccin-*.yazi`, `dracula.yazi`, `flexoki-*.yazi`, `gruvbox-*.yazi`, `modus.yazi`.

### 5. Verify color contrast

Check these specific combinations — they are the most common visibility issues:

- `muted` against `bg` — fish autosuggestions must be dim but readable
- `surface` against `bg` — separator between surface and bg needs enough contrast
- `text` against `bg` — main readability
- `muted` against `surface` — fish pager descriptions on selection background

### 6. Deploy and test

```bash
# Copy new theme to the themes dir
cp -r dotfiles/.config/themes/<name>/ ~/.config/themes/

# Render everything
~/.config/themes/render-theme.py <name>

# Restart services (or use switch-theme.sh which does it all)
~/.local/bin/switch-theme.sh <name>
```

Verify by switching to the theme and checking each component:

| Component | How to verify |
|---|---|
| oxwm | Check bar colors, border colors, tag highlight. `Mod+Shift+R` if needed |
| rofi | `Mod+D` — check background, text, selection border |
| dunst | Trigger a notification (`dunstify test`) — check bg, frame, text |
| wezterm | Open new terminal — check bg, fg, ANSI colors (`echo -e '\e[0;31mred\e[0m'`) |
| fish | Start typing a command — autosuggestion must be clearly visible |
| yazi | Open in a terminal — check flavor applied |
| GTK apps | Open nemo or any GTK app — check titlebar/widget colors |
| slock | `Mod+Shift+L` — lock screen bg (init), typing highlight (input), error flash (fail), message text |

## Troubleshooting

**Autosuggestion invisible**: `muted` value in `colors.lua` is too close to `bg`. Darken or lighten `muted` until readable against `bg`.

**Dunst frame missing**: `accent` value may not contrast enough with `bg`. The accent is used for the notification frame and highlight border.

**Terminal black (`ansi[0]` = `surface`) blends with bg**: Some terminals want a clearly distinct black from the main bg. Add a `wezterm.lua` override in the theme dir to set custom ANSI values.

**slock input color too subtle**: If `light_blue` is hard to see on `bg`, override in `colors.lua` or adjust the value. The input state should clearly contrast with the idle state.

## Important files reference

| File | Location in dotfiles | Purpose |
|---|---|---|
| Theme colors | `dotfiles/.config/themes/<name>/colors.lua` | All color values |
| Theme metadata | `dotfiles/.config/themes/<name>/theme.conf` | Non-color settings |
| Rofi template | `dotfiles/.config/themes/templates/rofi.rasi.tpl` | Rofi theme with `{{key}}` placeholders |
| Dunst template | `dotfiles/.config/themes/templates/dunst.conf.tpl` | Dunst config with `{{key}}` placeholders |
| Wezterm template | `dotfiles/.config/themes/templates/wezterm.lua.tpl` | Terminal colors with auto-ANSIs |
| Fish template | `dotfiles/.config/themes/templates/fish-colors.fish.tpl` | Shell colors |
| Slock template | `dotfiles/.config/themes/templates/slock.Xresources.tpl` | Lock screen colors (→ `~/.Xresources.d/slock`, loaded by xrdb) |
| Render engine | `dotfiles/.config/themes/render-theme.py` | Reads theme → renders templates → writes configs |
| Switch script | `dotfiles/.local/bin/switch-theme.sh` | Rofi picker + render + service restarts |

## Quick reference: colors.lua key → template mapping

```
oxwm-colors.lua:  fg red bg sep cyan green lavender light_blue grey blue purple
     (written directly, no template)

rofi.rasi.tpl:    bg text red lavender surface purple
dunst.conf.tpl:   bg text red surface accent
wezterm.lua.tpl:  bg text surface red green yellow light_blue purple cyan
fish.fish.tpl:    text light_blue red surface yellow green cyan purple blue muted
slock.Xresources.tpl:  bg light_blue red text
theme.conf:       rofi_font yazi_flavor gtk_theme gtk_icon gtk_font dark_mode
```

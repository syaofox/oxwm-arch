# AGENTS.md — oxwm-arch

Arch Linux minimal → OXWM tiling WM desktop environment. Dotfiles + setup scripts.

## Entrypoint

`install.sh` orchestrates everything. It sources `setup/utils.sh` and runs `setup/*.sh` in this order:

1. `upgrade-system` → `install-yay` → `configure-makepkg`
2. `install-deps` → `install-oxwm` → `install-apps`
3. `install-fonts` → `install-nemo` → `install-fcitx5` → `install-docker` → `install-nvidia` → `install-flathub`
4. `deploy-dotfiles` → `update-usergroup` → `configure-autologin` → `install-fish`

Each step has retry/skip/exit on failure.

## OXWM — built from source

- Clone: `https://github.com/syaofox/oxwm.git` → `/tmp/oxwm`
- Build: `zig build -Doptimize=ReleaseSmall`
- Install: `sudo zig build -Doptimize=ReleaseSmall --prefix /usr install`
- Dependencies: `zig libx11 libxft freetype2 fontconfig libxinerama`
- Config: `~/.config/oxwm/config.lua` — **no compilation needed on edit**, reload with `Mod+Shift+R`
- Colors: `~/.config/oxwm/colors/custom.lua` is imported by `config.lua`

## Dotfiles deployment

`setup/deploy-dotfiles.sh` **copies** (not symlinks) every file under `dotfiles/` to `$HOME/`. Existing files get backed up to `~/.config-backup-<timestamp>/`.

## Shell

- Default shell: **fish** (`/usr/bin/fish`, set via `chsh`)
- Plugin manager: **fisher**
- Plugins list: `dotfiles/.config/fish/fish_plugins` — `pure-fish/pure`, `PatrickF1/fzf.fish`
- Config split: `conf.d/01-env.fish` (env vars), `03-aliases.fish` (aliases/abbr), `04-fzf.fish`, `05-yazi.fish`, `06-zoxide.fish`

## X session

`startx` → `~/.xinitrc` → `dbus-run-session oxwm`. Auto-login on tty1 via systemd drop-in with password verification (`~/.local/bin/tty-lock-and-startx.sh`).

## Syntax

### Keybinds
```
Mod=Super, Terminal=wezterm, Menu=rofi, Browser=brave, File=nemo
```
All custom actions via `oxwmcmd.sh` subcommands:
- `oxwmcmd.sh menu` (launcher), `web`, `file`, `lock`, `calc`, `save`, `clip`, `clipman`, `theme`, `sys`, `search`, `switch-wallpaper`

### Theme switching (`Mod+Shift+T` → `oxwmcmd.sh theme` → `switch-theme.sh`)

Themes stored in `~/.config/themes/<name>/` — each dir has 7 template files:

| File | Target | Applied by |
|---|---|---|
| `oxwm-colors.lua` | `~/.config/oxwm/colors/custom.lua` | oxwm `Mod+Shift+R` hot-reload |
| `rofi.rasi` | `~/.config/rofi/theme.rasi` | read on next launch |
| `dunst.conf` | `~/.config/dunst/dunstrc` | `pkill dunst; dunst &` |
| `wezterm.lua` | `~/.config/wezterm/theme.lua` | read on next launch |
| `yazi-flavor` | content → `theme.toml` flavor field | read on next launch |
| `gtk-theme-name` | gtkrc + settings.ini + xsettingsd | `pkill xsettingsd; xsettingsd &` |
| `gtk-icon-theme-name` | icon theme in gtkrc + xsettingsd | same restart |

Built-in themes: `tokyo-night`, `nord`. Usage: `switch-theme.sh` (rofi), `switch-theme.sh nord`.

### Available layouts
`tiling`, `normie` (floating), `grid`, `monocle`, `tabbed`

## Admin scripts (sbin/)

| Script | Purpose | Usage |
|--------|---------|-------|
| `sbin/btrfs-select.sh` | Btrfs subvolume optimization | `./sbin/btrfs-select.sh <username>` |
| `sbin/sysctl.sh` | Kernel params (inotify) | `./sbin/sysctl.sh` |
| `sbin/zram.sh` | ZRAM swap config | `./sbin/zram.sh [percent]` |

All support `--chroot` flag for chroot environments. Require root.

## Config manager (tools/)

`tools/config-manager.sh` backs up/restores SSH, GPG, dconf, fcitx5 configs. Interactive (fzf fallback). Must NOT run as root. Subcommands: `backup`, `restore`.

## AUR helper

yay is built from source: `git clone https://aur.archlinux.org/yay.git && makepkg -si`. makepkg threads set to `nproc`.

## Notable install details

- **Nvidia**: auto-detected via `lspci`. Installs `nvidia-open-dkms` + matching kernel headers, configures `nvidia_drm modeset=1`, updates GRUB/systemd-boot
- **Docker**: systemd-enabled, user added to `docker` group
- **KVM**: `setup/install-kvm.sh` exists but **NOT called** from `install.sh` (manual only)
- **Flatpak**: flathub remote added, GTK theme overrides for flatpak apps
- **Input method**: fcitx5, env vars in `.xinitrc` (`GTK_IM_MODULE=fcitx`, `QT_IM_MODULE=fcitx`, etc.)
- **Backups dir**: `backups/` is fully gitignored (`/*` in `.gitignore`)

## OpenCode config

`dotfiles/.config/opencode/opencode.json`: Chrome DevTools MCP enabled, formatter disabled.

## No build/test/CI

This is a system provisioning repo — no conventional build, test, lint, or CI.

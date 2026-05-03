#!/usr/bin/env python3
"""Render theme templates for oxwm desktop theme switching."""

import os
import re
import sys

THEMES_DIR = os.path.expanduser("~/.config/themes")
TEMPLATES_DIR = os.path.join(THEMES_DIR, "templates")
HOME = os.path.expanduser("~")

OXWM_KEYS = ["fg", "red", "bg", "sep", "cyan", "green", "lavender",
             "light_blue", "grey", "blue", "purple"]

ANSI_MAP = [("surface", "bg"), ("red",), ("green",), ("yellow",),
            ("light_blue", "blue"), ("purple",), ("cyan",), ("text", "fg")]


def parse_colors_lua(path):
    colors = {}
    with open(path) as f:
        for line in f:
            m = re.match(r'^\s*(\w+)\s*=\s*"(#[0-9a-fA-F]+)"', line)
            if m:
                colors[m.group(1)] = m.group(2)
    return colors


def parse_theme_conf(path):
    meta = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                k, v = line.split("=", 1)
                meta[k.strip()] = v.strip()
    return meta


def render_template(template_path, vars_dict):
    with open(template_path) as f:
        content = f.read()

    def repl(m):
        key = m.group(1)
        return vars_dict.get(key, m.group(0))

    return re.sub(r"\{\{(\w+)\}\}", repl, content)


def generate_ansi(colors):
    ansi = []
    for spec in ANSI_MAP:
        val = None
        for key in spec:
            if key in colors:
                val = colors[key]
                break
        ansi.append(val or "#000000")
    return ansi, list(ansi)


def update_oxwm_colors(colors, out):
    with open(out, "w") as f:
        f.write("return {\n")
        for key in OXWM_KEYS:
            if key in colors:
                f.write(f'    {key} = "{colors[key]}",\n')
        f.write("}\n")


def update_file_regex(path, patterns):
    with open(path) as f:
        content = f.read()
    changed = False
    for pattern, repl in patterns:
        new_content = re.sub(pattern, repl, content)
        if new_content != content:
            content = new_content
            changed = True
    if changed:
        with open(path, "w") as f:
            f.write(content)
    return changed


def render(theme_name):
    theme_dir = os.path.join(THEMES_DIR, theme_name)
    colors_path = os.path.join(theme_dir, "colors.lua")
    conf_path = os.path.join(theme_dir, "theme.conf")
    wezterm_custom = os.path.join(theme_dir, "wezterm.lua")

    colors = parse_colors_lua(colors_path)
    meta = parse_theme_conf(conf_path)
    vars_dict = {**colors, **meta}

    # Generate ANSI terminal colors
    ansi, brights = generate_ansi(colors)
    for i in range(8):
        vars_dict[f"ansi_{i}"] = ansi[i]
        vars_dict[f"bright_{i}"] = brights[i]

    # 1. OXWM colors
    oxwm_out = os.path.join(HOME, ".config/oxwm/colors/custom.lua")
    update_oxwm_colors(colors, oxwm_out)
    print("  oxwm      ✓")

    # 2. Rofi
    rofi_tpl = os.path.join(TEMPLATES_DIR, "rofi.rasi.tpl")
    rofi_out = os.path.join(HOME, ".config/rofi/theme.rasi")
    rendered = render_template(rofi_tpl, vars_dict)
    with open(rofi_out, "w") as f:
        f.write(rendered)
    print("  rofi      ✓")

    # 3. Dunst
    dunst_tpl = os.path.join(TEMPLATES_DIR, "dunst.conf.tpl")
    dunst_out = os.path.join(HOME, ".config/dunst/dunstrc")
    rendered = render_template(dunst_tpl, vars_dict)
    with open(dunst_out, "w") as f:
        f.write(rendered)
    print("  dunst     ✓")

    # 4. Wezterm
    wezterm_out = os.path.join(HOME, ".config/wezterm/theme.lua")
    if os.path.exists(wezterm_custom):
        with open(wezterm_custom) as f:
            content = f.read()
    else:
        wezterm_tpl = os.path.join(TEMPLATES_DIR, "wezterm.lua.tpl")
        content = render_template(wezterm_tpl, vars_dict)
    with open(wezterm_out, "w") as f:
        f.write(content)
    print("  wezterm   ✓")

    # 5. Yazi flavor
    if "yazi_flavor" in meta:
        yazi_path = os.path.join(HOME, ".config/yazi/theme.toml")
        if os.path.exists(yazi_path):
            update_file_regex(yazi_path, [
                (r'dark = ".*"', f'dark = "{meta["yazi_flavor"]}"'),
                (r'light = ".*"', f'light = "{meta["yazi_flavor"]}"'),
            ])
    print("  yazi      ✓")

    # 6. GTK + xsettingsd
    gtk_theme = meta.get("gtk_theme", "")
    gtk_icon = meta.get("gtk_icon", "")
    gtk_font = meta.get("gtk_font", "Noto Sans 11")
    dark_mode = meta.get("dark_mode", "0")

    if gtk_theme:
        update_file_regex(os.path.join(HOME, ".gtkrc-2.0"), [
            (r'gtk-theme-name = ".*"', f'gtk-theme-name = "{gtk_theme}"'),
            (r'gtk-icon-theme-name = ".*"', f'gtk-icon-theme-name = "{gtk_icon}"'),
        ])

        for ver in ("3.0", "4.0"):
            path = os.path.join(HOME, f".config/gtk-{ver}/settings.ini")
            if os.path.exists(path):
                update_file_regex(path, [
                    (r"gtk-theme-name=.*", f"gtk-theme-name={gtk_theme}"),
                    (r"gtk-icon-theme-name=.*", f"gtk-icon-theme-name={gtk_icon}"),
                ])

        xset_path = os.path.join(HOME, ".config/xsettingsd/xsettingsd.conf")
        if os.path.exists(xset_path):
            update_file_regex(xset_path, [
                (r'Net/ThemeName ".*"', f'Net/ThemeName "{gtk_theme}"'),
                (r'Net/IconThemeName ".*"', f'Net/IconThemeName "{gtk_icon}"'),
            ])

    if gtk_font:
        for path, patterns in [
            (os.path.join(HOME, ".gtkrc-2.0"), [
                (r'gtk-font-name = ".*"', f'gtk-font-name = "{gtk_font}"'),
            ]),
            (os.path.join(HOME, ".config/gtk-3.0/settings.ini"), [
                (r"gtk-font-name=.*", f"gtk-font-name={gtk_font}"),
            ]),
            (os.path.join(HOME, ".config/gtk-4.0/settings.ini"), [
                (r"gtk-font-name=.*", f"gtk-font-name={gtk_font}"),
            ]),
            (os.path.join(HOME, ".config/xsettingsd/xsettingsd.conf"), [
                (r'Gtk/FontName ".*"', f'Gtk/FontName "{gtk_font}"'),
            ]),
        ]:
            if os.path.exists(path):
                update_file_regex(path, patterns)

    update_file_regex(os.path.join(HOME, ".gtkrc-2.0"), [
        (r"gtk-application-prefer-dark-theme = .*",
         f"gtk-application-prefer-dark-theme = {dark_mode}"),
    ])
    for ver in ("3.0", "4.0"):
        path = os.path.join(HOME, f".config/gtk-{ver}/settings.ini")
        if os.path.exists(path):
            update_file_regex(path, [
                (r"gtk-application-prefer-dark-theme=.*",
                 f"gtk-application-prefer-dark-theme={dark_mode}"),
            ])
    xset_path = os.path.join(HOME, ".config/xsettingsd/xsettingsd.conf")
    if os.path.exists(xset_path):
        update_file_regex(xset_path, [
            (r"Gtk/ApplicationPreferDarkTheme .*",
             f"Gtk/ApplicationPreferDarkTheme {dark_mode}"),
        ])

    print("  gtk       ✓")

    # 7. Fish shell colors
    fish_tpl = os.path.join(TEMPLATES_DIR, "fish-colors.fish.tpl")
    fish_out = os.path.join(HOME, ".config/fish/conf.d/02-colors.fish")
    rendered = render_template(fish_tpl, vars_dict)
    with open(fish_out, "w") as f:
        f.write(rendered)
    print("  fish      ✓")


def main():
    theme = sys.argv[1] if len(sys.argv) > 1 else ""
    if not theme:
        print("Usage: render-theme.py <theme_name>")
        sys.exit(1)
    render(theme)


if __name__ == "__main__":
    main()

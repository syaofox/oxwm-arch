#!/usr/bin/env python3
import sys
import os
import re

TEMPLATES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'templates')

TEMPLATE_OUTPUTS = [
    ('dunstrc.j2',            '~/.config/dunst/dunstrc'),
    ('rofi.rasi.j2',          '~/.config/rofi/theme.rasi'),
    ('wezterm.lua.j2',        '~/.config/wezterm/theme.lua'),
    ('yazi.toml.j2',          '~/.config/yazi/theme.toml'),
    ('ps1.j2',                '~/.bashrc.d/ps1/current'),
    ('gtk2.j2',               '~/.gtkrc-2.0'),
    ('gtk3.ini.j2',           '~/.config/gtk-3.0/settings.ini'),
    ('gtk3.ini.j2',           '~/.config/gtk-4.0/settings.ini'),
    ('xsettingsd.conf.j2',    '~/.config/xsettingsd/xsettingsd.conf'),
]


def hex_to_rgb(hex_color):
    hex_color = hex_color.strip().lstrip('#')
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return '{}, {}, {}'.format(r, g, b)


def hex_to_rgb_s(hex_color):
    """hex_to_rgb with semicolons (for ANSI escape sequences)"""
    hex_color = hex_color.strip().lstrip('#')
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return '{};{};{}'.format(r, g, b)


FILTERS = {
    'hex_to_rgb': hex_to_rgb,
    'hex_to_rgb_s': hex_to_rgb_s,
}


def parse_palette(filepath):
    palette = {}
    with open(filepath) as f:
        for line in f:
            line = line.strip()
            if line.startswith('#define'):
                rest = line[8:].strip()
                parts = rest.split(None, 1)
                if len(parts) >= 2:
                    palette[parts[0]] = parts[1]
                elif len(parts) == 1:
                    palette[parts[0]] = ''
    return palette


def render_template(text, context):
    def replacer(match):
        expr = match.group(1).strip()
        if '|' in expr:
            var_name, filter_name = (x.strip() for x in expr.split('|', 1))
            value = context.get(var_name, '')
            if filter_name in FILTERS:
                return FILTERS[filter_name](value)
            return value
        return context.get(expr, '')
    return re.sub(r'\{\{(.*?)\}\}', replacer, text)


def main():
    if len(sys.argv) < 2:
        print("Usage: generate-app-themes.py <theme_file>", file=sys.stderr)
        sys.exit(1)

    theme_file = sys.argv[1]
    if not os.path.isfile(theme_file):
        print("Error: Theme file not found: {}".format(theme_file), file=sys.stderr)
        sys.exit(1)

    if not os.path.isdir(TEMPLATES_DIR):
        print("Error: Templates directory not found: {}".format(TEMPLATES_DIR), file=sys.stderr)
        sys.exit(1)

    palette = parse_palette(theme_file)

    for tpl_name, rel_output in TEMPLATE_OUTPUTS:
        tpl_path = os.path.join(TEMPLATES_DIR, tpl_name)
        if not os.path.isfile(tpl_path):
            continue

        with open(tpl_path) as f:
            template_text = f.read()

        rendered = render_template(template_text, palette)

        output = os.path.expanduser(rel_output)
        os.makedirs(os.path.dirname(output), exist_ok=True)
        if os.path.islink(output):
            os.unlink(output)

        with open(output, 'w') as f:
            f.write(rendered)

    print("Theme configs generated successfully from: {}".format(os.path.basename(theme_file)))


if __name__ == '__main__':
    main()

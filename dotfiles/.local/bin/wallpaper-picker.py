#!/usr/bin/env python3
import os
import sys
import subprocess

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gtk, GdkPixbuf, Gdk, Pango

WALLPAPER_DIR = os.path.expanduser("~/.config/walls")
WALLPAPER_CONF = os.path.expanduser("~/.config/wallpaper.conf")
THUMB_SIZE = 200


def notify(msg):
    subprocess.run(["notify-send", "switch-wallpaper", msg], capture_output=True)


class WallpaperPicker(Gtk.Window):
    def __init__(self):
        super().__init__(title="Select Wallpaper")
        self.set_default_size(960, 640)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_type_hint(Gdk.WindowTypeHint.DIALOG)

        self.wallpapers = self._get_wallpapers()
        if not self.wallpapers:
            notify("No wallpapers found")
            sys.exit(1)

        self._selected_index = -1

        css = Gtk.CssProvider()
        css.load_from_data(b"""
            window { background-color: #1e1e2e; }
            .hint-bar {
                background-color: #181825;
                color: #a6adc8;
                padding: 8px 16px;
                font-size: 13px;
                border-bottom: 1px solid #313244;
            }
            .hint-bar label { color: #a6adc8; }
            .hint-bar .key { color: #cdd6f4; font-weight: bold; }
            .thumbnail-box {
                background-color: #181825;
                border-radius: 8px;
                margin: 6px;
                padding: 4px;
            }
            .thumbnail-box:selected {
                background-color: #45475a;
                border: 2px solid #89b4fa;
            }
            flowbox { padding: 8px; }
            scrollbar trough { background-color: #11111b; }
            scrollbar slider { background-color: #45475a; border-radius: 4px; }
            .filename-label {
                color: #bac2de;
                font-size: 11px;
                padding: 2px 4px;
            }
        """)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(vbox)

        hint = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        hint.get_style_context().add_class("hint-bar")
        hint.set_halign(Gtk.Align.CENTER)
        parts = [
            ("key", "Click"), ("", " select  \u00b7  "),
            ("key", "Click again"), ("", " set  \u00b7  "),
            ("key", "Enter"), ("", " set selected  \u00b7  "),
            ("key", "Esc"), ("", " exit"),
        ]
        for cls, text in parts:
            lbl = Gtk.Label(label=text)
            if cls:
                lbl.get_style_context().add_class(cls)
            hint.pack_start(lbl, False, False, 0)
        vbox.pack_start(hint, False, False, 0)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        vbox.pack_start(scrolled, True, True, 0)

        self.flowbox = Gtk.FlowBox()
        self.flowbox.set_valign(Gtk.Align.START)
        self.flowbox.set_max_children_per_line(10)
        self.flowbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.flowbox.set_activate_on_single_click(False)
        self.flowbox.connect("button-press-event", self._on_button)
        self.flowbox.connect("child-activated", self._on_activate)
        scrolled.add(self.flowbox)

        self._load_thumbnails()

        self.connect("key-press-event", self._on_key)
        self.connect("destroy", Gtk.main_quit)

    def _get_wallpapers(self):
        exts = (".jpg", ".jpeg", ".png", ".gif", ".webp")
        if not os.path.isdir(WALLPAPER_DIR):
            return []
        return sorted(
            os.path.join(WALLPAPER_DIR, f)
            for f in os.listdir(WALLPAPER_DIR)
            if f.lower().endswith(exts)
        )

    def _load_thumbnails(self):
        for path in self.wallpapers:
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            box.get_style_context().add_class("thumbnail-box")
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(
                    path, THUMB_SIZE, THUMB_SIZE
                )
            except Exception:
                continue
            img = Gtk.Image.new_from_pixbuf(pixbuf)
            box.pack_start(img, False, False, 0)
            name = os.path.splitext(os.path.basename(path))[0]
            label = Gtk.Label(label=name, max_width_chars=18)
            label.set_ellipsize(Pango.EllipsizeMode.END)
            label.get_style_context().add_class("filename-label")
            box.pack_start(label, False, False, 0)
            self.flowbox.add(box)

    def _on_button(self, widget, event):
        child = widget.get_child_at_pos(int(event.x), int(event.y))
        if child is None:
            return False
        idx = child.get_index()
        if idx == self._selected_index:
            self._set_wallpaper(self.wallpapers[idx])
        else:
            widget.select_child(child)
            self._selected_index = idx
        return True

    def _on_activate(self, flowbox, child):
        pass

    def _on_key(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            Gtk.main_quit()
        elif event.keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter):
            selected = self.flowbox.get_selected_children()
            if selected:
                idx = selected[0].get_index()
                self._set_wallpaper(self.wallpapers[idx])
        return False

    def _set_wallpaper(self, wallpaper):
        if not os.path.isfile(wallpaper):
            return
        try:
            subprocess.run(["xwallpaper", "--zoom", wallpaper], check=True)
            with open(WALLPAPER_CONF, "w") as f:
                f.write(wallpaper + "\n")
        except Exception as e:
            notify(f"Failed: {e}")
        Gtk.main_quit()


if __name__ == "__main__":
    win = WallpaperPicker()
    win.show_all()
    Gtk.main()

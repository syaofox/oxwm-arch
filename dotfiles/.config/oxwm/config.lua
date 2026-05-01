---@meta
-------------------------------------------------------------------------------
-- OXWM Configuration File
-------------------------------------------------------------------------------
-- This is the default configuration for OXWM, a dynamic window manager.
-- Edit this file and reload with Mod+Shift+R (no compilation needed)
--
-- For more information about configuring OXWM, see the documentation.
-- The Lua Language Server provides autocomplete and type checking.
-------------------------------------------------------------------------------

---Load type definitions for LSP
---@module 'oxwm'

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------
-- Define your variables here for easy customization throughout the config.
-- This makes it simple to change keybindings, colors, and settings in one place.

-- Modifier key: "Mod4" is the Super/Windows key, "Mod1" is Alt
local modkey = "Mod4"

-- Terminal emulator command (defaults to alacritty)
local terminal = "wezterm"

-- Color palette - customize these to match your theme
-- Alternatively you can import other files in here, such as
-- local colors = require("colors.lua") and make colors.lua a file
-- in the ~/.config/oxwm directory
local colors = require("colors.custom") -- Example of importing a separate colors file;

-- Workspace tags - can be numbers, names, or icons (requires a Nerd Font)
local tags = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
-- local tags = { "", "󰊯", "", "", "󰙯", "󱇤", "", "󱘶", "󰧮" } -- Example of nerd font icon tags

-- Font for the status bar (use "fc-list" to see available fonts)
local bar_font = "JetBrainsMono Nerd Font Propo:style=Bold:size=10"


-- Define your blocks
-- Similar to widgets in qtile, or dwmblocks
local blocks = {

    -- 网速
    oxwm.bar.block.netspeed{
        format = "{tx}/{rx} Mbps",
        interface = "",  -- 留空则自动检测
        interval = 2,
        color = colors.lavender,
        underline = false,
        click = "nm-connection-editor",
    },
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.sep,
        underline = false,
    }),

    -- GPU监控，支持NVIDIA和AMD显卡
    oxwm.bar.block.gpu({
        format = "GPU {gpu_util}% VRAM {vram_used}/{vram_total}G",
        interval = 3,
        color = colors.lavender,
        underline = false,
        click = terminal .. " -e nvtop",
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.sep,
        underline = false,
    }),

    -- CPU监控，显示使用率百分比
    oxwm.bar.block.cpu({
        format = "CPU: {}%",
        interval = 2,
        color = colors.lavender,
        underline = false,
        click = terminal .. " start --class htop -- htop",
    }),
    -- 内存监控，显示已用和总内存（单位GB）
    oxwm.bar.block.ram({
        format = "Ram: {used}/{total} GB",
        interval = 5,
        color = colors.lavender,
        underline = false,
        click = terminal .. " start --class htop -- htop",
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.sep,
        underline = false,
    }),

    -- oxwm.bar.block.shell({
    --     format = "{}",
    --     command = "uname -r",
    --     interval = 999999999,
    --     color = colors.red,
    --     underline = false,
    -- }),
    -- oxwm.bar.block.static({
    --     text = "│",
    --     interval = 999999999,
    --     color = colors.sep,
    --     underline = false,
    -- }),
    oxwm.bar.block.datetime({
        format = "{}",
        date_format = "%m-%d %H:%M",
        interval = 1,
        color = colors.lavender,
        underline = false,
        click = "gnome-calendar",
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.sep,
        underline = false,
    }),

    oxwm.bar.block.static({
        text = "󰈀",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
        click = "nm-connection-editor",
    }),
    oxwm.bar.block.static({
        text = "",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
        click = "pavucontrol",
    }),
    oxwm.bar.block.static({
        text = "",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
        click = "rofi-sysact.sh",
    }),
    -- oxwm.bar.block.static({
    --     text = "│",
    --     interval = 999999999,
    --     color = colors.sep,
    --     underline = false,
    -- }),
    -- oxwm.bar.block.shell({
    --     format = "Vol: {}%",
    --     command = "pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%'",
    --     interval = 1,
    --     color = colors.red,
    --     underline = false,
    --     click = "pavucontrol",
    -- }),1
    
    -- Uncomment to add battery status (useful for laptops)
    -- oxwm.bar.block.battery({
    --     format = "Bat: {}%",
    --     charging = "⚡ Bat: {}%",
    --     discharging = "- Bat: {}%",
    --     full = "✓ Bat: {}%",
    --     interval = 30,
    --     color = colors.green,
    --     underline = true,
    --     -- click: run a command when the block is clicked
    --     -- click = "alacritty -e btop",
    --     -- click = { command = "bluetui", floating = true },
    -- }),
};

-------------------------------------------------------------------------------
-- Basic Settings
-------------------------------------------------------------------------------
oxwm.set_terminal(terminal)
oxwm.set_modkey(modkey) -- This is for Mod + mouse binds, such as drag/resize
oxwm.set_tags(tags)

-- Set default layout (tiling by default)
-- oxwm.set_layout("tiling")

-------------------------------------------------------------------------------
-- Layouts
-------------------------------------------------------------------------------
-- Set custom symbols for layouts (displayed in the status bar)
-- Available layouts: "tiling", "normie" (floating), "grid", "monocle", "tabbed"
oxwm.set_layout_symbol("tiling", "[T]")
oxwm.set_layout_symbol("normie", "[F]")
oxwm.set_layout_symbol("tabbed", "[=]")

-- Set default layout of specific tag (tag_index, layout_name)
-- Unset value uses oxwm.set_layout value
-- oxwm.set_tag_layout(1, "grid")

-------------------------------------------------------------------------------
-- Appearance
-------------------------------------------------------------------------------
-- Border configuration

-- Width in pixels
oxwm.border.set_width(2)
-- Color of focused window border
oxwm.border.set_focused_color(colors.blue)
-- Color of unfocused window borders
oxwm.border.set_unfocused_color(colors.grey)

-- Where floating windows spawn: "top-left", "top-center", "top-right",
-- "center-left", "center", "center-right", "bottom-left", "bottom-center", "bottom-right"
oxwm.set_floating_position("center")

-- Smart Enabled = No border if 1 window
oxwm.gaps.set_smart(enabled)
-- Inner gaps (horizontal, vertical) in pixels
oxwm.gaps.set_inner(5, 5)
-- Outer gaps (horizontal, vertical) in pixels
oxwm.gaps.set_outer(5, 5)

-------------------------------------------------------------------------------
-- Window Rules
-------------------------------------------------------------------------------
-- Rules allow you to automatically configure windows based on their properties
-- You can match windows by class, instance, title, or role
-- Available properties: floating, tag, fullscreen, etc.
--
-- Common use cases:
-- - Force floating for certain applications (dialogs, utilities)
-- - Send specific applications to specific workspaces
-- - Configure window behavior based on title or class

-- Examples (uncomment to use):
oxwm.rule.add({ class = "Xfce4-clipman-history", floating = true, focus = true })
oxwm.rule.add({ class = "zenity", floating = true, focus = true })
oxwm.rule.add({ class = "org.gnome.FileRoller", floating = true, focus = true })
oxwm.rule.add({ class = "Xviewer", floating = true, focus = true })
oxwm.rule.add({ class = "Io.github.celluloid_player.Celluloid", floating = true, focus = true })
oxwm.rule.add({ class = "mpv", floating = true, focus = true })
oxwm.rule.add({ class = "Localsend", tag = 9, focus = false })
oxwm.rule.add({ class = "FreeFileSync", tag = 9, focus = false })
oxwm.rule.add({ class = "htop", floating = true, focus = true })
oxwm.rule.add({ class = "nvtop", floating = true, focus = true })
oxwm.rule.add({ class = "Nsxiv", floating = true, focus = true })
oxwm.rule.add({ class = "Sxiv", floating = true, focus = true })
oxwm.rule.add({ class = "Nm-connection-editor", floating = true, focus = true })
oxwm.rule.add({ class = "pavucontrol", floating = true, focus = true })

-- oxwm.rule.add({ class = "Alacritty", tag = 9, focus = true })
-- oxwm.rule.add({ class = "firefox", title = "Library", floating = true })
-- oxwm.rule.add({ class = "firefox", tag = 2 })
-- oxwm.rule.add({ instance = "mpv", floating = true })

-- To find window properties, use xprop and click on the window
-- WM_CLASS(STRING) shows both instance and class (instance, class)

-------------------------------------------------------------------------------
-- Status Bar Configuration
-------------------------------------------------------------------------------
-- Font configuration
oxwm.bar.set_font(bar_font)

-- Position configuration (top/bottom, top is default)
-- oxwm.bar.set_position("bottom")

-- Set your blocks here (defined above)
oxwm.bar.set_blocks(blocks)

-- Bar color schemes (for workspace tag display)
-- Parameters: foreground, background, border

-- Unoccupied tags
oxwm.bar.set_scheme_normal(colors.sep, colors.bg, colors.sep)
-- Occupied tags
oxwm.bar.set_scheme_occupied(colors.fg, colors.bg, colors.cyan)
-- Currently selected tag
oxwm.bar.set_scheme_selected(colors.cyan, colors.bg, colors.purple)
-- Urgent tags (windows requesting attention)
oxwm.bar.set_scheme_urgent(colors.fg, colors.red, colors.red)

-- Bar background color (overrides scheme_normal background)
oxwm.bar.set_background(colors.bg)

-- Border width for the selected tag underline in pixels
oxwm.bar.set_border_width(2)


-- Active window title in bar (color and max chars before truncation)
oxwm.bar.set_active_title_color(colors.fg)
oxwm.bar.set_active_title_max_chars(100)


-- Separators between bar zones: tag↔layout, layout↔title, title↔blocks
-- Each takes a character and an optional color (defaults to scheme_normal.foreground)
oxwm.bar.set_separator_tag_layout("", colors.sep)
oxwm.bar.set_separator_layout_title(" >", colors.fg)
oxwm.bar.set_separator_title_blocks("", colors.sep)



-- Hide tags that have no windows and are not selected
-- oxwm.bar.set_hide_vacant_tags(true)

-------------------------------------------------------------------------------
-- Keybindings
-------------------------------------------------------------------------------
-- Keybindings are defined using oxwm.key.bind(modifiers, key, action)
-- Modifiers: {"Mod4"}, {"Mod1"}, {"Shift"}, {"Control"}, or combinations like {"Mod4", "Shift"}
-- Keys: Use uppercase for letters (e.g., "Return", "H", "J", "K", "L")
-- Actions: Functions that return actions (e.g., oxwm.spawn(), oxwm.client.kill())
--
-- A list of available keysyms can be found in the X11 keysym definitions.
-- Common keys: Return, Space, Tab, Escape, Backspace, Delete, Left, Right, Up, Down

-- Basic window management

oxwm.key.bind({ modkey }, "Return", oxwm.spawn_terminal())
-- Launch Dmenu
oxwm.key.bind({ modkey }, "Space", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh menu" }))
-- Copy screenshot to clipboard
-- oxwm.key.bind({ modkey }, "S", oxwm.spawn({ "sh", "-c", "maim -s | xclip -selection clipboard -t image/png" }))
oxwm.key.bind({ modkey }, "Q", oxwm.client.kill())
oxwm.key.bind({ modkey }, "W", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh web" }))
oxwm.key.bind({ modkey, "Shift" }, "W", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh switch-wallpaper" }))

oxwm.key.bind({ modkey }, "E", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh file" }))
oxwm.key.bind({ modkey, "Shift" }, "L", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh lock" }))
oxwm.key.bind({ modkey, "Shift" }, "C", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh calc" }))
oxwm.key.bind({ modkey, "Shift" }, "A", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh save" }))
oxwm.key.bind({ modkey }, "A", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh clip" }))
oxwm.key.bind({ modkey }, "V", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh clipman" }))


oxwm.key.bind({ modkey, "Shift" }, "T", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh theme" }))
oxwm.key.bind({ modkey, "Shift" }, "Delete", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh sys" }))
oxwm.key.bind({ modkey, }, "S", oxwm.spawn({ "sh", "-c", "oxwmcmd.sh search" }))


-- Keybind overlay - Shows important keybindings on screen
oxwm.key.bind({ modkey, "Shift" }, "Slash", oxwm.show_keybinds())

-- Window state toggles
oxwm.key.bind({ modkey, "Shift" }, "Z", oxwm.client.toggle_fullscreen())
oxwm.key.bind({ modkey, "Shift" }, "F", oxwm.client.toggle_floating())

-- Layout management
oxwm.key.bind({ modkey }, "F", oxwm.layout.set("normie"))
oxwm.key.bind({ modkey }, "T", oxwm.layout.set("tiling"))
-- Cycle through layouts
oxwm.key.bind({ modkey }, "N", oxwm.layout.cycle())

-- Master area controls (tiling layout)

-- Decrease/Increase master area width
oxwm.key.bind({ modkey }, "Comma", oxwm.set_master_factor(-5))
oxwm.key.bind({ modkey }, "Period", oxwm.set_master_factor(5))
-- Enable tiled resize mode: Mod+RMB drag adjusts mfact instead of floating
-- oxwm.tiled_resize_mode(true)
-- Increment/Decrement number of master windows
-- oxwm.key.bind({ modkey }, "I", oxwm.inc_num_master(1))
-- oxwm.key.bind({ modkey }, "P", oxwm.inc_num_master(-1))

-- Gaps toggle
oxwm.key.bind({ modkey }, "A", oxwm.toggle_gaps())
-- Bar toggle
oxwm.key.bind({ modkey }, "B", oxwm.toggle_bar())

-- Window manager controls
oxwm.key.bind({ modkey, "Shift" }, "Q", oxwm.quit())
oxwm.key.bind({ modkey, "Shift" }, "R", oxwm.restart())

-- Focus movement [1 for up in the stack, -1 for down]
oxwm.key.bind({ modkey }, "J", oxwm.client.focus_stack(1))
oxwm.key.bind({ modkey }, "K", oxwm.client.focus_stack(-1))

-- Window movement (swap position in stack)
oxwm.key.bind({ modkey, "Shift" }, "J", oxwm.client.move_stack(1))
oxwm.key.bind({ modkey, "Shift" }, "K", oxwm.client.move_stack(-1))

-- Multi-monitor support

-- Focus next/previous Monitors
oxwm.key.bind({ modkey }, "Comma", oxwm.monitor.focus(-1))
oxwm.key.bind({ modkey }, "Period", oxwm.monitor.focus(1))
-- Move window to next/previous Monitors
-- oxwm.key.bind({ modkey, "Shift" }, "Comma", oxwm.monitor.tag(-1))
-- oxwm.key.bind({ modkey, "Shift" }, "Period", oxwm.monitor.tag(1))

-- Workspace (tag) navigation
-- Switch to workspace N (tags are 0-indexed, so tag "1" is index 0)
oxwm.key.bind({ modkey }, "1", oxwm.tag.view(0))
oxwm.key.bind({ modkey }, "2", oxwm.tag.view(1))
oxwm.key.bind({ modkey }, "3", oxwm.tag.view(2))
oxwm.key.bind({ modkey }, "4", oxwm.tag.view(3))
oxwm.key.bind({ modkey }, "5", oxwm.tag.view(4))
oxwm.key.bind({ modkey }, "6", oxwm.tag.view(5))
oxwm.key.bind({ modkey }, "7", oxwm.tag.view(6))
oxwm.key.bind({ modkey }, "8", oxwm.tag.view(7))
oxwm.key.bind({ modkey }, "9", oxwm.tag.view(8))

-- Move focused window to workspace N
oxwm.key.bind({ modkey, "Shift" }, "1", oxwm.tag.move_to(0))
oxwm.key.bind({ modkey, "Shift" }, "2", oxwm.tag.move_to(1))
oxwm.key.bind({ modkey, "Shift" }, "3", oxwm.tag.move_to(2))
oxwm.key.bind({ modkey, "Shift" }, "4", oxwm.tag.move_to(3))
oxwm.key.bind({ modkey, "Shift" }, "5", oxwm.tag.move_to(4))
oxwm.key.bind({ modkey, "Shift" }, "6", oxwm.tag.move_to(5))
oxwm.key.bind({ modkey, "Shift" }, "7", oxwm.tag.move_to(6))
oxwm.key.bind({ modkey, "Shift" }, "8", oxwm.tag.move_to(7))
oxwm.key.bind({ modkey, "Shift" }, "9", oxwm.tag.move_to(8))

-- Combo view (view multiple tags at once) {argos_nothing}
-- Example: Mod+Ctrl+2 while on tag 1 will show BOTH tags 1 and 2
oxwm.key.bind({ modkey, "Control" }, "1", oxwm.tag.toggleview(0))
oxwm.key.bind({ modkey, "Control" }, "2", oxwm.tag.toggleview(1))
oxwm.key.bind({ modkey, "Control" }, "3", oxwm.tag.toggleview(2))
oxwm.key.bind({ modkey, "Control" }, "4", oxwm.tag.toggleview(3))
oxwm.key.bind({ modkey, "Control" }, "5", oxwm.tag.toggleview(4))
oxwm.key.bind({ modkey, "Control" }, "6", oxwm.tag.toggleview(5))
oxwm.key.bind({ modkey, "Control" }, "7", oxwm.tag.toggleview(6))
oxwm.key.bind({ modkey, "Control" }, "8", oxwm.tag.toggleview(7))
oxwm.key.bind({ modkey, "Control" }, "9", oxwm.tag.toggleview(8))

-- Multi tag (window on multiple tags)
-- Example: Mod+Ctrl+Shift+2 puts focused window on BOTH current tag and tag 2
oxwm.key.bind({ modkey, "Control", "Shift" }, "1", oxwm.tag.toggletag(0))
oxwm.key.bind({ modkey, "Control", "Shift" }, "2", oxwm.tag.toggletag(1))
oxwm.key.bind({ modkey, "Control", "Shift" }, "3", oxwm.tag.toggletag(2))
oxwm.key.bind({ modkey, "Control", "Shift" }, "4", oxwm.tag.toggletag(3))
oxwm.key.bind({ modkey, "Control", "Shift" }, "5", oxwm.tag.toggletag(4))
oxwm.key.bind({ modkey, "Control", "Shift" }, "6", oxwm.tag.toggletag(5))
oxwm.key.bind({ modkey, "Control", "Shift" }, "7", oxwm.tag.toggletag(6))
oxwm.key.bind({ modkey, "Control", "Shift" }, "8", oxwm.tag.toggletag(7))
oxwm.key.bind({ modkey, "Control", "Shift" }, "9", oxwm.tag.toggletag(8))


oxwm.key.bind({}, "XF86AudioLowerVolume", oxwm.spawn({ "sh", "-c", "~/.local/bin/volume.sh down" }))
oxwm.key.bind({}, "XF86AudioRaiseVolume", oxwm.spawn({ "sh", "-c", "~/.local/bin/volume.sh up" }))
oxwm.key.bind({}, "XF86AudioMute", oxwm.spawn({ "sh", "-c", "~/.local/bin/volume.sh mute" }))


-------------------------------------------------------------------------------
-- Advanced: Keychords
-------------------------------------------------------------------------------
-- Keychords allow you to bind multiple-key sequences (like Emacs or Vim)
-- Format: {{modifiers}, key1}, {{modifiers}, key2}, ...
-- Example: Press Mod4+Space, then release and press T to spawn a terminal
-- oxwm.key.chord({
--     { { modkey }, "Space" },
--     { {},         "T" }
-- }, oxwm.spawn_terminal()) 

-------------------------------------------------------------------------------
-- Autostart
-------------------------------------------------------------------------------
-- Commands to run once when OXWM starts
-- Uncomment and modify these examples, or add your own

oxwm.autostart("~/.local/share/oxwm/autostart.sh") 

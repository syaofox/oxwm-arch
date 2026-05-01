local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- config.front_end = "Software"

local theme_path = os.getenv('HOME') .. '/.config/wezterm/theme.lua'
local theme_func = loadfile(theme_path)
if theme_func then
  local theme = theme_func()
  if theme then
    config.colors = theme
  end
end

-- 选中即复制 (Selection to Clipboard)
config.selection_word_boundary = " \t\n{}[];\"',`"


config.font = wezterm.font('JetBrainsMonoNL Nerd Font')
config.font_size = 10.0
config.use_ime = true
config.xim_im_name = 'fcitx'

config.default_cursor_style = 'BlinkingUnderline'
config.cursor_blink_rate = 500
config.cursor_thickness = 2
config.enable_tab_bar = false
config.window_background_opacity = 1

return config
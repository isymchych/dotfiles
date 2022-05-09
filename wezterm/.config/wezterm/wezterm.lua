local wezterm = require 'wezterm';

return {
  enable_wayland = true,

  font = wezterm.font("Iosevka Term"),
  font_size = 14.0,

  color_scheme = "Builtin Solarized Light",
  hide_tab_bar_if_only_one_tab = true,

  scrollback_lines = 20000,

  skip_close_confirmation_for_processes_named = {
    "bash", "sh", "zsh", "fish"
  },

  -- need this so that solarized ls looks good
  bold_brightens_ansi_colors = false,
}

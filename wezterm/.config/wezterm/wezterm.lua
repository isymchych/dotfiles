local wezterm = require 'wezterm';
local mux = wezterm.mux;
local act = wezterm.action;

local LIGHT_SCHEME = "Solarized (light) (terminal.sexy)"
local DARK_SCHEME = "Solarized Dark - Patched"

local function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return DARK_SCHEME
  end
  return LIGHT_SCHEME
end

wezterm.on("window-config-reloaded", function(window)
  local appearance = window:get_appearance()
  local scheme = scheme_for_appearance(appearance)
  local overrides = window:get_config_overrides() or {}
  if overrides.color_scheme ~= scheme then
    overrides.color_scheme = scheme
    window:set_config_overrides(overrides)
  end
end)

wezterm.on('spawn-window-in-current-cwd', function(window, pane)
  local cwd_uri = pane:get_current_working_dir();
  local cwd = cwd_uri and cwd_uri.file_path or nil;
  if cwd then
    mux.spawn_window{
      workspace = window:active_workspace(),
      cwd = cwd,
    };
    return;
  end
  mux.spawn_window{
    workspace = window:active_workspace(),
  };
end);

return {
  enable_wayland = true,

  font = wezterm.font("Iosevka Term Medium"),
  font_size = 16.0,

  color_scheme = wezterm.gui and scheme_for_appearance(wezterm.gui.get_appearance()) or LIGHT_SCHEME,
  hide_tab_bar_if_only_one_tab = true,

  scrollback_lines = 20000,

  skip_close_confirmation_for_processes_named = {
    "bash", "sh", "zsh", "fish"
  },

  keys = {
    {
      key = "Enter",
      mods = "ALT",
      action = act.EmitEvent("spawn-window-in-current-cwd"),
    },
  },

  -- need this so that solarized ls looks good
  bold_brightens_ansi_colors = false,
}

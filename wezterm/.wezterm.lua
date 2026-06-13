-- ╭──────────────────────────────────────────────────────────────╮
-- │  WezTerm · Vesper                                              │
-- │  Pure-black, near-monochrome, single amber accent.            │
-- │  Cohesive with the Min/Vesper VS Code setup.                  │
-- ╰──────────────────────────────────────────────────────────────╯
local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ── Vesper palette ────────────────────────────────────────────────
local vesper = {
  bg      = "#101010",
  bg_alt  = "#161616", -- titlebar / active tab
  fg      = "#e0e0e0",
  white   = "#ffffff",
  amber   = "#ffc799", -- the accent
  mint    = "#99ffe4", -- secondary accent (success, strings)
  red     = "#ff8080",
  gray    = "#8b8b8b",
  dim     = "#535353",
}

-- ── Font ──────────────────────────────────────────────────────────
-- JetBrains Mono Nerd Font: ligatures + the glyphs Starship needs.
config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono Nerd Font", weight = "Regular" },
  "Geist Mono", -- text fallback (no Nerd glyphs)
})
config.font_size = 14.5
config.line_height = 1.25
config.cell_width = 1.0
-- Ligatures on; tasteful contextual alternates.
config.harfbuzz_features = { "calt=1", "liga=1", "ss01=1" }
config.freetype_load_target = "Light"
config.freetype_render_target = "HorizontalLcd"

-- ── Colors ────────────────────────────────────────────────────────
config.colors = {
  foreground   = vesper.fg,
  background   = vesper.bg,
  cursor_bg    = vesper.amber,
  cursor_fg    = vesper.bg,
  cursor_border = vesper.amber,
  selection_bg = "#2a2a2a",
  selection_fg = vesper.white,
  scrollbar_thumb = "#2a2a2a",
  split        = "#1f1f1f",

  -- ANSI: Vesper is intentionally monochrome with amber + mint accents.
  ansi = {
    vesper.bg,    -- black
    vesper.red,   -- red
    vesper.mint,  -- green
    vesper.amber, -- yellow
    "#b3b3b3",    -- blue   → warm gray (desaturated, Vesper-style)
    vesper.amber, -- magenta→ amber
    vesper.mint,  -- cyan   → mint
    vesper.white, -- white
  },
  brights = {
    vesper.dim,   -- bright black
    vesper.red,   -- bright red
    vesper.mint,  -- bright green
    vesper.amber, -- bright yellow
    "#c0c0c0",    -- bright blue → gray
    vesper.amber, -- bright magenta
    vesper.mint,  -- bright cyan
    vesper.white, -- bright white
  },
}

-- Subtle depth without hurting readability. Bump opacity to 1.0 if you
-- ever want zero transparency.
config.window_background_opacity = 0.94
config.macos_window_background_blur = 28

-- ── Tabs (flat, minimal — no powerline chrome) ────────────────────
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 28
config.show_new_tab_button_in_tab_bar = false
config.colors.tab_bar = {
  background = vesper.bg,
  active_tab   = { bg_color = vesper.bg, fg_color = vesper.amber, intensity = "Bold" },
  inactive_tab = { bg_color = vesper.bg, fg_color = vesper.dim },
  inactive_tab_hover = { bg_color = vesper.bg_alt, fg_color = vesper.fg, italic = false },
  new_tab       = { bg_color = vesper.bg, fg_color = vesper.dim },
  new_tab_hover = { bg_color = vesper.bg_alt, fg_color = vesper.amber },
}

-- Clean tab title: " 1 · dirname ".  No arrows, no icons clutter.
wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
  local title = tab.tab_title
  if not title or #title == 0 then
    title = tab.active_pane.title or "shell"
  end
  title = wezterm.truncate_right(title, max_width - 6)
  local idx = tab.tab_index + 1
  local zoom = tab.active_pane.is_zoomed and "  " or ""
  return string.format("  %d · %s%s ", idx, title, zoom)
end)

-- ── Window chrome ─────────────────────────────────────────────────
config.window_decorations = "RESIZE" -- borderless; swap to "INTEGRATED_BUTTONS|RESIZE" for traffic lights
config.window_padding = { left = 16, right = 16, top = 12, bottom = 8 }
config.window_frame = {
  font = wezterm.font({ family = "JetBrainsMono Nerd Font", weight = "Medium" }),
  font_size = 13.0,
  active_titlebar_bg = vesper.bg,
  inactive_titlebar_bg = vesper.bg,
}
config.adjust_window_size_when_changing_font_size = false
config.initial_cols = 120
config.initial_rows = 34

-- ── Cursor ────────────────────────────────────────────────────────
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 600
config.cursor_blink_ease_in = "EaseOut"
config.cursor_blink_ease_out = "EaseOut"

-- Focused pane pops; others dim slightly.
config.inactive_pane_hsb = { saturation = 0.9, brightness = 0.82 }

-- ── Performance & behavior ────────────────────────────────────────
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 120          -- smooth on ProMotion displays
config.animation_fps = 60
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
config.check_for_updates = false
config.warn_about_missing_glyphs = false

-- ── Keybindings (preserved from your setup) ───────────────────────
config.keys = {
  { key = "d", mods = "CMD",            action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d", mods = "CMD|SHIFT",      action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  { key = "[", mods = "CMD",            action = act.ActivatePaneDirection("Prev") },
  { key = "]", mods = "CMD",            action = act.ActivatePaneDirection("Next") },
  { key = "LeftArrow",  mods = "CMD|OPT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = "CMD|OPT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow",    mods = "CMD|OPT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow",  mods = "CMD|OPT", action = act.ActivatePaneDirection("Down") },

  { key = "w", mods = "CMD",            action = act.CloseCurrentPane({ confirm = true }) },
  { key = "w", mods = "CMD|SHIFT",      action = act.CloseCurrentTab({ confirm = true }) },

  { key = "k", mods = "CMD",            action = act.Multiple({
      act.ClearScrollback("ScrollbackAndViewport"),
      act.SendKey({ key = "L", mods = "CTRL" }),
  }) },

  { key = "Space", mods = "CMD|SHIFT",  action = act.QuickSelect },
  { key = "r",     mods = "CMD|SHIFT",  action = act.ReloadConfiguration },
}

for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = "CMD", action = act.ActivateTab(i - 1) })
end

return config

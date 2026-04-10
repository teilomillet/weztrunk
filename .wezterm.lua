local wezterm = require 'wezterm'
local act = wezterm.action
local builtin_schemes = wezterm.color.get_builtin_schemes()

local config = wezterm.config_builder()
local weztrunk_switch_runner = wezterm.home_dir .. '/.local/bin/weztrunk-switch'
local weztrunk_cmd_runner = wezterm.home_dir .. '/.local/bin/weztrunk'
local weztrunk_manual_runner = wezterm.home_dir .. '/.local/bin/weztrunk-manual'

local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end

  return 'Dark'
end

local function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'WezTrunk Gruvbox dark, hard'
  end

  return 'WezTrunk Gruvbox light, hard'
end

local function deep_copy(value)
  if type(value) ~= 'table' then
    return value
  end

  local copy = {}
  for key, nested_value in pairs(value) do
    copy[key] = deep_copy(nested_value)
  end

  return copy
end

local function with_accent_ansi(base_scheme, accent, bright_accent)
  local scheme = deep_copy(base_scheme)
  scheme.ansi[3] = accent
  scheme.ansi[7] = accent
  scheme.brights[3] = bright_accent
  scheme.brights[7] = bright_accent
  return scheme
end

local function path_from_cwd_uri(cwd)
  if not cwd then
    return nil
  end

  if type(cwd) == 'table' then
    if cwd.scheme == 'file' then
      return cwd.file_path
    end

    return nil
  end

  if type(cwd) == 'string' then
    local parsed = wezterm.url.parse(cwd)
    if parsed and parsed.scheme == 'file' then
      return parsed.file_path
    end
  end

  return nil
end

local function basename(path)
  if not path then
    return nil
  end

  return path:match('([^/]+)/?$') or path
end

local function repo_branch_from_path(path)
  if not path or path == '' then
    return nil, nil
  end

  local repo_root, branch = path:match('^(.-)/%.worktrees/([^/]+)')
  if repo_root and branch then
    return basename(repo_root), branch
  end

  return basename(path), nil
end

local function trim_label(label, max_width)
  if not label or not max_width or max_width <= 0 or #label <= max_width then
    return label
  end

  if max_width <= 3 then
    return label:sub(1, max_width)
  end

  return label:sub(1, max_width - 3) .. '...'
end

local function split(direction)
  return act.SplitPane {
    direction = direction,
    size = { Percent = 50 },
  }
end

local function rename_tab()
  return act.PromptInputLine {
    description = 'Rename current tab',
    action = wezterm.action_callback(function(window, _, line)
      if line then
        window:active_tab():set_title(line)
      end
    end),
  }
end

local function switch_workspace()
  return act.PromptInputLine {
    description = 'Create or switch to workspace',
    action = wezterm.action_callback(function(window, pane, line)
      if line and line ~= '' then
        window:perform_action(act.SwitchToWorkspace { name = line }, pane)
      end
    end),
  }
end

local function current_local_cwd(pane)
  return path_from_cwd_uri(pane:get_current_working_dir())
end

local function spawn_worktrunk_agent(window, pane, opts)
  local cwd = current_local_cwd(pane)
  if not cwd then
    window:toast_notification(
      'Worktrunk',
      'Current pane has no local file-path cwd. Run this from a local shell pane.',
      nil,
      5000
    )
    return
  end

  local mode = 'pick'
  if opts.create then
    mode = 'create'
  elseif opts.branch then
    mode = 'switch'
  end

  local args = { weztrunk_switch_runner, mode, cwd }

  if opts.branch then
    table.insert(args, opts.branch)
  end

  if opts.prompt and opts.prompt ~= '' then
    table.insert(args, '--')
    table.insert(args, opts.prompt)
  end

  window:perform_action(
    act.SpawnCommandInNewTab {
      cwd = cwd,
      domain = 'DefaultDomain',
      args = args,
    },
    pane
  )

  window:toast_notification(
    'Worktrunk',
    opts.message or 'Opening Worktrunk + agent in a new tab',
    nil,
    3000
  )
end

local function worktrunk_picker()
  return wezterm.action_callback(function(window, pane)
    spawn_worktrunk_agent(window, pane, {
      message = 'Opening Worktrunk picker, then launching or re-attaching the code agent',
    })
  end)
end

local function worktrunk_create_branch()
  return act.PromptInputLine {
    description = 'Create a worktree branch and launch or re-attach the code agent',
    action = wezterm.action_callback(function(window, pane, line)
      if line and line ~= '' then
        spawn_worktrunk_agent(window, pane, {
          create = true,
          branch = line,
          message = 'Creating worktree and launching or re-attaching the code agent',
        })
      end
    end),
  }
end

local function open_weztrunk_manual()
  return wezterm.action_callback(function(window, pane)
    window:perform_action(
      act.SpawnCommandInNewTab {
        cwd = wezterm.home_dir,
        domain = 'DefaultDomain',
        args = { weztrunk_manual_runner },
      },
      pane
    )

    window:toast_notification(
      'WezTrunk',
      'Opening the WezTrunk manual in a new tab',
      nil,
      3000
    )
  end)
end

local function search_weztrunk_manual()
  return act.PromptInputLine {
    description = 'Search the WezTrunk manual',
    action = wezterm.action_callback(function(window, pane, line)
      local args = { weztrunk_cmd_runner, 'man' }
      if line and line ~= '' then
        table.insert(args, line)
      end

      window:perform_action(
        act.SpawnCommandInNewTab {
          cwd = wezterm.home_dir,
          domain = 'DefaultDomain',
          args = args,
        },
        pane
      )
    end),
  }
end

wezterm.on('update-right-status', function(window, _)
  local parts = { window:active_workspace() }
  if window:leader_is_active() then
    table.insert(parts, 1, 'LEADER')
  end

  window:set_right_status(' ' .. table.concat(parts, '  ') .. ' ')
end)

wezterm.on('augment-command-palette', function(_, _)
  return {
    {
      brief = 'Worktrunk: pick worktree and launch agent',
      doc = 'Runs `wt switch` in the current local repo, opens the interactive picker, then launches or re-attaches the configured code agent in a new tab using dtach plus the configured sleep guard.',
      action = worktrunk_picker(),
    },
    {
      brief = 'WezTrunk: open manual',
      doc = 'Opens the local WezTrunk manual in a new tab, including the current shell commands, WezTerm shortcuts, Worktrunk aliases, and multi-agent configuration model.',
      action = open_weztrunk_manual(),
    },
    {
      brief = 'WezTrunk: search manual',
      doc = 'Prompts for a topic, then opens a new tab with a focused manual search. Useful for quick lookups like remove, merge, session, or provider.',
      action = search_weztrunk_manual(),
    },
    {
      brief = 'Worktrunk: create branch and launch agent',
      doc = 'Prompts for a branch name, then runs `wt switch --create` from the current local repo and opens the configured code agent in the resulting worktree.',
      action = worktrunk_create_branch(),
    },
  }
end)

wezterm.on('format-tab-title', function(tab, _, _, _, _, max_width)
  local label
  if tab.tab_title and tab.tab_title ~= '' then
    label = tab.tab_title
  else
    local cwd = path_from_cwd_uri(tab.active_pane.current_working_dir)
    local repo, branch = repo_branch_from_path(cwd)
    if repo and branch then
      label = repo .. ':' .. branch
    else
      label = repo or tab.active_pane.title or 'shell'
    end
  end

  return ' ' .. trim_label(label, max_width - 2) .. ' '
end)

config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.integrated_title_button_alignment = 'Left'
config.color_schemes = {
  ['WezTrunk Gruvbox dark, hard'] = with_accent_ansi(
    builtin_schemes['Gruvbox dark, hard (base16)'],
    '#ee8959',
    '#f4aa88'
  ),
  ['WezTrunk Gruvbox light, hard'] = with_accent_ansi(
    builtin_schemes['Gruvbox light, hard (base16)'],
    '#4c1d95',
    '#5b21b6'
  ),
}
config.color_scheme = scheme_for_appearance(get_appearance())
config.set_environment_variables = {
  WEZTRUNK_APPEARANCE = get_appearance(),
}
config.text_min_contrast_ratio = 4.5
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 32
config.window_padding = {
  left = 8,
  right = 8,
  top = 6,
  bottom = 6,
}
config.initial_cols = 140
config.initial_rows = 38
config.scrollback_lines = 10000
config.adjust_window_size_when_changing_font_size = false
config.unzoom_on_switch_pane = true
config.enable_kitty_keyboard = true

config.leader = { key = 'b', mods = 'CMD', timeout_milliseconds = 1000 }

config.keys = {
  { key = 'd', mods = 'CMD', action = split 'Right' },
  { key = 'd', mods = 'CMD|SHIFT', action = split 'Down' },
  { key = 'Enter', mods = 'CMD', action = act.TogglePaneZoomState },
  { key = 'f', mods = 'CMD|SHIFT', action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 'g', mods = 'CMD|SHIFT', action = worktrunk_picker() },
  { key = 'l', mods = 'CMD|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|TABS|WORKSPACES|COMMANDS|KEY_ASSIGNMENTS' } },
  { key = 'm', mods = 'CMD|SHIFT', action = open_weztrunk_manual() },
  { key = 'p', mods = 'CMD|SHIFT', action = act.ActivateCommandPalette },
  { key = '/', mods = 'CMD|SHIFT', action = search_weztrunk_manual() },
  { key = 'r', mods = 'CMD|SHIFT', action = act.ReloadConfiguration },
  { key = 'Space', mods = 'CMD|SHIFT', action = act.QuickSelect },
  { key = '[', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(1) },
  { key = 'h', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Right' },
  { key = 'LeftArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Left' },
  { key = 'DownArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Down' },
  { key = 'UpArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Up' },
  { key = 'RightArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Right' },
  { key = 'h', mods = 'CMD|CTRL', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'j', mods = 'CMD|CTRL', action = act.AdjustPaneSize { 'Down', 3 } },
  { key = 'k', mods = 'CMD|CTRL', action = act.AdjustPaneSize { 'Up', 3 } },
  { key = 'l', mods = 'CMD|CTRL', action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'LeftArrow', mods = 'CMD|CTRL', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'DownArrow', mods = 'CMD|CTRL', action = act.AdjustPaneSize { 'Down', 3 } },
  { key = 'UpArrow', mods = 'CMD|CTRL', action = act.AdjustPaneSize { 'Up', 3 } },
  { key = 'RightArrow', mods = 'CMD|CTRL', action = act.AdjustPaneSize { 'Right', 3 } },
  {
    key = 'LeftArrow',
    mods = 'OPT',
    action = act.SendKey { key = 'b', mods = 'ALT' },
  },
  {
    key = 'RightArrow',
    mods = 'OPT',
    action = act.SendKey { key = 'f', mods = 'ALT' },
  },
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'f', mods = 'LEADER', action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 'g', mods = 'LEADER', action = worktrunk_picker() },
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
  { key = 'm', mods = 'LEADER', action = open_weztrunk_manual() },
  { key = '/', mods = 'LEADER', action = search_weztrunk_manual() },
  { key = 'H', mods = 'LEADER', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'LEADER', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'K', mods = 'LEADER', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'L', mods = 'LEADER', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'o', mods = 'LEADER', action = act.ActivatePaneDirection 'Next' },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  { key = 'q', mods = 'LEADER', action = act.PaneSelect { show_pane_ids = true } },
  { key = 'r', mods = 'LEADER', action = switch_workspace() },
  { key = 's', mods = 'LEADER', action = split 'Down' },
  { key = 'v', mods = 'LEADER', action = split 'Right' },
  { key = 'w', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|TABS|WORKSPACES|COMMANDS|KEY_ASSIGNMENTS' } },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
  { key = 'G', mods = 'LEADER', action = worktrunk_create_branch() },
  { key = ',', mods = 'LEADER', action = rename_tab() },
  { key = '-', mods = 'LEADER', action = split 'Down' },
  { key = '\\', mods = 'LEADER', action = split 'Right' },
}

for i = 1, 8 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'CMD',
    action = act.ActivateTab(i - 1),
  })
end

table.insert(config.keys, {
  key = '9',
  mods = 'CMD',
  action = act.ActivateTab(-1),
})

return config

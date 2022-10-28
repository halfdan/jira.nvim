local has_telescope = pcall(require, "telescope")

if not has_telescope then
  error "This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)"
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")

local entry_display = require("telescope.pickers.entry_display")
local jira = require("jira")
local log = require("jira.log")
local smart_url_opener =
  require("telescope._extensions.jira.actions").smart_url_opener

---@type TelescopeJiraConfig
local config = {
  url_open_command = "open",
  url_open_plugin = nil,
  issuetypes = {
    Epic = {
      icon = "",
    },
    Bug = {
      icon = "",
    },
    Spike = {
      icon = "",
    },
    Story = {
      icon = "",
    },
    Task = {
      icon = "",
    },
    Subtask = {
      icon = "",
    },
    Project= {
      icon = "",
    },
    _ = {
      icon = "", -- unknown 
    },
  }
}

local function get_icon(name)
  local issuetypes = config.issuetypes

  if issuetypes[name] == nil then
    log.fmt_debug("%s is not a known issue type", name)
    return issuetypes["_"].icon
  else
    return issuetypes[name].icon
  end
end

local function projects(opts)
  opts = opts or {}

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 1 },
      { width = 10 },
      { remaining = true },
    },
  }
  local make_display = function(entry)
    return displayer {
      get_icon("Project"),
      { entry.key, "TelescopeResultsIdentifier" },
      entry.name,
    }
  end

  pickers.new(opts, {
    prompt_title = "Projects",
    debounce = 250,
    finder = finders.new_dynamic {
      fn = function (input)
        return jira.projects(input).items
      end,
      entry_maker = function (entry)
        return {
          value = entry,
          display = make_display,
          ordinal = entry.key,
          key = entry.key,
          name = entry.name
        }
      end,
    },
    -- TODO: Build better sorter that takes recency into account
    sorter = sorters.empty(),
    attach_mappings = function()
      actions.select_default:replace(smart_url_opener(config))
      return true
    end,
  }):find()
end

local function live_search(opts)
  opts = opts or {}
  -- opts.entry_maker = vim.F.if_nil(opts.entry_maker, gen_issue_display(opts))

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 1 },
      { width = 10 },
      { width = 20 },
      { remaining = true },
    },
  }
  local make_display = function(entry)
    local issuetype = entry.value.issuetype:gsub("-", "")
    return displayer {
      get_icon(issuetype),
      { entry.key, "TelescopeResultsIdentifier" },
      entry.creator,
      entry.summary
    }
  end

  pickers.new(opts, {
    prompt_title = "Search Jira Issues",
    debounce = 250,
    finder = finders.new_dynamic {
      fn = function (input)
        return jira.search(input, opts).items
      end,
      entry_maker = function (entry)
        return {
          value = entry,
          display = make_display,
          ordinal = entry.key,
          key = entry.key,
          creator = entry.creator,
          summary = entry.summary,
        }
      end,
    },
    -- TODO: Build better sorter that takes recency into account
    sorter = sorters.empty(),
    attach_mappings = function()
      actions.select_default:replace(smart_url_opener(config))
      return true
    end,
  }):find()
end

return require("telescope").register_extension {
  setup = function(ext_config)
    config = vim.tbl_deep_extend("force", config, ext_config)
  end,
  exports = {
    live_search = live_search,
    projects = projects,
  },
}

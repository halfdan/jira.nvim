local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local debounce = require("telescope.debounce")
local sorters = require("telescope.sorters")

local entry_display = require("telescope.pickers.entry_display")
local make_entry = require("telescope.make_entry")
local jira = require("jira")

-- TODO: Figure out why this doesn't work
-- local function gen_issue_display(opts)
--   opts = opts or {}
--
--   local displayer = entry_display.create {
--     separator = " ",
--     items = {
--       { width = 10 },
--       { width = 20 },
--       { remaining = true },
--     },
--   }
--   local make_display = function(entry)
--     return displayer {
--       { entry.issue, "TelescopeResultsIdentifier" },
--       entry.assignee,
--       entry.description
--     }
--   end
--
--   return function(entry)
--     return make_entry.set_default_entry_mt({
--       value = entry,
--       display = make_display,
--       ordinal = entry[1],
--       issue = entry[1],
--       assignee = entry[2],
--       description = entry[3]
--     }, opts)
--   end
-- end

local type_mapping = {
  Epic = "",
  Bug = "",
  Spike = "",
  Story = "",
  Task = "",
  Subtask = "",
  Project = "",
  _ = "", -- unknown 
}

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
      type_mapping["Project"],
      { entry.key, "TelescopeResultsIdentifier" },
      entry.name,
    }
  end

  pickers.new(opts, {
    prompt_title = "Projects",
    debounce = 250,
    finder = finders.new_dynamic {
      fn = function (input)
        return jira.projects(input)
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
      type_mapping[issuetype] or type_mapping["_"],
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
        return jira.search(input, opts)
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
  }):find()
end

return require("telescope").register_extension {
  -- setup = function(ext_config, config)
  --   -- access extension config and user config
  -- end,
  exports = {
    live_search = live_search,
    projects = projects,
  },
}

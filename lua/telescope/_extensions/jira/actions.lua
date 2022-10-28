local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local jira = require "jira"

local plugin_actions = {}

local url_plugin_function = {
  open_browser = "openbrowser#open",
  vim_external = "external#browser",
}

-- Smart URL opener.
--
-- If `config.url_open_plugin` is given, then open it using the plugin function
-- otherwise open it using `config.url_open_command`.
---@param config TelescopeJiraConfig
---@return function
function plugin_actions.smart_url_opener(config)
  return function(prompt_bufnr)
    local plugin_name = config.url_open_plugin
    local selection = action_state.get_selected_entry()
    local browse_url = jira.get_browse_url(selection.key)
    actions.close(prompt_bufnr)

    if plugin_name and plugin_name ~= "" then
      local fname = url_plugin_function[plugin_name]
      if not fname then
        local supported = table.concat(vim.tbl_keys(url_plugin_function), ", ")
        error(
          string.format(
            "Unsupported plugin opener: %s (%s)",
            plugin_name,
            supported
          )
        )
      end

      vim.fn[fname](browse_url)
    else
      os.execute(
        string.format('%s "%s"', config.url_open_command, browse_url)
      )
    end
  end
end

return plugin_actions

local post = require'plenary.curl'.post


local M = {}

local function make_request(endpoint, payload)
  local response = post(
    endpoint,
    {
      auth = M._config.username .. ":" .. M._config.token,
      body = vim.fn.json_encode(payload),
      headers = {
        content_type = "application/json",
      },
    }
  )
  return {
    data = vim.fn.json_decode(response.body),
    status = response.status,
  }
end

local function construct_jql(opts)
  opts = opts or {}
  local jql = ""

  if opts.text then
    jql = jql .. "text ~ " .. string.gsub(opts.text, "\"", "\\\"")
  end

  return jql
end

M.search = function (search_phrase, opts)
  -- Validate config
  if search_phrase == "" then
    return {}
  end


  local jql = construct_jql {
    text = search_phrase
  }
  -- Paginate?
  local endpoint = M._config.base_url .. "search"
  local payload = {
    jql = jql,
    startAt = 0,
    maxResults = 50,
    fields = {
      "summary",
      "status",
      "assignee",
      "creator",
      "reporter",
      "description",
      "issuetype",
      "priority",
    }
  }

  local res = make_request(endpoint, payload)
  -- Validate success of request

  -- Format to table
  local entries = {}
  local count = 0
  for _, v in pairs(res.data.issues) do
    local f = v.fields
    table.insert(entries, {
      key = v.key,
      description = f.description,
      summary = f.summary,
      created = f.created,
      assignee = f.assignee ~= vim.NIL and f.assignee.displayName,
      creator = f.creator ~= vim.NIL and  f.creator.displayName,
      reporter = f.reporter ~= vim.NIL and  f.reporter.displayName,
      priority = f.priority ~= vim.NIL and  f.priority.name,
      issuetype = f.issuetype ~= vim.NIL and  f.issuetype.name,
      status = f.status ~= vim.NIL and  f.status.name
    })
    count = count + 1
  end
  return entries
end

M.setup = function(config)
    config = config or {}
    M._config = vim.tbl_deep_extend("force", {
      base_url = os.getenv("JIRA_SERVER") or "",
      username = os.getenv("JIRA_USERNAME") or "",
      token = os.getenv("JIRA_API_TOKEN") or "",
    }, config)
end


M.setup()

return M

local curl = require'plenary.curl'

local M = {}

local function handle_response(response)
  return {
    data = vim.fn.json_decode(response.body),
    status = response.status,
  }
end

local function make_request(method, endpoint, opts)
  opts = opts or {}
  local request_opts = vim.tbl_deep_extend("force", {
    auth = M._config.username .. ":" .. M._config.token,
    headers = {
      content_type = "application/json",
    },
  }, opts)

  local response = curl[method](
    endpoint,
    request_opts
  )

  return handle_response(response)
end

local function escape_string(str)
  return string.gsub(str, "\"", "\\\"")
end

local function construct_jql(opts)
  opts = opts or {}

  if opts.jql ~= nil then
    return opts.jql
  end

  local frag = {}

  if opts.text ~= "" then
    table.insert(frag, "text ~ \"" .. escape_string(opts.text) .. "\"")
  end

  for _, key in ipairs({'project','assignee','reporter','creator','watcher','type'}) do
    if opts[key] then
      local value = opts[key]
      -- Check if there's multiple values 
      -- multiple -> IN search
      -- single -> IS search
      -- Split value by comma to allow for multiple values being passed

      local args = {
        count = 0,
        items = {}
      }
      for i in string.gmatch(value, '([^,]+)') do
        table.insert(args.items, i)
        args.count = args.count + 1
      end

      if args.count > 1 then
        table.insert(frag, key .. " in (" .. table.concat(args.items, ",") .. ")")
      else
        table.insert(frag, key .. " = \"" .. escape_string(value) .. "\"")
      end
    end
  end

  return table.concat(frag, " AND ")
end

M.projects = function (search_phrase)
  local res
  if search_phrase == "" then
    local endpoint = M._config.base_url .. "project"
    res = make_request("get", endpoint)
  else
    local endpoint = M._config.base_url .. "projects/picker"
    res = make_request("get", endpoint, {
      query = { query = search_phrase }
    })
  end

  local entries = {}
  for _, v in pairs(res.data) do
    table.insert(entries, {
      key = v.key,
      name = v.name
    })
  end

  return {
    items = entries,
    maxResults = res.data.maxResults,
    startAt = res.data.startAt
  }
end

M.search = function (search_phrase, opts)
  -- Validate config

  local jql = construct_jql(vim.tbl_extend("keep", {
    text = search_phrase
  }, opts))

  local endpoint = M._config.base_url .. "search"
  -- Paginate?
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

  local res = make_request("post", endpoint, {
    body = vim.fn.json_encode(payload)
  })
  -- Validate success of request
  print(vim.inspect(res))
  if res.status ~= 200 then
    vim.notify.notify(res.data.errorMessages)
    return {
      items = {}
    }
  end

  -- Format to table
  local entries = {}
  for _, v in pairs(res.data.issues) do
    local f = v.fields
    table.insert(entries, {
      key = v.key,
      description = f.description,
      summary = f.summary,
      created = f.created,
      assignee = f.assignee ~= vim.NIL and f.assignee.displayName,
      creator = f.creator ~= vim.NIL and f.creator.displayName,
      reporter = f.reporter ~= vim.NIL and f.reporter.displayName,
      priority = f.priority ~= vim.NIL and f.priority.name,
      issuetype = f.issuetype ~= vim.NIL and f.issuetype.name,
      status = f.status ~= vim.NIL and f.status.name
    })
  end

  return {
    items = entries,
    maxResults = res.data.maxResults,
    startAt = res.data.startAt
  }
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

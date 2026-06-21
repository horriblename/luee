if vim.g.loaded_luee ~= nil then
  return
end

_G.reg = setmetatable({}, {
  __call = function(_, key) return vim.fn.getreg(key) end,
  __index = function(_, key) return vim.fn.getreg(key) end,
  __newindex = function(_, key, val) vim.fn.setreg(key, val) end,
})

local function get_keys(tbl, prefix)
  if type(tbl) ~= "table" then return {} end
  local items = {}
  for k in pairs(tbl) do
    if type(k) == "string" and k:sub(1, #prefix) == prefix
        or type(k) == "integer"
    then
      items[#items + 1] = k
    end
  end
  return items
end

---@param arg string
---@return (string|integer)[] path indexing path
---@return string ending_ident last identifier we want to complete
local function parse_path(arg)
  local ending_ident = arg:match "([%w_][%w%d_]*)$" or ""
  local before = arg:sub(1, #arg - #ending_ident)
  if before:sub(-1) == "." then
    before = before:sub(1, -2)
  end
  local parts = {}
  while true do
    local prefix = "^(.*)"
    local rest, index = before:match(prefix .. "%.([%w_]+)$")
    if not rest then
      rest, index = before:match(prefix .. "%['([^']+)'%]$")
    end
    if not rest then
      rest, index = before:match(prefix .. '%["([^"]+)"%]$')
    end
    if not rest then
      rest, index = before:match(prefix .. '%[(%d+)%]')
      index = tonumber(index)
    end

    if not rest then
      break
    end

    table.insert(parts, 1, index)
    before = rest
  end

  if before ~= "" then
    table.insert(parts, 1, before)
  end

  return parts, ending_ident
end

---@param s string
---@return boolean
local function is_ident(s)
  return string.match(s, "^[%w_][%w%d_]*$") ~= nil
end

---@param parts (string|integer)[] path segments
---@return string?
local function index_path_to_expr(parts)
  local path = ''
  for _, part in ipairs(parts) do
    if path == '' then -- first loop
      path = tostring(part)
    elseif type(part) == "string" and is_ident(part) then
      path = path .. '.' .. part
    else
      path = path .. '[' .. vim.inspect(part) .. ']'
    end
  end

  return path
end

---@param ArgLead string
---@return table
local function completion(ArgLead)
  local parts, prefix = parse_path(ArgLead)
  if prefix == "" and #parts == 0 then
    return {}
  end
  local tbl = _G
  for _, part in ipairs(parts) do
    tbl = tbl[part]
    if tbl == nil then return {} end
  end
  local keys = get_keys(tbl, prefix)
  local head = #parts > 0
      and (index_path_to_expr(parts) or "")
      or ""
  for i, k in ipairs(keys) do
    if #parts > 0 then
      keys[i] = index_path_to_expr({ head, k })
    else
      keys[i] = k
    end
  end
  return keys
end

local function luee_cmd(args)
  local ast, err = require('luee.parser').parse("return " .. args.args, "main.luee")
  if ast == nil then
    vim.notify(err --[[@as string]], vim.log.levels.ERROR)
    return
  end
  local transpiled = require('luee.format').tostring(ast)
  if args.bang then
    vim.print('transpiled: ', transpiled, '---')
  end
  local l, e = loadstring(transpiled, "main.luee")
  if l == nil then
    vim.notify(e --[[@as string]], vim.log.levels.ERROR)
    return
  end
  vim.print(l())
end

vim.api.nvim_create_user_command("Luee", luee_cmd, {
  bar = false,
  bang = true,
  nargs = "+",
  complete = completion,
})

vim.api.nvim_create_user_command("L", luee_cmd, {
  bar = false,
  bang = true,
  nargs = "+",
  complete = completion,
})

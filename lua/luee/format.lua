--[[
This module impements a pretty printer to the AST
]]
local pp = {}

local block2str, stm2str, exp2str, var2str
local explist2str, varlist2str, parlist2str, fieldlist2str

local function iscntrl(x)
  if (x >= 0 and x <= 31) or (x == 127) then return true end
  return false
end

local function isprint(x)
  return not iscntrl(x)
end

local function fixed_string(str)
  local new_str = ""
  for i = 1, string.len(str) do
    char = string.byte(str, i)
    if char == 34 then
      new_str = new_str .. string.format("\\\"")
    elseif char == 92 then
      new_str = new_str .. string.format("\\\\")
    elseif char == 7 then
      new_str = new_str .. string.format("\\a")
    elseif char == 8 then
      new_str = new_str .. string.format("\\b")
    elseif char == 12 then
      new_str = new_str .. string.format("\\f")
    elseif char == 10 then
      new_str = new_str .. string.format("\\n")
    elseif char == 13 then
      new_str = new_str .. string.format("\\r")
    elseif char == 9 then
      new_str = new_str .. string.format("\\t")
    elseif char == 11 then
      new_str = new_str .. string.format("\\v")
    else
      if isprint(char) then
        new_str = new_str .. string.format("%c", char)
      else
        new_str = new_str .. string.format("\\%03d", char)
      end
    end
  end
  return new_str
end

local function name2str(name)
  -- do we need escape? for e.g. {["for"] = 1}
  return name
end

local function boolean2str(b)
  return tostring(b)
end

local function number2str(n)
  return tostring(n)
end

local function string2str(s)
  return string.format('"%s"', fixed_string(s))
end

local function op2str(op)
  if op == "or" then
    return " or "
  elseif op == "and" then
    return " and "
  elseif op == "ne" then
    return "~="
  elseif op == "eq" then
    return "=="
  elseif op == "le" then
    return "<="
  elseif op == "ge" then
    return ">="
  elseif op == "lt" then
    return "<"
  elseif op == "gt" then
    return ">"
  elseif op == "bor" then
    return "|"
  elseif op == "bxor" then
    return "~"
  elseif op == "band" then
    return "&"
  elseif op == "shl" then
    return "<<"
  elseif op == "shr" then
    return ">>"
  elseif op == "concat" then
    return ".."
  elseif op == "add" then
    return "+"
  elseif op == "sub" then
    return "-"
  elseif op == "mul" then
    return "*"
  elseif op == "idiv" then
    return "//"
  elseif op == "div" then
    return "/"
  elseif op == "mod" then
    return "%"
  elseif op == "not" then
    return " not "
  elseif op == "unm" then
    return "-"
  elseif op == "len" then
    return "#"
  elseif op == "bnot" then
    return "~"
  elseif op == "pow" then
    return "^"
  end

  error("invalid operator: " .. op)
end


function var2str(var)
  local tag = var.tag
  local str
  if tag == "Id" then        -- `Id{ <string> }
    str = var[1]
  elseif tag == "Index" then -- `Index{ expr expr }
    str = exp2str(var[1])
    str = str .. "["
    str = str .. exp2str(var[2])
    str = str .. "]"
  else
    error("expecting a variable, but got a " .. tag)
  end
  return str
end

function varlist2str(varlist)
  local l = {}
  for k, v in ipairs(varlist) do
    l[k] = var2str(v)
  end
  return table.concat(l, ", ")
end

function parlist2str(parlist)
  local l = {}
  local len = #parlist
  local is_vararg = false
  if len > 0 and parlist[len].tag == "Dots" then
    is_vararg = true
    len = len - 1
  end
  local i = 1
  while i <= len do
    l[i] = var2str(parlist[i])
    i = i + 1
  end
  if is_vararg then
    l[i] = "..."
  end
  return "(" .. table.concat(l, ", ") .. ")"
end

function fieldlist2str(fieldlist)
  local l = {}
  for k, v in ipairs(fieldlist) do
    local tag = v.tag
    if tag == "Pair" then -- `Pair{ expr expr }
      l[k] = string.format("[%s]", exp2str(v[1])) .. " = " .. exp2str(v[2])
    else                  -- expr
      l[k] = exp2str(v)
    end
  end
  if #l > 0 then
    return "{ " .. table.concat(l, ", ") .. " }"
  else
    return "{}"
  end
end

local function pipe2str(exp)
  local lhs = exp[2]
  local rhs = exp[3]
  if rhs.tag == "Call" then
    local call = {
      tag = "Call",
      pos = exp.pos,
      end_pos = exp.end_pos,
      [1] = rhs[1],
      [2] = lhs,
    }

    for i = 2, #exp[3] do
      call[i + 1] = exp[3][i]
    end

    return exp2str(call)
  elseif rhs.tag == "Invoke" then
    local call = {
      tag = "Invoke",
      pos = exp.pos,
      end_pos = exp.end_pos,
      [1] = rhs[1],
      [2] = rhs[2],
      [3] = lhs,
    }

    for i = 3, #exp[3] do
      call[i + 1] = exp[3][i]
    end

    return exp2str(call)
  end

  local call = {
    tag = "Call",
    pos = exp.pos,
    end_pos = exp.end_pos,
    [1] = {
      tag = "Paren",
      pos = exp[3].pos,
      end_pos = exp[3].end_pos,
      [1] = exp[3],
    },
    [2] = exp[2],
  }
  local ret = exp2str(call)
  return ret
end

function exp2str(exp)
  local tag = exp.tag
  local str
  if tag == "Nil" then
    str = "nil"
  elseif tag == "Dots" then
    str = "..."
  elseif tag == "Boolean" then  -- `Boolean{ <boolean> }
    str = boolean2str(exp[1])
  elseif tag == "Number" then   -- `Number{ <number> }
    str = number2str(exp[1])
  elseif tag == "String" then   -- `String{ <string> }
    str = string2str(exp[1])
  elseif tag == "Function" then -- `Function{ { `Id{ <string> }* `Dots? } block }
    str = "function"
    str = str .. parlist2str(exp[1])
    str = str .. "\n"
    str = str .. block2str(exp[2])
    str = str .. " end "
  elseif tag == "Fn" then
    str = "function"
    str = str .. parlist2str(exp[1])
    str = str .. "return "
    str = str .. exp2str(exp[2])
    str = str .. " end "
  elseif tag == "Table" then -- `Table{ ( `Pair{ expr expr } | expr )* }
    str = fieldlist2str(exp)
  elseif tag == "Op" then    -- `Op{ opid expr expr? }
    if exp[1] == "pipe" then
      return pipe2str(exp)
    end
    str = exp2str(exp[2])
    str = str .. op2str(exp[1])
    if exp[3] ~= nil then
      str = str .. exp2str(exp[3])
    end
  elseif tag == "Paren" then -- `Paren{ expr }
    str = "( " .. exp2str(exp[1]) .. " )"
  elseif tag == "Call" then  -- `Call{ expr expr* }
    str = exp2str(exp[1])
    str = str .. "("
    if exp[2] then
      str = str .. exp2str(exp[2])
      for i = 3, #exp do
        str = str .. ", " .. exp2str(exp[i])
      end
    end
    str = str .. ")"
  elseif tag == "Invoke" then -- `Invoke{ expr `String{ <string> } expr* }
    str = exp2str(exp[1]) .. ":"
    str = str .. exp[2][1]    -- for some reason this is a `String
    str = str .. "("
    if exp[3] then
      str = str .. exp2str(exp[3])
      for i = 4, #exp do
        str = str .. ", " .. exp2str(exp[i])
      end
    end
    str = str .. ")"
  elseif tag == "Id" or   -- `Id{ <string> }
      tag == "Index" then -- `Index{ expr expr }
    str = var2str(exp)
  else
    error("expecting an expression, but got a " .. tag)
  end
  return str
end

function explist2str(explist)
  local l = {}
  for k, v in ipairs(explist) do
    l[k] = exp2str(v)
  end
  if #l > 0 then
    return table.concat(l, ", ")
  else
    return ""
  end
end

function stm2str(stm)
  local tag = stm.tag
  local str = ''      --TODO: make nil
  if tag == "Do" then -- `Do{ stat* }
    local l = {}
    for k, v in ipairs(stm) do
      l[k] = stm2str(v)
    end
    str = "do\n" .. table.concat(l, "\n\t") .. "end\n"
  elseif tag == "Set" then -- `Set{ {lhs+} {expr+} }
    str = varlist2str(stm[1]) .. " = "
    str = str .. explist2str(stm[2])
  elseif tag == "While" then -- `While{ expr block }
    str = "while "
    str = str .. exp2str(stm[1]) .. " do\n"
    str = str .. block2str(stm[2])
    str = str .. "end\n"
  elseif tag == "Repeat" then -- `Repeat{ block expr }
    str = str .. "repeat\n"
    str = str .. block2str(stm[1]) .. "\n"
    str = str .. "until " .. exp2str(stm[2])
  elseif tag == "If" then -- `If{ (expr block)+ block? }
    str = "if "
    local len = #stm
    if len % 2 == 0 then
      local l = {}
      for i = 1, len - 2, 2 do
        str = str .. exp2str(stm[i]) .. ", " .. block2str(stm[i + 1]) .. "\n"
      end
      str = str .. exp2str(stm[len - 1]) .. ", " .. block2str(stm[len])
    else
      local l = {}
      for i = 1, len - 3, 2 do
        str = str .. exp2str(stm[i]) .. ", " .. block2str(stm[i + 1]) .. ", "
      end
      str = str .. exp2str(stm[len - 2]) .. ", " .. block2str(stm[len - 1]) .. ", "
      str = str .. block2str(stm[len])
    end
    str = str .. "end\n"
  elseif tag == "Fornum" then -- `Fornum{ ident expr expr expr? block }
    str = "for "
    str = str .. var2str(stm[1])
    str = str .. " = "
    str = str .. exp2str(stm[2]) .. ", "
    str = str .. exp2str(stm[3])
    if stm[5] then -- optional step
      str = str .. "," .. exp2str(stm[4])
    end
    str = str .. "\n"
    str = str .. block2str(stm[4])
    str = str .. "end\n"
  elseif tag == "Forin" then -- `Forin{ {ident+} {expr+} block }
    str = "for "
    str = str .. varlist2str(stm[1])
    str = str .. " in "
    str = str .. explist2str(stm[2]) .. "\n"
    str = str .. block2str(stm[3])
    str = str .. "\nend\n"
  elseif tag == "Local" then -- `Local{ {ident+} {expr+}? }
    str = "local "
    str = str .. varlist2str(stm[1])
    if #stm[2] > 0 then
      str = str .. " = "
      str = str .. explist2str(stm[2])
    end
  elseif tag == "Localrec" then -- `Localrec{ ident expr }
    str = "local function "
    str = str .. var2str(stm[1][1])
    local func = stm[2][1]
    str = str .. parlist2str(func[1])
    str = str .. "\n"
    str = str .. block2str(func[2])
    str = str .. "end\n"
  elseif tag == "Goto" then   -- `Goto{ <string> }
    str = "goto " .. name2str(stm[1]) .. "\n"
  elseif tag == "Label" then  -- `Label{ <string> }
    str = name2str(stm[1]) .. ":\n"
  elseif tag == "Return" then -- `Return{ <expr>* }
    str = "return " .. explist2str(stm) .. "\n"
  elseif tag == "Break" then
    str = "break\n"
  elseif tag == "Call" then -- `Call{ expr expr* }
    str = exp2str(stm[1]) .. "("
    if stm[2] then
      str = str .. exp2str(stm[2])
      for i = 3, #stm do
        str = str .. ", " .. exp2str(stm[i])
      end
    end
    str = str .. ")\n"
  elseif tag == "Invoke" then -- `Invoke{ expr `String{ <string> } expr* }
    str = exp2str(stm[1]) .. ":"

    str = str .. stm[2][1] .. "(" --for some reason this is a `String
    if stm[3] then
      str = str .. exp2str(stm[3])
      for i = 4, #stm do
        str = str .. ", " .. exp2str(stm[i])
      end
    end
    str = str .. ")"
  else
    error("expecting a statement, but got a " .. tag)
  end
  return str
end

function block2str(block)
  local l = {}
  for k, v in ipairs(block) do
    l[k] = stm2str(v)
  end
  return table.concat(l, "\n")
end

function pp.tostring(t)
  assert(type(t) == "table")
  return block2str(t)
end

function pp.print(t)
  assert(type(t) == "table")
  print(pp.tostring(t))
end

function pp.dump(t, i)
  if i == nil then i = 0 end
  io.write(string.format("{\n"))
  io.write(string.format("%s[tag] = %s\n", string.rep(" ", i + 2), t.tag or "nil"))
  io.write(string.format("%s[pos] = %s\n", string.rep(" ", i + 2), t.pos or "nil"))
  for k, v in ipairs(t) do
    io.write(string.format("%s[%s] = ", string.rep(" ", i + 2), tostring(k)))
    if type(v) == "table" then
      pp.dump(v, i + 2)
    else
      io.write(string.format("%s\n", tostring(v)))
    end
  end
  io.write(string.format("%s}\n", string.rep(" ", i)))
end

return pp

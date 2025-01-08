if vim.g.loaded_luee ~= nil then
  return
end

vim.api.nvim_create_user_command("Luee", function(args)
  local ast, err = require('luee.parser').parse("return " .. args.args, "main.luee")
  if ast == nil then
    vim.notify(err, vim.log.levels.ERROR)
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
end, {
  bar = false,
  bang = true,
  nargs = "+",
})

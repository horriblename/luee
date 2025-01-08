# Luee

**Lu**a **E**xtended **E**xpressions

Transpiler that adds support for short-hand function expression and pipe
operator to lua.

This is designed as a "REPL-only" language. That is to say, don't actually write
in Luee in your files, it's only useful for typing hacky pipelines on your
command line.

Parser adapted from [andremm/lua-parser](https://github.com/andremm/lua-parser)
under MIT.

# Features

## fn expressions

```lua
fn(x) x+y

-- transpiles to

function(x)
    return x+y
end
```

Fn expressions have weaker binding power than pipe operators but stronger
binding power than any other lua operator

## Pipe operator

```lua
'(%s)' |> string.format('hi') |> fn(x) x .. '.' |> vim.inspect

-- transpiles to

vim.inspect((function(x) return x .. '.' end)(string.format('(%s)', 'hi')))
```

Pipe operators have the weakest binding power

# Example

```vim
:Luee vim.opt.rtp:get() |> vim.iter() |> fn(x) x:filter(fn(x) x:match('luee'))

" transpiles to
:lua= vim.iter(vim.opt.rtp:get()):filter(function(x) return x:match('luee') end)
```

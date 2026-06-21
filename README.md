# Luee

**Lu**a **E**xtended **E**xpressions

Transpiler that adds support for various short-hand expressions and pipe
operator to lua.

Personal project, I will make breaking changes whenever I feel, and will cater
to my own needs.

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

## @ token

Used in conjunction with the separately added `reg` global, gets/sets vim
registers, the character after `@` is taken as the

```vim
:Luee @+ = @a

" transpiles to
:lua= reg["+"] = reg["a"]
```

## Assignment as expression

Single variable assignment `a = b` is now possible. Multi-variable ones
`a, b = c, d` are not allowed

```vim
:Luee a = b
" transpiles to
:lua= (function() a = b; return a end)()

:Luee a = (b = c + d),
" transpiles to
:lua= (function()
    \    a = (
    \      function()
    \          b = c + d
    \          return b end
    \    )();
    \    return a 
    \ end)()
```

> [!WARN]
>
> With this extension, some syntax errors in base Lua is now accepted:
>
> ```lua
> -- lua, syntax error
> x = -
> y = 3
> ```
>
> is parsed in Luee as
>
> ```lua
> -- Luee
> x = -(y = 3)
> ```

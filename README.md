<h1 align="center">
smartcolumn.nvim
</h1>

<p align="center">
<a href="https://github.com/m4xshen/smartcolumn.nvim/stargazers">
    <img
      alt="Stargazers"
      src="https://img.shields.io/github/stars/m4xshen/smartcolumn.nvim?style=for-the-badge&logo=starship&color=fae3b0&logoColor=d9e0ee&labelColor=282a36"
    />
  </a>
  <a href="https://github.com/m4xshen/smartcolumn.nvim/issues">
    <img
      alt="Issues"
      src="https://img.shields.io/github/issues/m4xshen/smartcolumn.nvim?style=for-the-badge&logo=gitbook&color=ddb6f2&logoColor=d9e0ee&labelColor=282a36"
    />
  </a>
  <a href="https://github.com/m4xshen/smartcolumn.nvim/contributors">
    <img
      alt="Contributors"
      src="https://img.shields.io/github/contributors/m4xshen/smartcolumn.nvim?style=for-the-badge&logo=opensourceinitiative&color=abe9b3&logoColor=d9e0ee&labelColor=282a36"
    />
  </a>
</p>

![demo](https://user-images.githubusercontent.com/74842863/219844450-37d96fe1-d15d-4aaf-ae57-1c6ce66d8cbc.gif)

## 📃 Introduction

A Neovim plugin hiding your colorcolumn when unneeded.

## ⚙️ Features

The colorcolumn is hidden as default, but it appears after one of lines in the scope exceeds the `colorcolumn` value you set.

You can:
- hide colorcolumn for specific filetype
- set custom colorcolumn value for different filetype
- specify the scope where the plugin should work

## 📦 Installation

1. Install via your favorite package manager.

- [lazy.nvim](https://github.com/folke/lazy.nvim)
```Lua
{
  "m4xshen/smartcolumn.nvim",
  opts = {}
},
```

- [packer.nvim](https://github.com/wbthomason/packer.nvim)
```Lua
use "m4xshen/smartcolumn.nvim"
```

- [vim-plug](https://github.com/junegunn/vim-plug)
```VimL
Plug "m4xshen/smartcolumn.nvim"
```

2. Setup the plugin in your `init.lua`. This step is not needed with lazy.nvim if `opts` is set as above.
```Lua
require("smartcolumn").setup()
```

## 🔧 Configuration

You can pass your config table into the `setup()` function or `opts` if you use lazy.nvim.

The available options:

- `colorcolumn` (strings or table) : screen columns that are highlighted
  - `"80"` (default)
  - `{ "80", "100" }`
- `disabled_filetypes` (table of strings) : the `colorcolumn` will be disabled under the filetypes in this table
  - `{ "help", "text", "markdown" }` (default)
  - `{ "NvimTree", "lazy", "mason", "help" }`
- `scope` (strings): the plugin only checks whether the lines within scope exceed colorcolumn
  - `"file"` (default): current file
  - `"window"`: visible part of current window
  - `"line"`: current line
- `custom_colorcolumn` (table or function returning string): custom `colorcolumn` values for different filetypes
  - `{}` (default)
  - `{ ruby = "120", java = { "180", "200"} }`
  - you can also pass a function to handle more complicated logic:
  ```lua
  custom_colorcolumn = function ()
     return "100"
  end
  ```

### Default config

```Lua
local config = {
   colorcolumn = "80",
   disabled_filetypes = { "help", "text", "markdown" },
   custom_colorcolumn = {},
   scope = "file",
}
```

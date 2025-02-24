# 🚁 HoverSplit

![hoversplit](https://github.com/roobert/tabtree.nvim/assets/226654/b30c6892-6f4a-4443-94ed-84c3aa75d51b)

## Overview

A Neovim plugin designed to enhance the Language Server Protocol (LSP) experience by providing hover information in a split window. With this plugin, it is possible to quickly access additional context, documentation, or information related to code symbols directly within Neovim without disrupting your workflow.

## Features

- **Hover Information**: Get detailed hover information about symbols, functions, types, and more in a separate split window.
- **Auto Update**: The content automatically updates as the cursor moves to new targets.
- **Toggle Splits**: Easily toggle the split window open and closed using configurable key bindings.

## Installation

Install hoversplit.nvim using any preferred plugin manager.
LazyVim Example:

```lua
{
  "roobert/hoversplit.nvim",
  config = function()
    require("hoversplit").setup({
      autoupdate = false,
      -- close when cursor leave current window
      autoclose = true,
      max_size = 0.3,
      -- :h nvim_open_win()
      winconfig = {
        split = 'below',
        height = 15,
      },
    })
  end
}
```

## Usage

### Key Bindings

Configure key bindings for different functionalities. Example configuration:

```lua
{
  "roobert/hoversplit.nvim",
  config = function()
    vim.keymap.set('n', '<leader>h', function() require('hoversplit').toggle() end)
  end,
}
```

## Functions

- **show**
- **close**
- **toggle**

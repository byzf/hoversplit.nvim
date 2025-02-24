local M = {
  autoupdate = false,
  -- close when cursor leave current window
  autoclose = true,
  max_size = 0.3,
  -- :h nvim_open_win()
  winconfig = {
    split = 'below',
    height = 15,
  },
}

return M

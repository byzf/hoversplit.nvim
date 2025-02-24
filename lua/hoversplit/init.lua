local M = {}

local config = require("hoversplit.config")
local agname = "HoverSplit"

local hover_bufnr = -1
local hover_winid = -1
local invoked_buf = -1 -- for autoclose behaviour

local function is_valid()
	return vim.api.nvim_buf_is_valid(hover_bufnr)
end

local function is_shown()
  return vim.api.nvim_win_is_valid(hover_winid)
end

local function close()
  if is_shown() then
    vim.api.nvim_win_close(hover_winid, true)
    vim.api.nvim_create_augroup(agname, { clear = true })
    hover_winid = -1
    return true
  end
  return false
end

local function render(contents, syntax)
  if not is_valid() or not is_shown() then
    return
  end

  local width = vim.api.nvim_win_get_width(hover_winid)

  -- Set up the contents, using treesitter for markdown
  local do_stylize = syntax == 'markdown' and vim.g.syntax_on ~= nil
  if do_stylize then
    contents = vim.lsp.util._normalize_markdown(contents, { width = width })
    vim.wo[hover_winid].conceallevel = 2
    vim.bo[hover_bufnr].filetype = 'markdown'
    vim.treesitter.start(hover_bufnr)
  else
    if syntax then
      vim.bo[hover_bufnr].syntax = syntax
    end
  end

  vim.bo[hover_bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(hover_bufnr, 0, -1, false, contents)
  vim.bo[hover_bufnr].modifiable = false
end

local function req_update()
	-- Check the current buffer and cursor position
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local current_line = vim.api.nvim_buf_get_lines(bufnr, cursor_pos[1] - 1, cursor_pos[1], false)[1] or ""

	-- Validate the cursor position
	if cursor_pos[1] < 1 or cursor_pos[1] > line_count or cursor_pos[2] < 0 or cursor_pos[2] > #current_line then
		print("Invalid cursor position detected. Skipping hover content update.")
		return
	end

  local function lsp_callback(err, result)
    local format = 'plaintext'
    local contents = {} ---@type string[]
    if err then
      contents = { err }
    elseif not result or not result.contents then
      -- pass
    elseif type(result.contents) == 'table' and result.contents.kind == 'plaintext' then
      contents = vim.split(result.contents.value or '', '\n', { trimempty = true })
    else
      format = 'markdown'
      contents = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
    end

    if vim.tbl_isempty(contents) then
      contents = { 'No information available' }
      format = 'plaintext'
    end

    render(contents, format)
  end

	vim.lsp.buf_request(
    0,
    "textDocument/hover",
    vim.lsp.util.make_position_params(nil, 'utf-8'),
    lsp_callback
  )
end

local function open()
  if not is_valid() then
    hover_bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(hover_bufnr, "hoversplit")
    vim.api.nvim_buf_set_var(hover_bufnr, "is_lsp_hover_split", true)

    local opts = { buf = hover_bufnr }
    vim.api.nvim_set_option_value("bufhidden", "hide", opts)
    vim.api.nvim_set_option_value("modifiable", false, opts)

  end

  local wopts = config.winconfig
  if wopts.split == 'below' or wopts.split == 'top' then
    local h = math.floor(
      vim.api.nvim_win_get_height(0) * config.max_size
    )
    wopts.height = math.min(h, wopts.height)
  else
    local w = math.floor(
      vim.api.nvim_win_get_width(0) * config.max_size
    )
    wopts.width = math.min(w, wopts.width)
  end
  hover_winid = vim.api.nvim_open_win(hover_bufnr, false, wopts)
  vim.wo[hover_winid].foldenable = false
  vim.wo[hover_winid].breakindent = true
  vim.wo[hover_winid].smoothscroll = true

  if config.autoclose then
    invoked_buf = vim.api.nvim_get_current_buf()
    local augroup = vim.api.nvim_create_augroup(agname, { clear = true })
    vim.api.nvim_create_autocmd({'BufEnter'}, {
      callback = function(ev)
        if ev.buf == invoked_buf then
          return
        elseif ev.buf == hover_bufnr then
          return
        else
          close()
        end
      end,
      group=augroup
    })
  end
end

function M.show()
	if not is_shown() then
		open()
	end
  req_update()
end

function M.close()
  close()
end

function M.toggle()
	if not close() then
    open()
    req_update()
  end
end

function M.setup(options)
	if options == nil then
		options = {}
	end

  config = vim.tbl_deep_extend('force', config, options)

  if config.autoupdate then
    vim.api.nvim_create_autocmd({'CursorMoved', 'CursorMovedI'}, {
      callback = function ()
        req_update()
      end
    })
  end
end

return M

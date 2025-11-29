-- TODO document all this

-- inspired by
-- https://github.com/neovim/neovim/discussions/35953#discussioncomment-14544580
-- this makes it possible to toggle hover window in insert mode
local float_wrapper = function(opener, var_name)
  return function(contents, syntax, opts)
    local buf_id, win_id = opener(contents, syntax, opts)
    if not buf_id or not win_id then
      return buf_id, win_id
    end
    if opts.parent_bufnr ~= nil then
      vim.api.nvim_buf_set_var(
        opts.parent_bufnr,
        var_name,
        win_id
      )
    end
    if opts.callback then
      opts.callback()
    end
    return buf_id, win_id
  end
end

local function diag_win_preview(bufnr, var_name)
  local result, win_id = pcall(vim.api.nvim_buf_get_var, bufnr, var_name)
  if not result or not win_id then
    return
  elseif not vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_buf_set_var(bufnr, var_name, nil)
    return
  end
  vim.api.nvim_set_current_win(win_id)
  print(vim.cmd("pbuffer %"))
  vim.api.nvim_win_close(win_id, true)
  vim.api.nvim_buf_set_var(bufnr, var_name, nil)
  -- TODO clear highlight on close of preview window and if possible
  -- check if there was previous highlight to leave alone
  -- clears only current line
  -- local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  -- vim.api.nvim_buf_clear_namespace(0, 0, cur_line-1, cur_line)
  -- clears everything
  vim.api.nvim_buf_clear_namespace(0, 0, 0, -1)
end

M = {
  wrap_float = function(var_name)
    vim.lsp.util.open_floating_preview = float_wrapper(
      vim.lsp.util.open_floating_preview,
      var_name
    )
  end,
  hover_toggle = function(opts, bufnr, var_name)
    local result, hover_win_id = pcall(
      vim.api.nvim_buf_get_var,
      bufnr,
      var_name
    )
    if result and hover_win_id and
        vim.api.nvim_win_is_valid(hover_win_id) then
      vim.api.nvim_win_close(hover_win_id, true)
      vim.api.nvim_buf_set_var(bufnr, var_name, nil)
      return
    end
    opts.parent_bufnr = bufnr
    vim.lsp.buf.hover(opts)
  end,
  diag_win_preview = diag_win_preview,
  buf_hover_preview = function(opts, var_name, bufnr)
    if bufnr then
      opts.parent_bufnr = bufnr
    end
    opts.callback = function()
      diag_win_preview(bufnr, var_name)
    end
    vim.lsp.buf.hover(opts)
  end,
}

return M

local function DiagWinPreview()
  local cw = vim.api.nvim_replace_termcodes("<C-w>", true, true, true)
  vim.cmd.normal(cw .. "w")
  vim.cmd.sleep("10m")
  vim.cmd("silent! pedit")
  vim.cmd.close()
  vim.cmd.normal(cw .. "P")
end

M = {
  DiagWinPreview = DiagWinPreview,
  BufHoverPreview = function(opts)
    vim.lsp.buf.hover(opts)
    vim.cmd.sleep("20m")
    DiagWinPreview()
  end,
}

return M

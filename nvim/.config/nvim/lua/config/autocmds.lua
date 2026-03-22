local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank (flash copied text briefly)
autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Return to last edit position when opening a file
autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ── Theme persistence ────────────────────────────────────
local theme_file = vim.fn.stdpath("data") .. "/current_theme.txt"

-- Save theme whenever it changes
autocmd("ColorScheme", {
  callback = function(args)
    local f = io.open(theme_file, "w")
    if f then
      f:write(args.match)
      f:close()
    end
  end,
})

-- Restore theme after all plugins are loaded (VimEnter fires after lazy setup)
autocmd("VimEnter", {
  once = true,
  callback = function()
    local f = io.open(theme_file, "r")
    if f then
      local theme = f:read("*l")
      f:close()
      if theme and theme ~= "" then
        local ok = pcall(vim.cmd.colorscheme, theme)
        if not ok then
          vim.cmd.colorscheme("tokyonight-night")
        end
        return
      end
    end
    vim.cmd.colorscheme("tokyonight-night")
  end,
})
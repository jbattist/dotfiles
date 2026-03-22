return {
  "lambdalisue/vim-suda",
  cmd = { "SudaRead", "SudaWrite" },
  init = function()
    vim.cmd([[cnoreabbrev <expr> W ((getcmdtype() == ':' && getcmdline() == 'W') ? 'SudaWrite' : 'W')]])
  end,
}

return {
  "lambdalisue/vim-suda",
  event = "VeryLazy",
  init = function()
    vim.cmd([[cnoreabbrev <expr> W ((getcmdtype() == ':' && getcmdline() == 'W') ? 'SudaWrite' : 'W')]])
  end,
}

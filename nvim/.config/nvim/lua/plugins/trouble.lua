return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  config = function()
    require("trouble").setup()
    vim.keymap.set("n", "<leader>xx", ":Trouble diagnostics toggle<CR>", { desc = "Diagnostics" })
    vim.keymap.set("n", "<leader>xd", ":Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Buffer diagnostics" })
  end,
}
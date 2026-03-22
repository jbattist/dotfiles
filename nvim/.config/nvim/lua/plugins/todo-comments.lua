return {
  "folke/todo-comments.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = "nvim-lua/plenary.nvim",
  config = function()
    require("todo-comments").setup()
    vim.keymap.set("n", "<leader>ft", ":TodoTelescope<CR>", { desc = "Find TODOs" })
  end,
}
return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    require("bufferline").setup({
      options = {
        mode = "buffers",
        diagnostics = "nvim_lsp",
        offsets = {
          {
            filetype = "neo-tree",
            text = " Files",
            highlight = "Directory",
            separator = true,
          },
        },
        separator_style = "thin",
        show_close_icon = false,
        show_buffer_close_icons = true,
        always_show_bufferline = true,
      },
    })

    -- Pick buffer by letter
    vim.keymap.set("n", "<leader>bp", ":BufferLinePick<CR>", { desc = "Pick buffer" })
    vim.keymap.set("n", "<leader>bc", ":BufferLinePickClose<CR>", { desc = "Pick close buffer" })
  end,
}
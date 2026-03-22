return {
  "folke/edgy.nvim",
  event = "VeryLazy",
  opts = {
    left = {
      {
        title = "Files",
        ft = "neo-tree",
        size = { width = 30 },
        pinned = true,
      },
    },
    bottom = {
      {
        title = "Terminal",
        ft = "toggleterm",
        size = { height = 15 },
        filter = function(buf)
          local name = vim.api.nvim_buf_get_name(buf)
          return not name:match("opencode")
        end,
      },
      {
        title = "Trouble",
        ft = "trouble",
        size = { height = 15 },
      },
    },
    right = {
      {
        title = "Opencode",
        ft = "toggleterm",
        size = { width = 0.28 },
        filter = function(buf)
          local name = vim.api.nvim_buf_get_name(buf)
          return name:match("opencode") ~= nil
        end,
      },
    },
    animate = { enabled = false },
  },
}
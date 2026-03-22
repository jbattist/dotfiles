return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local wk = require("which-key")
    wk.setup({
      delay = 200,
      icons = {
        breadcrumb = "»",
        separator = "➜",
        group = " ",
      },
      win = {
        border = "rounded",
        padding = { 1, 2 },
        title = true,
        title_pos = "center",
      },
    })

    wk.add({
      -- Top-level leader groups
      { "<leader>f", group = "Find (Telescope)" },
      { "<leader>g", group = "Git" },
      { "<leader>b", group = "Buffers" },
      { "<leader>t", group = "Terminal" },
      { "<leader>l", group = "LSP / Code" },
      { "<leader>x", group = "Trouble / Diagnostics" },

      -- File operations
      { "<leader>w", desc = "Save file" },
      { "<leader>q", desc = "Quit" },
      { "<leader>x", desc = "Save and quit" },
      { "<leader>Q", desc = "Quit ALL panels" },
      { "<leader>e", desc = "Toggle file explorer" },
      { "<leader>o", desc = "Focus file explorer" },
      { "<leader>L", desc = "Launch VS Code layout" },
      { "<leader>T", desc = "Switch colorscheme" },
      { "<leader>h", desc = "Clear search highlight" },

      -- Telescope find group
      { "<leader>ff", desc = "Find files" },
      { "<leader>fg", desc = "Live grep (search text)" },
      { "<leader>fb", desc = "Find open buffers" },
      { "<leader>fh", desc = "Search help docs" },
      { "<leader>fr", desc = "Recent files" },
      { "<leader>fs", desc = "Grep word under cursor" },
      { "<leader>ft", desc = "Find TODOs" },

      -- Git group
      { "<leader>gg", desc = "Open Lazygit" },
      { "<leader>gp", desc = "Preview git change" },
      { "<leader>gb", desc = "Blame this line" },
      { "<leader>gr", desc = "Reset this change" },

      -- Buffer group
      { "<leader>bd", desc = "Close buffer" },
      { "<leader>bp", desc = "Pick buffer by letter" },
      { "<leader>bc", desc = "Pick buffer to close" },

      -- Terminal group
      { "<leader>tt", desc = "Toggle bottom terminal" },
      { "<leader>to", desc = "Toggle opencode (right)" },

      -- LSP group
      { "<leader>la", desc = "Code action (fix it)" },
      { "<leader>lr", desc = "Rename symbol" },
      { "<leader>ld", desc = "Show line error" },
      { "<leader>lf", desc = "Format file" },

      -- Trouble group
      { "<leader>xx", desc = "All diagnostics" },
      { "<leader>xd", desc = "This file's diagnostics" },

      -- Non-leader essentials for beginners
      { "g", group = "Go to..." },
      { "gd", desc = "Go to definition" },
      { "gD", desc = "Go to declaration" },
      { "gr", desc = "Find all references" },
      { "gi", desc = "Go to implementation" },
      { "gc", group = "Comment toggle" },
      { "gcc", desc = "Comment this line" },

      { "]", group = "Next..." },
      { "]h", desc = "Next git change" },
      { "]d", desc = "Next error/warning" },

      { "[", group = "Previous..." },
      { "[h", desc = "Previous git change" },
      { "[d", desc = "Previous error/warning" },

      -- Visual mode hints
      { mode = "v", "<", desc = "Indent left (stay selected)" },
      { mode = "v", ">", desc = "Indent right (stay selected)" },
      { mode = "v", "J", desc = "Move selection down" },
      { mode = "v", "K", desc = "Move selection up" },

      -- Surround hints (if nvim-surround is installed)
      { "ys", group = "Add surround..." },
      { "ds", group = "Delete surround..." },
      { "cs", group = "Change surround..." },
    })
  end,
}
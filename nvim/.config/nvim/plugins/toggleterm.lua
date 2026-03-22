return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.3
        end
      end,
      open_mapping = [[<C-\>]],
      direction = "horizontal",
      shade_terminals = true,
      shading_factor = 2,
      persist_size = true,
      close_on_exit = true,
      shell = vim.o.shell,
    })

    local Terminal = require("toggleterm.terminal").Terminal

    -- Lazygit terminal (dedicated git UI)
    local lazygit = Terminal:new({
      cmd = "lazygit",
      direction = "float",
      float_opts = {
        border = "curved",
        width = function() return math.floor(vim.o.columns * 0.9) end,
        height = function() return math.floor(vim.o.lines * 0.9) end,
      },
      on_open = function(term)
        vim.cmd("startinsert!")
      end,
    })

    -- Opencode terminal (right panel)
    local opencode = Terminal:new({
      cmd = "opencode",
      direction = "vertical",
      on_open = function(term)
        vim.cmd("startinsert!")
      end,
    })

    -- Bottom terminal
    local bottom_term = Terminal:new({
      direction = "horizontal",
      on_open = function(term)
        vim.cmd("startinsert!")
      end,
    })

    -- Keymaps
    vim.keymap.set("n", "<leader>gg", function() lazygit:toggle() end, { desc = "Lazygit" })
    vim.keymap.set("n", "<leader>to", function() opencode:toggle() end, { desc = "Toggle opencode (right)" })
    vim.keymap.set("n", "<leader>tt", function() bottom_term:toggle() end, { desc = "Toggle terminal (bottom)" })

    -- Terminal mode mappings (escape terminal mode)
    vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
    vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Move to left split" })
    vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Move to lower split" })
    vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Move to upper split" })
    vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Move to right split" })
  end,
}
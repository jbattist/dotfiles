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
  end,
}
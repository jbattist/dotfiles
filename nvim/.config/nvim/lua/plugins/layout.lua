return {
  dir = ".",
  name = "layout",
  config = function()
    vim.api.nvim_create_user_command("Layout", function()
      vim.cmd("Neotree show")
      vim.cmd("wincmd l")

      local Terminal = require("toggleterm.terminal").Terminal

      local opencode = Terminal:new({
        cmd = "opencode",
        direction = "vertical",
        count = 6,
      })
      opencode:toggle()

      vim.cmd("wincmd h")

      local bottom = Terminal:new({
        direction = "horizontal",
        count = 5,
      })
      bottom:toggle()

      vim.cmd("wincmd k")
    end, { desc = "Open VS Code-like layout" })
  end,
}
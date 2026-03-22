-- A custom command to launch the full VS Code-like layout in one shot
return {
  dir = ".", -- No actual plugin, just config
  config = function()
    vim.api.nvim_create_user_command("Layout", function()
      -- 1. Open neo-tree on the left
      vim.cmd("Neotree show")

      -- 2. Move focus back to the main editor
      vim.cmd("wincmd l")

      -- 3. Open a horizontal terminal at the bottom
      local Terminal = require("toggleterm.terminal").Terminal
      local bottom = Terminal:new({
        direction = "horizontal",
        count = 5,
      })
      bottom:toggle()

      -- 4. Move focus back to editor, open vertical split on the right
      vim.cmd("wincmd k")
      local opencode = Terminal:new({
        cmd = "opencode",
        direction = "vertical",
        count = 6,
      })
      opencode:toggle()

      -- 5. Return focus to editor
      vim.cmd("wincmd h")
      vim.cmd("wincmd l") -- center pane
    end, { desc = "Open VS Code-like layout" })

    vim.keymap.set("n", "<leader>L", ":Layout<CR>", { desc = "Launch VS Code layout" })
  end,
}
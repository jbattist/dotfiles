return {
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },
  { "catppuccin/nvim", name = "catppuccin", lazy = false, priority = 1000 },
  { "Mofiqul/dracula.nvim", name = "dracula", lazy = false, priority = 1000 },
  { "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
  { "rose-pine/neovim", name = "rose-pine", lazy = false, priority = 1000 },
  { "sainnhe/everforest", lazy = false, priority = 1000 },
  { "Mofiqul/vscode.nvim", name = "vscode", lazy = false, priority = 1000 },
  { "nyoom-engineering/oxocarbon.nvim", lazy = false, priority = 1000 },

  -- Theme picker and persistence
  {
    dir = ".",
    name = "theme-picker",
    priority = 999,
    config = function()
      -- Default theme
      local theme_file = vim.fn.stdpath("data") .. "/current_theme.txt"

      -- Load saved theme or fall back to tokyonight
      local function load_saved_theme()
        local f = io.open(theme_file, "r")
        if f then
          local theme = f:read("*l")
          f:close()
          return theme
        end
        return "tokyonight-night"
      end

      -- Save theme choice
      local function save_theme(name)
        local f = io.open(theme_file, "w")
        if f then
          f:write(name)
          f:close()
        end
      end

      -- Apply on startup
      local ok, _ = pcall(vim.cmd.colorscheme, load_saved_theme())
      if not ok then
        vim.cmd.colorscheme("tokyonight-night")
      end

      -- Theme switcher: Space + T to pick a theme with Telescope
      vim.keymap.set("n", "<leader>T", function()
        vim.cmd("Telescope colorscheme enable_preview=true")
      end, { desc = "Switch theme" })

      -- Auto-save when theme changes
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function(args)
          save_theme(args.match)
        end,
      })
    end,
  },
}
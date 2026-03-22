return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000, -- Load before other plugins
  config = function()
    require("catppuccin").setup({
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      transparent_background = false,
      integrations = {
        neotree = true,
        treesitter = true,
        cmp = true,
        gitsigns = true,
        telescope = true,
        which_key = true,
      },
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
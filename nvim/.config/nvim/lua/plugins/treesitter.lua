return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    ---@diagnostic disable-next-line: missing-fields
    require("nvim-treesitter").setup({
      ensure_installed = {
        "lua", "python", "javascript", "typescript", "bash",
        "json", "yaml", "toml", "html", "css", "markdown",
        "markdown_inline", "vim", "vimdoc", "go", "rust",
      },
      auto_install = true,
    })
  end,
}
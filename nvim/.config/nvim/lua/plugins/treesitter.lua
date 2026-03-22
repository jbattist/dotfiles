return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- The rewritten nvim-treesitter (2024+) no longer uses nvim-treesitter.configs.
    -- setup() only accepts install_dir; parsers are managed via :TSInstall / build hook.
    require("nvim-treesitter").setup()

    -- Ensure parsers are installed on first load
    local parsers = {
      "lua", "python", "javascript", "typescript", "bash",
      "json", "yaml", "toml", "html", "css", "markdown",
      "markdown_inline", "vim", "vimdoc", "go", "rust",
    }
    require("nvim-treesitter.install").install(parsers)
  end,
}
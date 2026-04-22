-- nvim-treesitter 1.x: no nvim-treesitter.configs; do not lazy-load (see plugin docs).
local parsers = {
  "lua",
  "vim",
  "vimdoc",
  "query",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "typescript",
  "javascript",
  "tsx",
  "json",
  "yaml",
  "bash",
  "html",
  "css",
  "scss",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()
      require("nvim-treesitter").install(parsers)

      local group = vim.api.nvim_create_augroup("setup-nvim-treesitter-highlight", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = "*",
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}

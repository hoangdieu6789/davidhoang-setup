vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ~/.local/bin (tree-sitter CLI) and ~/.local/go/bin must be on PATH before Lazy runs
-- plugin builds (nvim-treesitter :TSUpdate shells out to `tree-sitter`).
local function prepend_env_path(dir)
  if vim.fn.isdirectory(dir) ~= 1 then
    return
  end
  local p = vim.env.PATH or ""
  if (":" .. p .. ":"):find(":" .. dir .. ":", 1, true) then
    return
  end
  vim.env.PATH = dir .. ":" .. p
end

local home = vim.env.HOME or vim.fn.expand("~")
prepend_env_path(home .. "/.local/bin")
prepend_env_path(home .. "/.local/go/bin")

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = { lazy = true },
  install = { colorscheme = { "tokyonight" } },
  checker = { enabled = true, frequency = 86400 },
  performance = {
    rtp = {
      reset = false,
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

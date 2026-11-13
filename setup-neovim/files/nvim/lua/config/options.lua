local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.wrap = false
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.cursorline = true
opt.mouse = "a"
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.termguicolors = true
opt.timeoutlen = 300
opt.updatetime = 250
opt.completeopt = "menu,menuone,noselect"
opt.clipboard:append("unnamedplus")

vim.filetype.add({
  extension = {
    mod = "gomod",
    sum = "gosum",
    workspace = "gomod",
    -- MDX (Markdown + JSX, e.g. Next.js docs): Markdown highlighting and markdownlint.
    mdx = "markdown",
  },
})

-- Neovim 0.11+ hides diagnostic text by default (only a sign in the left column).
-- Show the message at the end of the line, so LSP and lint problems are easy to see.
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded", source = true },
})

local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write buffer" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })

map("n", "<leader>ff", function()
  require("telescope.builtin").find_files()
end, { desc = "Find files" })
map("n", "<leader>fg", function()
  require("telescope.builtin").live_grep()
end, { desc = "Live grep" })
map("n", "<leader>fb", function()
  require("telescope.builtin").buffers()
end, { desc = "Buffers" })

map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    local function opts(desc)
      return { buffer = buf, desc = desc }
    end
    map("n", "gd", vim.lsp.buf.definition, opts("Goto definition"))
    map("n", "gr", vim.lsp.buf.references, opts("References"))
    map("n", "K", vim.lsp.buf.hover, opts("Hover"))
    map("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename"))
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
    map("n", "<leader>f", function()
      vim.lsp.buf.format({ async = true })
    end, opts("Format buffer"))
  end,
})

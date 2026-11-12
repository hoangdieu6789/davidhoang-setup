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
map("n", "<leader>fw", function()
  require("telescope.builtin").grep_string()
end, { desc = "Find word under cursor (project)" })
map("n", "<leader>fr", function()
  require("telescope.builtin").resume()
end, { desc = "Reopen last search" })
map("n", "<leader>fo", function()
  require("telescope.builtin").oldfiles()
end, { desc = "Recent files" })
-- Space fd: find a folder by name, then show it in the file tree.
map("n", "<leader>fd", function()
  local fd = vim.fn.executable("fd") == 1 and "fd" or (vim.fn.executable("fdfind") == 1 and "fdfind" or nil)
  local cmd = fd and { fd, "--type", "d", "--hidden", "--exclude", ".git" }
    or { "find", ".", "-type", "d", "-not", "-path", "*/.git*", "-not", "-path", "*/node_modules/*" }
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")
  require("telescope.builtin").find_files({
    prompt_title = "Find folder",
    find_command = cmd,
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local entry = state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then
          require("nvim-tree.api").tree.find_file({ buf = entry.path or entry[1], open = true, focus = true })
        end
      end)
      return true
    end,
  })
end, { desc = "Find folder (show in tree)" })
-- Space fG: like Space fg, but asks which folder to search in first (Tab completes folder names).
map("n", "<leader>fG", function()
  vim.ui.input({ prompt = "Search in folder: ", completion = "dir" }, function(dir)
    if dir == nil then
      return
    end
    if dir == "" then
      dir = "."
    end
    require("telescope.builtin").live_grep({ search_dirs = { dir }, prompt_title = "Grep in " .. dir })
  end)
end, { desc = "Grep in a folder" })
-- Space g = git. Telescope lists (Enter on a branch checks it out).
map("n", "<leader>gs", function()
  require("telescope.builtin").git_status()
end, { desc = "Git status (changed files)" })
map("n", "<leader>gc", function()
  require("telescope.builtin").git_commits()
end, { desc = "Git commits (project)" })
map("n", "<leader>gf", function()
  require("telescope.builtin").git_bcommits()
end, { desc = "Git commits (this file)" })
map("n", "<leader>gb", function()
  require("telescope.builtin").git_branches()
end, { desc = "Git branches" })
map("n", "<leader>/", function()
  require("telescope.builtin").current_buffer_fuzzy_find()
end, { desc = "Search in this file" })

map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "File tree" })

-- Windows: easier than Ctrl-w. Ctrl + h/j/k/l = move left/down/up/right (same as hjkl).
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Space s = "split" group (press Space s and wait to see the list).
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Split vertical (left | right)" })
map("n", "<leader>sh", "<cmd>split<CR>", { desc = "Split horizontal (top / bottom)" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close this split" })
map("n", "<leader>so", "<cmd>only<CR>", { desc = "Close other splits" })
map("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
map("n", "<leader>sm", "<C-w>_<C-w>|", { desc = "Maximize this split" })

-- Neotest (Go via neotest-go): needs `go` on PATH and Tree-sitter `go` parser.
map("n", "<leader>tn", function()
  require("neotest").run.run()
end, { desc = "Test nearest" })
map("n", "<leader>tf", function()
  require("neotest").run.run(vim.fn.expand("%"))
end, { desc = "Test file" })
map("n", "<leader>ta", function()
  require("neotest").run.run(vim.fn.getcwd())
end, { desc = "Test suite (cwd)" })
map("n", "<leader>ts", function()
  require("neotest").summary.toggle()
end, { desc = "Test summary" })
map("n", "<leader>to", function()
  require("neotest").output.open({ enter = true })
end, { desc = "Test output" })
map("n", "<leader>tS", function()
  require("neotest").run.stop()
end, { desc = "Stop tests" })

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
    map("n", "gr", function()
      require("telescope.builtin").lsp_references()
    end, opts("References (with preview)"))
    map("n", "K", vim.lsp.buf.hover, opts("Hover"))
    map("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename"))
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
    map("n", "<leader>f", function()
      vim.lsp.buf.format({ async = true })
    end, opts("Format buffer"))
  end,
})

-- Linters that are not language servers (nvim-lint). Results show as normal diagnostics.
-- Markdown is linted only on demand (<leader>l shows / hides the problems), so notes stay clean.
-- markdownlint-cli2 is installed by Mason (see lua/config/mason.lua).
-- Rules: put a .markdownlint-cli2.yaml (or .markdownlint.json) in the project to change them.
return {
  {
    "mfussenegger/nvim-lint",
    keys = {
      { "<leader>l", desc = "Lint: show / hide problems" },
      { "<leader>mf", desc = "Markdown: fix lint problems" },
    },
    config = function()
      -- Mason puts its programs here; add it to PATH in case Mason has not started yet.
      local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
      if not (":" .. (vim.env.PATH or "") .. ":"):find(":" .. mason_bin .. ":", 1, true) then
        vim.env.PATH = mason_bin .. ":" .. (vim.env.PATH or "")
      end

      local lint = require("lint")
      lint.linters_by_ft = {
        markdown = { "markdownlint-cli2" },
      }

      local function try_lint()
        local names = lint.linters_by_ft[vim.bo.filetype] or {}
        for _, name in ipairs(names) do
          local linter = lint.linters[name]
          local cmd = type(linter) == "table" and linter.cmd or name
          if type(cmd) == "string" and vim.fn.executable(cmd) == 1 then
            lint.try_lint(name)
          end
        end
      end

      -- Problems found by the linters in this buffer (nvim-lint keeps one namespace per linter).
      local function shown(bufnr)
        for _, name in ipairs(lint.linters_by_ft[vim.bo[bufnr].filetype] or {}) do
          if #vim.diagnostic.get(bufnr, { namespace = lint.get_namespace(name) }) > 0 then
            return true
          end
        end
        return false
      end

      local function clear(bufnr)
        for _, name in ipairs(lint.linters_by_ft[vim.bo[bufnr].filetype] or {}) do
          vim.diagnostic.reset(lint.get_namespace(name), bufnr)
        end
      end

      -- On demand: the first press shows the problems, the next press hides them. Editing the
      -- file does not run the linter again, so nothing pops up while you write.
      vim.keymap.set("n", "<leader>l", function()
        local bufnr = vim.api.nvim_get_current_buf()
        if shown(bufnr) then
          clear(bufnr)
          vim.notify("Lint problems hidden")
        else
          try_lint()
        end
      end, { desc = "Lint: show / hide problems" })

      -- Let markdownlint-cli2 fix what it can (blank lines, spaces, list style ...), then reload.
      vim.keymap.set("n", "<leader>mf", function()
        if vim.bo.filetype ~= "markdown" then
          return vim.notify("Not a Markdown file", vim.log.levels.WARN)
        end
        vim.cmd("silent update")
        vim.fn.system({ "markdownlint-cli2", "--fix", vim.api.nvim_buf_get_name(0) })
        vim.cmd("checktime")
        clear(0)
      end, { desc = "Markdown: fix lint problems" })
    end,
  },
}

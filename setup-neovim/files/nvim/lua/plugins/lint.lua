-- Linters that are not language servers (nvim-lint). Results show as normal diagnostics.
-- markdownlint-cli2 is installed by Mason (see lua/config/mason.lua).
-- Rules: put a .markdownlint-cli2.yaml (or .markdownlint.json) in the project to change them.
return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
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

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("UserLint", { clear = true }),
        callback = try_lint,
      })

      vim.keymap.set("n", "<leader>l", try_lint, { desc = "Lint this file" })
      -- The plugin loads during the first BufReadPost, before the filetype is set: lint a bit later.
      vim.schedule(try_lint)
    end,
  },
}

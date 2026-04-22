return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "folke/which-key.nvim" },
    config = function()
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gitsigns = require("gitsigns")
          local function d(text)
            return "Gitsigns: " .. text
          end
          local function map(mode, lhs, rhs, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, lhs, rhs, opts)
          end

          map("n", "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gitsigns.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = d("Next hunk") })

          map("n", "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gitsigns.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = d("Previous hunk") })

          map("n", "<leader>hs", gitsigns.stage_hunk, { desc = d("Stage hunk") })
          map("n", "<leader>hr", gitsigns.reset_hunk, { desc = d("Reset hunk") })
          map("v", "<leader>hs", function()
            gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = d("Stage hunk (visual)") })
          map("n", "<leader>hS", gitsigns.stage_buffer, { desc = d("Stage whole buffer") })
          map("n", "<leader>hp", gitsigns.preview_hunk, { desc = d("Preview hunk") })
          map("n", "<leader>hb", function()
            gitsigns.blame_line({ full = true })
          end, { desc = d("Blame line (full)") })
        end,
      })
      pcall(function()
        require("which-key").add({
          { "<leader>h", group = "Gitsigns" },
        })
      end)
    end,
  },
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    event = "VeryLazy",
    config = true,
  },
}

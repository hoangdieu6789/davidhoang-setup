-- Terminal inside Neovim.
--   Ctrl-\      toggle a terminal at the bottom (press again to hide; programs keep running)
--   Space T f   floating terminal, Space T v   terminal on the right, Space T h   terminal at the bottom
-- Inside these terminals: Esc Esc = leave typing mode, Ctrl-h/j/k/l = move to another window.
-- (Only for toggleterm terminals, so lazygit and other tools still get Esc and Ctrl keys.)
return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      { [[<C-\>]], mode = { "n", "i", "t" }, desc = "Toggle terminal" },
      { "<leader>Tf", "<cmd>ToggleTerm direction=float<CR>", desc = "Terminal: float" },
      { "<leader>Tv", "<cmd>ToggleTerm direction=vertical<CR>", desc = "Terminal: right" },
      { "<leader>Th", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "Terminal: bottom" },
    },
    opts = {
      open_mapping = [[<C-\>]],
      direction = "horizontal",
      size = function(term)
        if term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
        return 15
      end,
      float_opts = { border = "rounded" },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
      vim.api.nvim_create_autocmd("TermOpen", {
        group = vim.api.nvim_create_augroup("UserToggletermKeys", { clear = true }),
        pattern = "term://*toggleterm#*",
        callback = function(ev)
          local function tmap(lhs, rhs, desc)
            vim.keymap.set("t", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          tmap("<Esc><Esc>", [[<C-\><C-n>]], "Leave terminal typing mode")
          tmap("<C-h>", [[<Cmd>wincmd h<CR>]], "Go to left window")
          tmap("<C-j>", [[<Cmd>wincmd j<CR>]], "Go to lower window")
          tmap("<C-k>", [[<Cmd>wincmd k<CR>]], "Go to upper window")
          tmap("<C-l>", [[<Cmd>wincmd l<CR>]], "Go to right window")
        end,
      })
    end,
  },
}

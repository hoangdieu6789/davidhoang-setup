return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Faster sorting in big projects (compiled with make; skipped if the build failed).
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    event = "VeryLazy",
    config = function()
      require("telescope").setup({})
      pcall(require("telescope").load_extension, "fzf")
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>s", group = "Split" },
        { "<leader>f", group = "Find" },
      },
    },
  },
}

local mason_cfg = require("config.mason")

return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      require("mason").setup({
        ui = { border = "rounded" },
        -- registries = { "github:mason-org/mason-registry@TAG_FROM_RELEASES_PAGE" },
      })

      for _, name in ipairs(mason_cfg.lsp_servers) do
        vim.lsp.config(name, { capabilities = capabilities })
      end

      require("mason-lspconfig").setup({
        automatic_enable = true,
      })

      -- Install by Mason package name (avoid ensure_installed / empty registry map).
      local function install_mason_pkgs(success)
        if not success then
          vim.notify(
            "[mason] Registry refresh failed. Run :MasonUpdate, or remove ~/.local/share/nvim/mason/registries and restart.",
            vim.log.levels.ERROR
          )
          return
        end
        local mr = require("mason-registry")
        for _, pkg_name in ipairs(mason_cfg.mason_packages) do
          local ok, pkg = pcall(mr.get_package, pkg_name)
          if not ok then
            vim.notify(("[mason] Package %q not found in registry"):format(pkg_name), vim.log.levels.WARN)
          elseif not pkg:is_installed() and not pkg:is_installing() then
            pkg:install()
          end
        end
      end

      -- Defer so mason-lspconfig.setup()'s registry refresh can start first; then we queue installs.
      vim.schedule(function()
        require("mason-registry").refresh(vim.schedule_wrap(install_mason_pkgs))
      end)

      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("UserLspFormat", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local clients = vim.lsp.get_clients({
            bufnr = bufnr,
            method = "textDocument/formatting",
          })
          if #clients > 0 then
            vim.lsp.buf.format({ bufnr = bufnr, async = false })
          end
        end,
      })
    end,
  },
}

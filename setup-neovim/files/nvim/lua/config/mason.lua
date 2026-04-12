-- Single source of truth for Mason package ids <-> nvim-lspconfig server names.
return {
  lsp_servers = {
    "gopls",
    "ts_ls",
    "angularls",
    "jsonls",
    "bashls",
    "yamlls",
  },
  mason_packages = {
    "gopls",
    "typescript-language-server",
    "angular-language-server",
    "json-lsp",
    "bash-language-server",
    "yaml-language-server",
  },
}

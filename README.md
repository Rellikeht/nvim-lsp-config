# nvim-lsp-config

Just a bunch of nvim lsp configurations in one place.
Basically my own lsp zero with lazy loading for older versions.

## Dependencies

### Required

- neovim/nvim-lspconfig - to make this work in nvim < 0.11.2 and to 
  provide utils
- mfussenegger/nvim-jdtls - to use jdtls setup

### Optional

- p00f/clangd_extensions.nvim - for clangd setup

## Features

- lazy loading of lsp configurations for appropriate file types
- helpers for displaying hover docs in `preview-window` and toggling 
  hover in insert mode
- tags caching - makes `:tag` work as expected after `<c-t>` with lsp 
  provided `tagfunc()` (why isn't this default)

## TODO

- proper documentation
- live lsp config edition

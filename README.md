# nvim-lsp-config

Just a bunch of nvim lsp configurations in one place.
Basically my own lsp zero with lazy loading for older versions.

## Dependencies

- neovim/nvim-lspconfig - to make this work in nvim < 0.11.2 and to 
  provide utils
- mfussenegger/nvim-jdtls - to use jdtls setup
- p00f/clangd_extensions.nvim - for clangd setup

## Features

- lazy loading of lsp configurations for appropriate file types
- helpers for displaying hover docs in `preview-window` and toggling 
  hover in insert mode

## TODO

- proper documentation
- live lsp config edition

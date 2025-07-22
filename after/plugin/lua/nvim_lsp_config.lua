if vim.fn.has("nvim-0.10") == 0 then
  return -- Not supported so don't even bother :(
end

-- helpers {{{

local function reedit()
  if vim.b.readonly then
    vim.cmd.view()
  else
    vim.cmd.edit()
  end
end

---@diagnostic disable: unused-local
local lspconfig_util = require("lspconfig.util")
local lazy_utils = require("lazy_utils")

local default_server_setup = {
  preselectSupport = false,
  preselect = false,
  single_file_support = true,
  on_attach = lsp_attach,
  capabilities = Capabilities,
  settings = { telemetry = { enable = false } },
}

local lsp_config
if vim.fn.has("nvim-0.11.2") == 1 then
  lsp_config = function(name, config)
    vim.lsp.config(name, config)
  end
else
  local lspconfig = require("lspconfig")
  lsp_config = function(name, config)
    lspconfig[name].setup(config)
  end
end

local server_augroup_id = 0
local function lazy_setup(filetypes, name, loader, args)
  lazy_utils.load_on_filetypes(
    filetypes, function()
      local success, setup = pcall(loader, args)
      if success then
        lsp_config(name, setup)
      else
        lsp_config(name, loader)
      end

      -- all because shit won't start on it's own when
      -- it's needed and will start when it isn't
      lazy_utils.load_on_cursor(function()
        vim.cmd.LspStart(name)
      end)
    end
  )
end

-- }}}

-- settings {{{

local python_line_length = 76

--  }}}

-- command {{{

vim.api.nvim_create_user_command(
  "LspConfig", function(opts)
    for _, name in pairs(opts.fargs) do
      lsp_config(name, default_server_setup)
    end
  end, { nargs = "+" }
)

--  }}}

local servers = { -- {{{
  -- must have
  [{ "python" }] = {
    -- :(
    -- "pylyzer",
    -- TODO check
  },
  [{
    "ocaml",
    "ocamlinterface",
    "menhir",
    "ocamllex",
    "reason",
    "dune",
    "opam",
  }] = "ocamllsp",
  [{ "haskell", "cabal" }] = "hls",
  [{ "html" }] = "superhtml",
  [{ "html" }] = "html",
  [{ "css", "scss", "less" }] = "cssls",
  [{ "sh", "bash", "zsh" }] = "bashls",

  -- sometimes needed
  [{ "zig", "zir" }] = "zls",
  [{ "latex", "tex", "plaintex", "bib" }] = "texlab",
  [{
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.jsx",
  }] = { "ts_ls", "denols" },

  -- just in case
  [{ "erlang" }] = "erlangls",
  [{ "odin" }] = "ols",
  [{ "nickel", "ncl" }] = "nickel_ls",
  [{ "scala" }] = "metals",
  [{ "kotlin" }] = "kotlin_language_server",
  [{ "ada" }] = "ada_ls",
  [{ "roc" }] = "roc_ls",
  [{ "r", "rmd", "quarto" }] = "r_language_server",
  [{ "teal" }] = "teal_ls",
  [{ "autohotkey" }] = "autohotkey_lsp",
  [{ "yaml.ansible" }] = "ansiblels",
  [{ "dhall" }] = "dhall_lsp_server",
  [{ "star", "bzl", "BUILD.bazel" }] = "starlark_rust",
  [{ "gleam" }] = "gleam",
  [{ "fortran" }] = "fortls",
  [{ "cs" }] = "csharp_ls",
  [{ "clojure" }] = "clojure_lsp",
  [{ "cmake" }] = "neocmake",
  [{ "glsl", "vert", "tesc", "tese", "frag", "geom", "comp" }] = {
    "glsl_analyzer",
  },
  [{ "gd", "gdscript", "gdscript3" }] = "gdscript",
  [{ "gdshader", "gdshaderinc" }] = "gdshader_lsp",

  -- test and select (or leave multiple)
  [{ "solidity" }] = { "solang", "solc", "solidity_ls" },
  [{ "vhdl", "vhd" }] = { "vhdl_ls", "ghdl_ls" },
  [{ "verilog", "systemverilog" }] = {
    "svls",
    "veridain",
    "verible",
  },

  [{ "scheme.guile" }] = "guile_ls",
  [{ "scheme" }] = "scheme_langserver",
}

for ftypes, names in pairs(servers) do
  if type(names) == "table" then
    for _, name in pairs(names) do
      lazy_setup(ftypes, name, default_server_setup)
    end
  else
    lazy_setup(ftypes, names, default_server_setup)
  end
end

-- TODO is this optimal way to do this
if vim.fn.executable("ast-grep") == 1 then
  lazy_setup("*", "ast_grep", default_server_setup)
  -- lsp_config("ast_grep", default_server_setup)
end

-- }}}

lazy_setup(
  { "lua" }, "lua_ls", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities, -- }}}
    on_init = function(client)   -- {{{
      ---@diagnostic disable: undefined-field
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if vim.loop.fs_stat(path .. "/.luarc.json") or
            vim.loop.fs_stat(path .. "/.luarc.jsonc") then
          return
        end
      end

      client.config.settings.Lua = vim.tbl_deep_extend(
        "force", client.config.settings.Lua, {
          runtime = {
            -- Tell the language server which version of Lua you're using
            -- (most likely LuaJIT in the case of Neovim)
            version = "LuaJIT",
          }, -- Make the server aware of Neovim runtime files
          workspace = {
            checkThirdParty = false,
            library = {
              vim.env.VIMRUNTIME,
              -- Depending on the usage, you might want to add additional paths here.
              -- "${3rd}/luv/library"
              -- "${3rd}/busted/library",
            },

            -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
            -- library = vim.api.nvim_get_runtime_file("", true)
          },
        }
      )
    end,         -- }}}
    settings = { -- {{{
      Lua = {
        runtime = {
          version = "LuaJIT", -- Setup your lua path
          path = {
            "?.lua",
            "?/init.lua",
            unpack(vim.split(package.path, ";")),
          },
        },
        hint = { enable = true },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = { "vim", "require" },
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          -- library = vim.api.nvim_get_runtime_file("", true),
        },
        format = {
          defaultConfig = {
            indent_style = "space",
            indent_size = 2,
          },
        },
        telemetry = { enable = false },
      },
    }, -- }}}
  }
)

lazy_setup(
  { "python" }, "pylsp", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities,
    -- }}}
    settings = { -- {{{
      pylsp = {
        plugins = {
          jedi_completion = {
            --
            fuzzy = true,
            eager = false,
            include_funciton_objects = true,
            include_class_objects = true,
            resolve_at_most = 100,
          },
          pylsp_mypy = {
            enabled = true,
            live_mode = false,
            dmypy = true,
            follow_imports = "silent" -- "normal" ?
          },
          pylint = {
            enabled = true,
          },
          pyls_isort = { enabled = true, },
          black = { enabled = true, maxLineLength = python_line_length },
          pycodestyle = { line_length = python_line_length },
          rope_autoimport = { enabled = true, eager = true },
        },
      },

      flags = { debounce_text_changes = 100 },
    }, -- }}}
  }
)

lazy_setup(
  { "python" }, "ruff", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities,
    -- }}}
    init_options = {
      settings = { -- {{{
        lineLength = python_line_length,
      },         -- }}}
    }
  }
)


lazy_setup(
  { "nix" }, "nil_ls", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities, -- }}}
    settings = {                 -- {{{
      ["nil"] = {
        formatting = { command = { "alejandra" } },
        diagnostics = {
          ignored = {
            -- "unused_rec",
            -- "empty_let_in",
            -- "unused_with",
          },
        },
        nix = {
          maxMemoryMB = 4096,
          flake = {
            --
            autoArchive = false,
            autoEvalInputs = false,
          },
        },
      },
    }, -- }}}
  }
)

lazy_setup(
  { "nim" }, "nim_langserver", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities, -- }}}
    settings = {                 -- {{{
      nim = {
        notificationVerbosity = "error",
        nimsuggestIdleTimeout = 9999999999,
        autoRestart = true,
        logNimsuggest = false,
      },
    }, -- }}}
  }
)

-- fucking almost useless shit
-- that crashes on every fucking input
lazy_setup(
  { "typst" }, "tinymist", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities,
    offset_encoding = "utf-8",
    -- }}}
    settings = { -- {{{
      offset_encoding = "utf-8",
      semanticTokens = "disable",
      exportPdf = "never",
    }, -- }}}
  }
)

lazy_setup(
  { "go", "gomod", "gowork", "gotmpl" }, "gopls", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities, -- }}}
    settings = {                 -- {{{
      gopls = {
        completionBudget = "0",
        usePlaceholders = true,
        experimentalPostfixCompletions = true,
        analyses = { unusedparams = true, shadow = true },
        staticcheck = true,
        vulncheck = "Imports",
      },
    }, -- }}}
  }
)

lazy_setup(
  { "julia" }, "julials", function()
    local settings = {
      -- boilerplate {{{
      preselectSupport = false,
      preselect = false,
      single_file_support = true,
      on_attach = lsp_attach,
      capabilities = Capabilities,
      settings = { telemetry = { enable = false } }, -- }}}
    }
    if vim.fn.executable("julials") == 1 then
      settings.cmd = { "julials" }
    end
    return settings
  end
)

-- TODO copying rust-project.json from config dir
-- to current dir to make this shit work

-- No idea if all of that is really needed
lazy_setup(
  { "rust" }, "rust_analyzer", {
    -- boilerplate {{{
    on_attach = lsp_attach,
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    capabilities = Capabilities, -- }}}
    settings = {                 -- {{{
      ["rust-analyzer"] = {
        standalone = true,
        workspaceFolders = false,
        workspace = { workspaceFolders = false },

        completion = { contextSupport = true },
        imports = {
          granularity = { group = "module" },
          prefix = "self",
        },
        cargo = {
          buildScripts = { enable = true },
          allFeatures = true,
        },
        procMacro = { enable = true },
      },
    }, -- }}}
  }
)

local c_files = { "c", "cpp", "objc", "objcpp", "cuda" }

lazy_setup(
  c_files, "clangd", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities, -- }}}
    cmd = {                      -- {{{
      "clangd",
      "--clang-tidy",
      "--enable-config",
      "--header-insertion=never",
      "--completion-style=detailed",
      "--pch-storage=memory",
      "--background-index",
      "--background-index-priority=low",
    },            -- }}}
    filetypes = { --  {{{
      "c",
      "cpp",
      "objc",
      "objcpp",
      "cuda",
    },           --  }}}
    settings = { -- {{{
    },           -- }}}
  }
)

lazy_utils.load_on_filetypes(
  c_files, function()
    require("clangd_extensions").setup(
      {
        inlay_hints = { -- {{{
          -- Options other than `highlight' and `priority' only work
          -- if `inline' is disabled
          inline = vim.fn.has("nvim-0.10") == 1,

          -- Only show inlay hints for the current line
          only_current_line = false,

          -- Event which triggers a refresh of the inlay hints.
          -- You can make this { "CursorMoved" } or { "CursorMoved,CursorMovedI" } but
          -- note that this may cause higher CPU usage.
          -- This option is only respected when only_current_line is true.
          only_current_line_autocmd = { "CursorHold" },

          -- whether to show parameter hints with the inlay hints or not
          show_parameter_hints = true,

          -- prefix for parameter hints
          parameter_hints_prefix = "<- ",

          -- prefix for all the other hints (type, chaining)
          other_hints_prefix = "=> ",

          -- whether to align to the length of the longest line in the file
          max_len_align = false,

          -- padding from the left if max_len_align is true
          max_len_align_padding = 1,

          -- whether to align to the extreme right or not
          right_align = false,

          -- padding from the right if right_align is true
          right_align_padding = 7, -- The color of the hints
          highlight = "Comment",

          -- The highlight group priority for extmark
          priority = 100,
        },               -- }}}
        ast = {          -- {{{
          -- These are unicode, should be available in any font
          role_icons = { -- {{{
            type = "🄣",
            declaration = "🄓",
            expression = "🄔",
            statement = ";",
            specifier = "🄢",
            ["template argument"] = "🆃",
          },             -- }}}
          kind_icons = { -- {{{
            Compound = "🄲",
            Recovery = "🅁",
            TranslationUnit = "🅄",
            PackExpansion = "🄿",
            TemplateTypeParm = "🅃",
            TemplateTemplateParm = "🅃",
            TemplateParamObject = "🅃",
          }, -- }}}
          highlights = { detail = "Comment" },
        },   -- }}}
        -- {{{
        memory_usage = { border = "none" },
        symbol_info = { border = "none" },
        -- }}}
      }
    )
  end
)

lazy_setup(
  { "elixir" }, "elixirls", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities, -- }}}
    settings = {                 -- {{{
      fetchDeps = false,
      suggestSpecs = true,
      dialyzerEnabled = true,
      incrementalDialyzer = true,
      enableTestLenses = true,
      mixEnv = true,
    },
    cmd = { "elixir-ls" },
    -- }}}
  }
)

lazy_setup(
  { "ps1" }, "powershell_es", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities, -- }}}
    settings = {                 -- {{{
    },

    bundle_path = "~/.powershell_es",
    -- }}}
  }
)

lazy_setup(
  { "arduino" }, "arduino_language_server", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities,
    -- }}}
    cmd = { --  {{{
      "arduino-language-server",
      -- "-log",
      "-jobs",
      "0",
      -- gives nothing
      -- "-skip-libraries-discovery-on-rebuild",
    },           --  }}}
    settings = { -- {{{
    },

    -- disabledFeatures = { "semanticTokens" },
    autostart = true,
    -- }}}
  }
)

-- {{{

-- lspconfig.pylyzer.setup(
--   {
--     cmd = {"pylyzer", "--server"},

--     --   root_dir = function(fname)
--     --     local root_files = {
--     --       "setup.py",
--     --       "tox.ini",
--     --       "requirements.txt",
--     --       "Pipfile",
--     --       "pyproject.toml"
--     --     }
--     --     return lspconfig_util.root_pattern(unpack(root_files))(fname) or
--     --              lspconfig_util.find_git_ancestor(fname)
--     --   end,

--     single_file_support = true,
--     settings = {
--       python = {
--         diagnostics = true,
--         inlayHints = true,
--         smartCompletion = true,
--         checkOnType = true,
--       },
--     },
--   }
-- )

-- }}}

-- {{{

-- This has some weird problems
-- lspconfig.java_language_server.setup({
--   cmd = {'java-language-server'},
--   preselectSupport = false,
--   preselect = false,
--   single_file_support = true,
--   on_attach = lsp_attach,
--   capabilities = Capabilities,
--   -- settings = {}
-- })

-- }}}

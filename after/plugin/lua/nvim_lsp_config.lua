if vim.fn.has("nvim-0.10") == 0 then
  return -- Not supported so don't even bother :(
end

-- helpers {{{

local lspconfig = require("lspconfig")
local lazy_utils = require("lazy_utils")

local default_server_setup = {
  preselectSupport = false,
  preselect = false,
  single_file_support = true,
  on_attach = lsp_attach,
  capabilities = Capabilities,
  settings = { telemetry = { enable = false } },
}

local lsp_config, lsp_setup
if vim.fn.has("nvim-0.11.2") == 1 then
  lsp_config = function(name, config)
    vim.lsp.config(name, config)
  end
  lsp_setup = function(_, name, loader, args)
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
else
  lsp_config = function(name, config)
    lspconfig[name].setup(config)
  end

  lsp_setup = function(filetypes, name, loader, args)
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
end

-- }}}

-- settings {{{
-- defined here because of more than one reference or logic more
-- complicated than just an assignment

local c_files = { "c", "cpp", "objc", "objcpp", "cuda" }
local ltex_plus_files = { "bib",
  "context",
  "gitcommit",
  "html",
  "markdown",
  "org",
  "pandoc",
  "plaintex",
  "quarto",
  "mail",
  "mdx",
  "rmd",
  "rnoweb",
  "rst",
  "tex",
  "latex",
  "typst",
  "xhtml",
}

local python_line_length = 76
local nix_formatting_cmd = "alejandra"
local latex_build_directory = "build"

local texlab_formatter_line_length = vim.o.textwidth
if texlab_formatter_line_length == 0 then
  texlab_formatter_line_length = 80
end

local synctex_previewer = "synctex-previewer"
if vim.fn.executable(synctex_previewer) == 0 then
  synctex_previewer = "zathura"
end

--  }}}

-- commands {{{

vim.api.nvim_create_user_command(
  "LspConfig", function(opts)
    for _, name in pairs(opts.fargs) do
      lsp_config(name, default_server_setup)
    end
  end, { nargs = "+" }
)

--  }}}

if vim.g.lsp_autosetup ~= nil and not vim.g.lsp_autosetup then
  return
end

local servers = { -- {{{
  -- must have
  [{ "python" }] = {
    "ty",
    -- :(
    -- "pylyzer",
    -- TODO use only for completion
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
  [{
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.jsx",
  }] = { "ts_ls", "eslint" }, -- :(
  [{ "erlang" }] = "erlangls",
  [{ "kotlin" }] = "kotlin_language_server",
  [{ "autohotkey" }] = "autohotkey_lsp",

  -- just in case
  [{ "odin" }] = "ols",
  [{ "nickel", "ncl" }] = "nickel_ls",
  [{ "scala" }] = "metals",
  [{ "ada" }] = "ada_ls",
  [{ "roc" }] = "roc_ls",
  [{ "r", "rmd", "quarto" }] = "r_language_server",
  [{ "teal" }] = "teal_ls",
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
  [{ "xml", "xsd", "xsl", "xslt", "svg" }] = "lemmnix",
  [{ "luau" }] = "luau_lsp",
  [{ "nelua" }] = "nelua_lsp",
  [{ "lean" }] = "leanls",
  [{ "dart" }] = "dartls",
  [{ "yaml", "yaml.docker-compose", "yaml.gitlab" }] = "yamlls",
  [{ "tex", "plaintex", "context" }] = "digestif",

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
      lsp_setup(ftypes, name, default_server_setup)
    end
  else
    lsp_setup(ftypes, names, default_server_setup)
  end
end

-- TODO is this optimal way to do this
if vim.fn.executable("ast-grep") == 1 then
  lsp_setup("*", "ast_grep", default_server_setup)
  -- lsp_config("ast_grep", default_server_setup)
end

-- }}}

lsp_setup(
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

lsp_setup(
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

lsp_setup(
  { "python" }, "pyright", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities,
    -- }}}
    settings = { -- {{{
      pyright = {
        analysis = {
          typeCheckingMode = "standard",
          reportUnnecessaryTypeIgnoreComment = "warning",
        },
      },
    }, -- }}}
  }
)

lsp_setup(
  { "python" }, "basedpyright", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities,
    -- }}}
    settings = { -- {{{
      basedpyright = {
        analysis = {
          typeCheckingMode =
              (vim.env.BASEDPYRIGHT_MODE or "recommended"),
          useTypingExtensions = true,
          strictListInference = true,
          strictSetInference = true,
          strictDictInference = true,
          enableTypeIgnoreComments = true,
          inlayHints = {
            variableTypes = false,
            callArgumentNames = false,
            functionReturnTypes = false,
          },
          diagnosticSeverityOverrides = {
            reportUnknownMemberType = false,
            reportUnknownArgumentType = false,
            reportUnknownVariableType = "information",
            reportUnknownParameterType = false,
            -- reportMissingParameterType = "information",
            reportUnannotatedClassAttribute = "information",
            reportMissingTypeArgument = "warning",
            reportCallInDefaultInitializer = false,
            reportUnknownLambdaType = false,
            reportMissingTypeStubs = "information",
            reportIgnoreCommentWithoutRule = false,
            reportImplicitOverride = "information",
            reportExplicitAny = false,
            reportAny = false,
            reportImplicitRelativeImport = "information",
            reportDeprecated = "error",
          },
        },
      },
    }, -- }}}
  }
)

lsp_setup(
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
      },           -- }}}
    }
  }
)

lsp_setup(
  { "nix" }, "nil_ls", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities, -- }}}
    settings = {                 -- {{{
      ["nil"] = {
        formatting = { command = { nix_formatting_cmd } },
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

lsp_setup(
  { "nix" }, "nixd", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities, -- }}}
    settings = {                 -- {{{
      nixd = {
        formatting = { command = { nix_formatting_cmd } },
        nixpkgs = {
          expr = "import <nixpkgs> { }",
        },
      },
    }, -- }}}
  }
)

lsp_setup(
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

lsp_setup(
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

lsp_setup(
  { "latex", "tex", "plaintex", "bib" }, "texlab", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities,
    offset_encoding = "utf-8",
    -- }}}
    settings = { -- {{{
      texlab = {
        diagnosticsDelay = 250,
        formatterLineLength = texlab_formatter_line_length,
        forwardSearch = { executable = synctex_previewer, },
        latexFormatter = "latexindent",
        build = {
          onSave = false,
          args = {
            "-pdf",
            "-interaction=nonstopmode",
            "-synctex=1",
            "-outdir=" .. latex_build_directory,
            "%f",
          },
          logDirectory = latex_build_directory,
          auxDirectory = latex_build_directory,
          pdfDirectory = latex_build_directory,
        },
      },
    }, -- }}}
  }
)

lsp_setup(
  ltex_plus_files, "ltex_plus", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities,
    offset_encoding = "utf-8",
    -- }}}
    settings = { -- {{{
      ltex = {
        -- TODO language
        -- TODO more settings
        enabled = ltex_plus_files,
      },
    }, -- }}}
  }
)

lsp_setup(
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

lsp_setup(
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
      settings.settings.cmd = { "julials" }
    end
    return settings
  end
)

-- TODO copying rust-project.json from config dir
-- to current dir to make this shit work

-- No idea if all of that is really needed
lsp_setup(
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

lsp_setup(
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

lsp_setup(
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

lsp_setup(
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

lsp_setup(
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

lsp_setup(
  { --  {{{
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.jsx",
  }, --  }}}
  "denols", {
    -- boilerplate {{{
    preselectSupport = false,
    preselect = false,
    single_file_support = true,
    on_attach = lsp_attach,
    capabilities = Capabilities,
    root_dir = function(bufnr, on_dir)
      local result = lspconfig.util.root_pattern("deno.json", "deno.jsonc")(
        vim.fn.getbufinfo(bufnr).name
      )
      -- TODO start when ts_ls is not available
      -- I don't need this anyway so it will probably stay like this
      if not result then
        return
      end
      on_dir(result)
    end,
    -- }}}

    init_options = { --  {{{
      lint = true,
      unstable = true,
      suggest = {
        imports = {
          hosts = {
            ["https://deno.land"] = true,
            ["https://cdn.nest.land"] = true,
            ["https://crux.land"] = true,
          },
        },
      },
    },           --  }}}

    settings = { -- {{{
    },
    -- }}}
  }
)

-- lspconfig.java_language_server.setup({ -- TODO {{{
-- This has some weird problems
--   cmd = {'java-language-server'},
--   preselectSupport = false,
--   preselect = false,
--   single_file_support = true,
--   on_attach = lsp_attach,
--   capabilities = Capabilities,
--   -- settings = {}
-- }) -- }}}

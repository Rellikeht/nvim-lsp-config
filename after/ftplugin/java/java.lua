local nvim_local_dir = vim.fn.stdpath("data")
local project_name = vim.fn.fnamemodify(
  vim.fn.getcwd(), ":p:h:t"
)

local workspace_dir =
    nvim_local_dir ..
    "/jdtls-workspaces/" ..
    project_name

-- local classpath

local cmd = {
  "jdtls",
  "-data",
  workspace_dir,
}
-- just copied from nvim-lspconfig
local jvm_args = vim.env["JDTLS_JVM_ARGS"] or ""
for a in string.gmatch(jvm_args, "%S+") do
  table.insert(cmd, "--jvm-arg=" .. a)
end

local config = {
  cmd = cmd,

  settings = {
    java = {
      signatureHelp = { enabled = true },
      symbols = { includeGeneratedCode = true },
      completion = {
        favoriteStaticMembers = {},
        importOrder = { "java", "javax", "com", "org" },
      },

      autobuild = { enabled = false },
      rename = { enabled = true },
      trace = { server = "verbose" },

      import = {
        enabled = true,
        gradle = { enabled = true },
        maven = { enabled = true },
        exclusions = {
          "**/node_modules/**",
          "**/.metadata/**",
          "**/archetype-resources/**",
          "**/META-INF/maven/**",
          "/**/test/**",
        },
      },

      format = { enable = true },
    },
  },
  sources = {
    organizeImports = {
      starThreshold = 9999,
      staticStarThreshold = 9999,
    },
  },
  on_attach = LSP_global_on_attach,

  handlers = { ["language/status"] = function() end },

  root_dir = vim.fs.dirname(
    vim.fs.find(
      {
        "gradlew",
        ".git",
        "mvnw",
        ".hg",
        "pom.xml",
      }, { upward = true }
    )[1]
  ),
}

local success, jdtls = pcall(require, "jdtls")
if success then
  local extendedClientCapabilities =
      jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport =
      true
  config.extendedClientCapabilities = extendedClientCapabilities
  jdtls.start_or_attach(config)
end

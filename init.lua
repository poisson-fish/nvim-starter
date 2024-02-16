-- Lazy.nvim bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "neovim/nvim-lspconfig",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-cmdline",
  "hrsh7th/nvim-cmp",
  "L3MON4D3/LuaSnip",
  "saadparwaiz1/cmp_luasnip",
  "mfussenegger/nvim-dap",
  "rcarriga/nvim-dap-ui",
  "nvim-tree/nvim-tree.lua",
  "nvim-tree/nvim-web-devicons",
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" }
  },
  "Shatur/neovim-ayu",
  "nvim-treesitter/nvim-treesitter",
  {
    "mrcjkb/rustaceanvim",
    version = '^4', -- Recommended
    ft = { 'rust' }
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  }
}, {})

require("mason").setup()
require("mason-lspconfig").setup()

require("mason-lspconfig").setup_handlers({ -- Handles attaching for any LSP installed by mason

  function(server_name)
    require('lspconfig')[server_name].setup({
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        severity_sort = true,
      },
      inlay_hints = {
        enabled = true,
      },
      on_attach = function(client, bufnr)
        if server_name == 'lua_ls' then -- Add a conditional check
          require('lspconfig')[server_name].setup({
            settings = {
              Lua = {
                runtime = {
                  version = 'LuaJIT',
                },
                diagnostics = {
                  globals = { 'vim', 'require' },
                },
                workspace = {
                  library = vim.api.nvim_get_runtime_file("", true),
                },
                telemetry = {
                  enable = false,
                },
              },
            },
          })
        end

        -- Enable completion triggered by <c-x><c-o>
        vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Toggle inlay hints
        local function toggle_inlay_hints()
          if vim.g.inlay_hints_visible then
            vim.g.inlay_hints_visible = false
            vim.lsp.inlay_hint.enable(bufnr, false)
          else
            if client.server_capabilities.inlayHintProvider then
              vim.g.inlay_hints_visible = true
              vim.lsp.inlay_hint.enable(bufnr, true)
            else
              print("no inlay hints available")
            end
          end
        end

        -- Toggle diagnostics
        vim.g.diagnostics_visible = true
        local function toggle_diagnostics()
          if vim.g.diagnostics_visible then
            vim.g.diagnostics_visible = false
            vim.diagnostic.disable()
          else
            vim.g.diagnostics_visible = true
            vim.diagnostic.enable()
          end
        end

        -- Autocmd to show diagnostics on CursorHold
        vim.api.nvim_create_autocmd("CursorHold", {
          buffer = bufnr,
          desc = "✨lsp show diagnostics on CursorHold",
          callback = function()
            local hover_opts = {
              focusable = false,
              close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
              border = "rounded",
              source = "always",
              prefix = " ",
            }
            vim.diagnostic.open_float(nil, hover_opts)
          end,
        })


        -- Buffer local mappings - Use vim.api.nvim_buf_set_keymap
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = bufnr }
        local bufopts = opts
        vim.keymap.set("n", "<space>k", vim.lsp.buf.hover,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp hover for docs" }))
        vim.keymap.set(
          "n",
          "<space>lgD",
          vim.lsp.buf.declaration,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp go to declaration" })
        )
        vim.keymap.set(
          "n",
          "<space>lgd",
          vim.lsp.buf.definition,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp go to definition" })
        )
        vim.keymap.set(
          "n",
          "<space>lgt",
          vim.lsp.buf.type_definition,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp go to type definition" })
        )
        vim.keymap.set(
          "n",
          "<space>lgi",
          vim.lsp.buf.implementation,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp go to implementation" })
        )
        vim.keymap.set("n", "<space>rn", function()
            return ":IncRename " .. vim.fn.expand("<cword>")
          end,
          { expr = true }
        )

        vim.keymap.set(
          "n",
          "<space>lgr",
          vim.lsp.buf.references,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp go to references" })
        )
        vim.keymap.set("n", "<space>lf", function()
            vim.lsp.buf.format { async = true }
          end,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp format" })
        )
        vim.keymap.set(
          "n",
          "<space>ltd",
          toggle_diagnostics,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp toggle diagnostics" })
        )
        vim.keymap.set(
          "n",
          "<space>lth",
          toggle_inlay_hints,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp toggle inlay hints" })
        )
        vim.keymap.set(
          "n",
          "<space>la",
          vim.lsp.buf.code_action,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp code action" })
        )
        vim.keymap.set(
          "n",
          "<space>ls",
          vim.lsp.buf.signature_help,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp signature help" })
        )
        vim.keymap.set(
          "n",
          "<space>lwa",
          vim.lsp.buf.add_workspace_folder,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp add workspace folder" })
        )
        vim.keymap.set(
          "n",
          "<space>lwr",
          vim.lsp.buf.remove_workspace_folder,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp remove workspace folder" })
        )
        vim.keymap.set(
          "n",
          "<space>lwl",
          function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp list workspace folders" })
        )
        vim.keymap.set(
          "n",
          "<space>lr",
          vim.lsp.buf.rename,
          vim.tbl_extend("force", bufopts, { desc = "✨lsp rename symbol" })
        )
      end
    })
  end
})



require("dapui").setup()

require('ayu').setup({
  mirage = false, -- Set to `true` to use `mirage` variant instead of `dark` for dark background.
  overrides = {}, -- A dictionary of group names, each associated with a dictionary of parameters (`bg`, `fg`, `sp` and `style`) and colors in hex.
})
require('lualine').setup({
  options = {
    theme = 'ayu',
  },
})
require('ayu').colorscheme()
-- General settings
vim.opt.number = true         -- Enable line numbers
vim.opt.relativenumber = true -- Enable relative line numbers
vim.opt.tabstop = 2           -- 2 spaces for a tab
vim.opt.shiftwidth = 2        -- 2 spaces for autoindent
vim.opt.expandtab = true      -- Convert tabs to spaces
vim.opt.hlsearch = true       -- Highlight search matches
vim.opt.ignorecase = true     -- Case-insensitive searches
vim.opt.smartcase = true      -- Use case-sensitivity when search contains capitals


-- LSP Config
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-u>'] = cmp.mapping.scroll_docs(-4), -- Up
    ['<C-d>'] = cmp.mapping.scroll_docs(4),  -- Down
    -- C-b (back) C-f (forward) for snippet placeholder navigation.
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}

-- Setup nvim-tree
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- empty setup using defaults
require("nvim-tree").setup()

-- OR setup with some options
require("nvim-tree").setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
})

vim.opt.autoread = true
vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.dir=os.getenv("HOME") .. "/.vim_local/swapfiles"
vim.opt.guifont = "Hack:h8"
vim.opt.hidden = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.list = true
vim.opt.listchars = { leadmultispace = "◦···", tab = "⇥ " }
vim.opt.modeline = true
vim.opt.scroll=10
vim.opt.shiftwidth=2
vim.opt.softtabstop=2
vim.opt.switchbuf = "useopen,usetab"
vim.opt.tabstop=8 -- Conventional, see :help 30.5
vim.opt.updatetime = 100
vim.opt.undodir = os.getenv("HOME") .. "/.vim_local/undodir/"
vim.opt.undofile = true
vim.opt.viewdir=os.getenv("HOME") .. "/.vim_local/views/"
vim.opt.mouse = ''
vim.opt.relativenumber = true
vim.opt.expandtab = true

vim.g.mapleader = " " -- Make sure to set `mapleader` before lazy so your mappings are correct
vim.g.maplocalleader = "\\" -- Same for `maplocalleader`

-- lazy.nvim installation:
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
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

require("lazy").setup('plugins')

vim.opt.termguicolors = true

-- Spelling highlight
vim.api.nvim_set_hl(0, "SpellBad", {ctermfg=4})

-- CursorLine/CursorColumn configuration:
--
-- vim.api.nvim_set_hl(0, "CursorLine" {term=bold, ctermbg=black, cterm=none})
-- vim.api.nvim_set_hl(0, "CursorColumn" term=bold, ctermbg=black, cterm=none})
vim.api.nvim_set_hl(0, "CursorLine", {term=none, ctermbg=233, cterm=bold})
vim.api.nvim_set_hl(0, "CursorColumn", {term=none, ctermbg=233, cterm=none})

--------------------------------------------------------------------------------
-- Configuring neovim's behaviours
--------------------------------------------------------------------------------

-- Remember view upon enter/leave. In particular folds.
-- http://vim.wikia.com/wiki/VimTip991 + http://stackoverflow.com/a/1549318
vim.api.nvim_create_autocmd({"BufWinLeave"},{
  pattern="*",
  callback = function()
    vim.cmd[[silent! mkview]]
  end,
})

vim.api.nvim_create_autocmd({"BufWinEnter"},{
  pattern="*",
  callback = function()
    vim.cmd[[silent! loadview]]
  end,
})

-- Sign column colours:
vim.api.nvim_create_autocmd({"ColorScheme", "VimEnter"},{
  pattern="*",
  callback = function()
    vim.api.nvim_set_hl(0, "SignColumn", { ctermbg=234, bg="#444444" })   
  end,
})

-- Highlight bad use of whitespace:
vim.api.nvim_set_hl(0, "SpecialKey", {ctermbg=red})
vim.api.nvim_set_hl(0, "BadWhitespace", {ctermbg=red})
vim.cmd [[match BadWhitespace /\s\+\%#\@<!$/]]



-- highlight words after a while:
-- https://vi.stackexchange.com/a/25687:
vim.api.nvim_set_hl(0, "HighlightedWord", {cterm=undercurl, ctermfg=211})
vim.api.nvim_create_augroup("highlight_current_word", { })

-- Highlight words after a while
-- Doesn't seem to work, post-conversion to lua, leaving be
--[[
vim.api.nvim_create_autocmd("CursorHold",{
  pattern="*",
  callback = function()
    vim.cmd ":silent! :exec 'match HighlightedWord /\V\<' . expand('<cword>') . '\>/'"
  end
})
--]]

--------------------------------------------------------------------------------
-- Dvorak re-binds
--------------------------------------------------------------------------------

-- The following mappings get in the way of search hit traversal, so this:
vim.keymap.set('n', '<S-m>', '<S-n>')
vim.keymap.set('n', 'm', 'n')

vim.keymap.set('n', 'h', 'h')
vim.keymap.set('n', 't', 'j')
vim.keymap.set('n', 'n', 'k')
vim.keymap.set('n', 's', 'l')

--------------------------------------------------------------------------------
-- Configuration of netrw
--------------------------------------------------------------------------------

vim.cmd [[
" netrw config:
" buggy tree list style surrounding symlinks:
" https://github.com/vim/vim/issues/2386


let g:netrw_liststyle = 3
let g:netrw_keepdir = 0
" See https://vi.stackexchange.com/a/4563
" (Possibly overconfigured; but leaving it in, as a Dvorak user may need to
" revisit re-mapping features.)
function! s:ConfigureNetrw()
  let prior = maparg("t", "n")
  hi Normal ctermbg=none
  if prior != "j"
    nnoremap <buffer> t j
  endif
endfunction

augroup netrw_configuration
  autocmd!
  autocmd FileType netrw call s:ConfigureNetrw()
augroup end

]]

-- It's a bit of a TODO to get this working as
-- nvim_create_augroup/nvim_create_autocmd:
--
-- The current trouble seems to be that pattern='netrw' doesn't get triggered...?
-- vim.api.nvim_create_autocmd({"FileType"},{
--   pattern="*",
--   callback = function(ev)
--     print(string.format('event fired: %s', vim.inspect(ev)))
--   end
--   -- pattern="netrw",
--   -- callback = function()
--   --   vim.keymap.set('n', 'h', 'h')
--   --   vim.keymap.set('n', 't', 'j')
--   --   vim.keymap.set('n', 'n', 'k')
--   --   vim.keymap.set('n', 's', 'l')
--   -- end,
-- })

-- https://vi.stackexchange.com/a/15419:
vim.api.nvim_create_augroup("FiletypeSpecificMappings", {
})

vim.api.nvim_create_autocmd({"FileType"},{
  pattern="gitcommit",
  group="FiletypeSpecificMappings",
  callback = function(ev)
    vim.opt_local.spell = true
  end
})

vim.api.nvim_create_autocmd({"FileType"},{
  pattern="markdown",
  group="FiletypeSpecificMappings",
  callback = function(ev)
    vim.opt_local.spell = true
  end
})

vim.api.nvim_create_autocmd({"FileType"},{
  pattern="go",
  group="FiletypeSpecificMappings",
  callback = function(ev)
    vim.opt.shiftwidth=4
    vim.opt.tabstop=4
  end
  -- pattern="netrw",
  -- callback = function()
  --   vim.keymap.set('n', 'h', 'h')
  --   vim.keymap.set('n', 't', 'j')
  --   vim.keymap.set('n', 'n', 'k')
  --   vim.keymap.set('n', 's', 'l')
  -- end,
})

vim.api.nvim_create_augroup("AutoTest", {})

vim.api.nvim_create_autocmd(
  "BufWritePost",
  {
    pattern = "*.go",
    group = "AutoTest",
    callback = function()
      require("neotest").run.run(vim.fn.expand("%"))
    end,
  }
)

local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
   require('go.format').goimports()
  end,
  group = format_sync_grp,
})




--------------------------------------------------------------------------------
-- Generic keymap configuration
--------------------------------------------------------------------------------

-- Using the arrow keys to move between windows seems like a reasonable choice
vim.keymap.set('n', '<Up>', '<c-w>k')
vim.keymap.set('n', '<Down>', '<c-w>j')
vim.keymap.set('n', '<Left>', '<c-w>h')
vim.keymap.set('n', '<Right>', '<c-w>l')
-- <Leader>c to close windows:
vim.keymap.set('n', '<Leader>c', '<cmd>q<Enter>', { noremap = true })
-- <Leader>w to save everything
vim.keymap.set('n', '<Leader>w', '<cmd>wa<Enter>')

-- Adding a LatexTableReformat command
vim.cmd [[command LatexTableReformat normal! <s-v>?begin.tabularx<cr><down>o/end.tabularx<cr><up>:'<,'>.!sed -r 's/\s*(\\\\|&)\s*/|\1 /g' | column -ts'|' | sort<cr> ]]


--------------------------------------------------------------------------------
-- Plugin configuration
--------------------------------------------------------------------------------

require("focus").setup()

require("telescope").setup{
  defaults = {
    file_ignore_patterns = {
      ".git/",
    }
  }
}

require("telescope").load_extension("frecency")

vim.keymap.set('n', '<Leader>H', '<cmd>Telescope frecency<Enter>', { noremap = true })
vim.keymap.set('n', '<Leader>f', '<cmd>Telescope find_files hidden=true<Enter>', { noremap = true })
vim.keymap.set('n', '<Leader>b', '<cmd>Telescope buffers<Enter>', { noremap = true })
vim.keymap.set('n', '<Leader>r', '<cmd>Telescope live_grep<Enter>', { noremap = true })

require("hardtime").setup(
{
  restricted_keys = {
    ["h"] = { "n", "x" },
    ["t"] = { "n", "x" },
    ["n"] = { "n", "x" },
    ["s"] = { "n", "x" },
    ["-"] = { "n", "x" },
    ["+"] = { "n", "x" },
    ["gj"] = { "n", "x" },
    ["gk"] = { "n", "x" },
    ["<CR>"] = { "n", "x" },
    ["<C-M>"] = { "n", "x" },
    ["<C-N>"] = { "n", "x" },
    ["<C-P>"] = { "n", "x" },
 },
 disabled_keys = {
   ["<Up>"] = {},
   ["<Down>"] = {},
   ["<Left>"] = {},
   ["<Right>"] = {},
  }
})

require('lualine').setup{
  options = {
    theme = 'material-stealth'
  }
}

require('ibl').setup()

local cmp = require'cmp'

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
    end,
  },
  mapping = {
    ['<C-s>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif vim.fn["vsnip#available"](1) == 1 then
        feedkey("<Plug>(vsnip-expand-or-jump)", "")
      elseif has_words_before() then
        cmp.complete()
      else
        fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function()
      if cmp.visible() then
        cmp.select_prev_item()
      elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        feedkey("<Plug>(vsnip-jump-prev)", "")
      end
    end, { "i", "s" }),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'vsnip' }, -- For vsnip users.
    { name = 'gitmoji' },
  }, {
    { name = 'buffer' },
  })
})


local capabilities = require('cmp_nvim_lsp').default_capabilities() --nvim-cmp

local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
end

-- Setup lspconfig.
local nvim_lsp = require('lspconfig')

-- setup languages 
-- GoLang
nvim_lsp['gopls'].setup{
  cmd = {'gopls'},
  -- on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    gopls = {
      experimentalPostfixCompletions = true,
      analyses = {
        unusedparams = true,
        shadow = true,
      },
      staticcheck = true,
    },
  },
  init_options = {
    usePlaceholders = true,
  }
}

require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the listed parsers MUST always be installed)
  ensure_installed = { "go", "lua", "vim", "markdown", "markdown_inline" },
  sync_install = false,
  auto_install = true,
}

-- Neotest setup:
require("neotest").setup({
  adapters = {
    require("neotest-golang")({ -- Specify configuration
      go_test_args = {
        "-v",
        "-race",
        "-count=1",
        "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
      },
    }), -- Registration
  },
})

require('leap').opts.safe_labels = {}
vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
vim.keymap.set('n', '<Leader>s', function ()
  require('leap').leap {
    target_windows = require('leap.user').get_focusable_windows()
  }
end)

require('material').setup({
    plugins = { -- Uncomment the plugins that you use to highlight them
        -- Available plugins:
        -- "coc",
        -- "colorful-winsep",
        -- "dap",
        -- "dashboard",
        -- "eyeliner",
        -- "fidget",
        -- "flash",
        -- "gitsigns",
        -- "harpoon",
        -- "hop",
        -- "illuminate",
        "indent-blankline",
        -- "lspsaga",
        -- "mini",
        -- "neogit",
        "neotest",
        -- "neo-tree",
        -- "neorg",
        -- "noice",
        "nvim-cmp",
        -- "nvim-navic",
        -- "nvim-tree",
        "nvim-web-devicons",
        -- "rainbow-delimiters",
        -- "sneak",
        "telescope",
        -- "trouble",
        -- "which-key",
        -- "nvim-notify",
    },
    lualine_style = "stealth", -- Lualine style ( can be 'stealth' or 'default' )
    async_loading = true, -- Load parts of the theme asynchronously for faster startup (turned on by default)
})

vim.g.material_style = "darker"
vim.cmd[[colorscheme material]]

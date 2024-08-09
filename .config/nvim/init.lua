
vim.cmd.colorscheme("skrewzscheme")

vim.opt.autoread = true
vim.opt.cursorline = true
vim.opt.cursorcolumn = true
vim.opt.dir=os.getenv("HOME") .. "/.vim_local/swapfiles"
vim.opt.guifont = "Hack:h18"
vim.opt.hidden = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.list = true
vim.opt.listchars = "tab:  ,trail: ,extends:·"
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

require("telescope").load_extension("frecency")

vim.keymap.set('n', '<Leader>H', '<cmd>Telescope frecency<Enter>', { noremap = true })
vim.keymap.set('n', '<Leader>f', '<cmd>Telescope find_files<Enter>', { noremap = true })
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
    theme = 'gruvbox'
  }
}

require('ibl').setup()

require('leap')
vim.api.nvim_set_hl(0, 'LeapBackdrop', { link = 'Comment' })
vim.keymap.set('n', '<Leader>s', function ()
  require('leap').leap {
    target_windows = require('leap.user').get_focusable_windows()
  }
end)


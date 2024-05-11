colorscheme skrewzscheme
syntax on
set nocompatible
set foldmethod=syntax
set foldminlines=10
" Extra space when scrolling:
set so=10
" Reduced for more immediate updates in e.g. airblade/vim-gitgutter:
set updatetime=100
set switchbuf=useopen,usetab

set guifont=Hack:h8

set hlsearch
set incsearch

let mapleader = " "

set cursorline cursorcolumn
"highlight CursorLine   term=bold ctermbg=black cterm=none
"highlight CursorColumn term=bold ctermbg=black cterm=none
highlight CursorLine   term=none ctermbg=233 cterm=bold
highlight CursorColumn term=none ctermbg=233 cterm=none
highlight SpellBad ctermfg=4
" Autoread is tremendously useful for long-running vim sessions on VCS'ed data
set autoread

" http://vim.wikia.com/wiki/Configuring_the_cursor
if &term =~ "xterm\\|rxvt"
  " use a red cursor in insert mode
  let &t_SI = "\<Esc>]12;white\x7"
  " use a red cursor otherwise
  let &t_EI = "\<Esc>]12;grey\x7"
  silent !echo -ne "\033]12;grey\007"
  " reset cursor when vim exits
  autocmd VimLeave * silent !echo -ne "\033]112\007"
  " use \003]12;gray\007 for gnome-terminal and rxvt up to version 9.21
endif

autocmd VimEnter,Colorscheme * highlight SignColumn ctermbg=234 guibg=#444444



" listchars-highlight Bad Spacing (but in a whitespace-preserving way:)
set listchars=tab:\ \ ,trail:\ ,extends:·
highlight SpecialKey ctermbg=red

highlight BadWhitespace ctermbg=red
match BadWhitespace /\s\+\%#\@<!$/

" skrewz@20150118: Not needed, turns ``bottom overflow'' $colour.
" highlight NonText    ctermbg=green

" highlight words after a while:
" https://vi.stackexchange.com/a/25687:
highlight HighlightedWord cterm=undercurl ctermfg=211
augroup highlight_current_word
  au!
  au CursorHold * :silent! :exec 'match HighlightedWord /\V\<' . expand('<cword>') . '\>/'
augroup END

set list
set modeline
set relativenumber
set hidden
set scroll=10
set shiftwidth=2
set softtabstop=2
set tabstop=8 " Conventional, see :help 30.5

" Daring, could be useful?
" autocmd BufRead,BufWritePre *.sh normal gg=G

set expandtab " Nobody likes tab characters.

" Configuration of temporary/synced vim dirs:
" TODO: use this approach: https://vi.stackexchange.com/a/53
silent !mkdir -p ~/.vim_synced/spell > /dev/null 2>&1
silent !mkdir -p ~/.vim_local/swapfiles ~/.vim_local/tagfiles ~/.vim_local/undodir ~/.vim_local/views > /dev/null 2>&1
set dir=~/.vim_local/swapfiles

" Remember view upon enter/leave. In particular folds.
" http://vim.wikia.com/wiki/VimTip991 + http://stackoverflow.com/a/1549318
set viewdir=~/.vim_local/views/
autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* silent! loadview

if has('persistent_undo')
    set undodir=~/.vim_local/undodir/
    set undofile
endif

"au FileType python python
"    \ set tabstop=4
"    \ set softtabstop=4
"    \ set shiftwidth=4
"    \ set textwidth=79
"    \ set expandtab
"    \ set autoindent
"    \ set fileformat=unix

"autocmd FileType python setlocal colorcolumn=79

" Set up ColorColumn when typing email:
autocmd FileType mail setlocal colorcolumn=85
highlight ColorColumn ctermbg=52

" Enable spellchecking by default in certain files:
autocmd FileType gitcommit setlocal spell
autocmd FileType markdown setlocal spell

" python3 configuration: {{{
" https://github.com/tweekmonster/nvim-python-doctor/wiki/Advanced:-Using-pyenv suggests:
" (made with `cd ~/.config/nvim; python3 -m venv py3venv; source $HOME/.config/nvim/py3venv/bin/activate; pip3 install neovim`).
let g:python3_host_prog = $HOME . '/.config/nvim/py3venv/bin/python3'
" }}}

" Setting up Vim-plug: {{{
filetype off
call plug#begin('~/.vim_local/vim-plugged')

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Plug 'chriskempson/tomorrow-theme'
" Plug 'scrooloose/nerdtree'
Plug 'easymotion/vim-easymotion'
Plug 'nathanaelkane/vim-indent-guides'
" Plug 'Valloric/YouCompleteMe'
Plug 'tomlion/vim-solidity'
Plug 'rodjek/vim-puppet'
Plug 'neovim/nvim-lspconfig'
Plug 'chrisbra/unicode.vim'
" Plug 'vim-syntastic/syntastic'
" Plug 'dense-analysis/ale'
" Plug 'tpope/vim-git'
" Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'airblade/vim-rooter'
Plug 'tpope/vim-vinegar'
Plug 'tpope/vim-commentary'
Plug 'leafgarland/typescript-vim'
Plug 'pangloss/vim-javascript'
Plug 'rhysd/vim-grammarous'
Plug 'gerrard00/vim-mocha-only', { 'for': ['javascript'] }
Plug 'mbbill/undotree'
Plug 'm4xshen/hardtime.nvim'
" https://github.com/Shougo/deoplete.nvim#install
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'deoplete-plugins/deoplete-jedi'
Plug 'deoplete-plugins/deoplete-dictionary'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'beauwilliams/focus.nvim'
" not relevant on nvim:
"Plug 'roxma/nvim-yarp'
"Plug 'roxma/vim-hug-neovim-rpc'
Plug 'ludovicchabant/vim-gutentags'
Plug 'salkin-mada/openscad.nvim'
Plug 'saltstack/salt-vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'kkharji/sqlite.lua'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.2' }
Plug 'cljoly/telescope-repo.nvim'
Plug 'nvim-telescope/telescope-frecency.nvim'
Plug 'lervag/vimtex'
Plug 'ray-x/go.nvim'
call plug#end()
" }}}

" Telescope configuration: {{{
noremap <Leader>H <cmd>Telescope frecency<Enter>
noremap <Leader>f <cmd>Telescope find_files<Enter>
noremap <Leader>b <cmd>Telescope buffers<Enter>
noremap <Leader>r <cmd>Telescope live_grep<Enter>
noremap <Leader>a :mark A<Enter>gg=G`A
" }}}
imap <S-Insert> <C-R>*
noremap <Leader>c :q<Enter>

" Grammarous configuration: {{{
let g:grammarous#use_vim_spelllang = 1
let g:grammarous#disabled_rules = {
            \ '*' : [],
            \ 'markdown' : ['WHITESPACE_RULE', 'EN_QUOTES', 'SENTENCE_WHITESPACE', 'UPPERCASE_SENTENCE_START'],
            \ }
" }}}

" Airline configuration: {{{
let g:airline_powerline_fonts = 1
let g:airline_theme = 'bubblegum'
" }}}

" focus setup {{{
"You must run setup() to begin using focus
lua require("focus").setup()
" }}}
"
" hardtime setup {{{
"You must run setup() to begin using hardtime
lua << HARDTIME
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
HARDTIME
" }}}

" telescope-frecency setup {{{
lua << FRECENCY
require("telescope").load_extension("frecency")
FRECENCY
" }}}

" Indent guides configuration: {{{
" :help indent_guides_auto_colors  for a start.

let g:indent_guides_auto_colors = 0
let g:indent_guides_enable_on_vim_startup=1

autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=#444444 ctermbg=234
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=#333333 ctermbg=235
" }}}

" Deoplete configuration: {{{
setlocal dictionary+=/usr/share/dict/british-english
" Remove this if you'd like to use fuzzy search
call deoplete#custom#source(
\ 'dictionary', 'matchers', ['matcher_head'])
" If dictionary is already sorted, no need to sort it again.
call deoplete#custom#source(
\ 'dictionary', 'sorters', [])
" Do not complete too short words
call deoplete#custom#source(
      \ 'dictionary', 'min_pattern_length', 4)

" (https://github.com/Shougo/deoplete.nvim#configuration)
let g:deoplete#enable_at_startup = 1

call deoplete#custom#option('sources', {
\ '_': ['ale'],
\})

" }}}



function! WrapInOpenScadBlock (blocktype)
  let lineno = line('.')
  let baseindent = indent(lineno)
  let indentspacing = repeat(" ",baseindent)
  let additionallineindent = repeat(" ",2)
  call setline(lineno,additionallineindent.getline("."))
  call append(lineno,indentspacing."}")
  call append(lineno-1,indentspacing."{")
  call append(lineno-1,indentspacing.a:blocktype)
endfunction

noremap <Leader>od :call WrapInOpenScadBlock('difference()')<Enter>
noremap <Leader>ou :call WrapInOpenScadBlock('union()')<Enter>
noremap <Leader>oi :call WrapInOpenScadBlock('intersection()')<Enter>

" Oddball; kinda want to put cursor into the paranthesis, here:
noremap <Leader>ot :call WrapInOpenScadBlock('translate([0,0,0])')<Enter>
noremap <Leader>or :call WrapInOpenScadBlock('rotate([0,0,0])')<Enter>


" vim-terraform configuration: {{{
let g:terraform_align=1
autocmd FileType terraform setlocal commentstring=#%s
" }}}

let g:rbpt_colorpairs = [
    \ ['brown',       'RoyalBlue3'],
    \ ['Darkblue',    'SeaGreen3'],
    \ ['darkgray',    'DarkOrchid3'],
    \ ['darkgreen',   'firebrick3'],
    \ ['darkcyan',    'RoyalBlue3'],
    \ ['darkred',     'SeaGreen3'],
    \ ['brown',       'firebrick3'],
    \ ['red' ,        'RoyalBlue3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['Darkblue',    'firebrick3'],
    \ ['darkgreen',   'RoyalBlue3'],
    \ ['darkcyan',    'SeaGreen3'],
    \ ['gray',        'firebrick3'],
    \ ]

" }}}

" Easymotion configuration: {{{
" See :h easymotion.txt
let g:EasyMotion_smartcase = 1

" }}}

" vim-gutentags configuration: {{{
let g:gutentags_cache_dir = '~/.vim_local/tagfiles'
" }}}



" spelling settings
setglobal spelllang=en
" setglobal nospell
let g:tex_comment_nospell= 1

execute "set spellfile=~/.vim_synced/spell/wordlist.".&g:spelllang.".utf-8.add"
" set spellfile=~/.vim_synced/spell/wordlist.en.utf-8.add




" Test if this is a host where Dvorak-style keybinds shouldn't be enacted.
" This is controlled through a file in .vim, in my case. Inspiration in
" http://stackoverflow.com/a/3098685
if ! filereadable($HOME . "/.vim/dont_do_dvorak_binds")
  " The following mappings get in the way of search hit traversal, so this:
  noremap <S-m> <S-n>
  noremap m n

  noremap h h
  noremap t j
  noremap n k
  noremap s l

  " Using the arrow keys to move between windows seems like a reasonable choice
  map <Up> <c-w>k
  map <Down> <c-w>j
  map <Left> <c-w>h
  map <Right> <c-w>l
endif

if filereadable($HOME . "/.vim/abbreviations.vim")
  source $HOME . "/.vim/abbreviations.vim"
endif

if filereadable($HOME . "/.vim/localtweaks.vim")
  exec "source " . $HOME . "/.vim/localtweaks.vim"
endif


noremap <Leader>u :UndotreeToggle<Enter>
" Consider: https://www.reddit.com/r/vim/comments/21f4gm/best_workflow_when_using_fugitive/
noremap <Leader>gc :Gcommit -v<Enter>
noremap <Leader>gs :Gstatus<Enter>
noremap <Leader>gd :Gvdiff<Enter>

noremap <Leader>gd :Gvdiff<Enter>

noremap <Leader>mo :MochaOnlyToggle<Enter>

nmap <Leader>w :wa<Enter>:w<Enter>

nmap <Leader>s <Plug>(easymotion-overwin-f2)
"xmap <Leader>s <Plug>(easymotion-owerwin-f2)
"omap <Leader>s <Plug>(easymotion-owerwin-f2)
nmap <Leader>t <Plug>(easymotion-sn)
xmap <Leader>t <Plug>(easymotion-sn)
omap <Leader>t <Plug>(easymotion-sn)

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

map <f1> vG$!~/bin/ol2sanity.pl<cr>

noremap <S-s> :call GetDate('')<CR>
function! GetDate(format)
  " Append space + result to current line without moving cursor.
  call setline(line('.'), getline('.') . ' ' . strftime('%Y-%m-%d %H:%M:%S'))
endfunction


" Make the gnupg plugin prefer armored and symmetrically encrypted files:

let g:GPGPreferSymmetric = 1
let g:GPGPreferArmor = 1

let g:syntastic_puppet_lint_disable = 1
let g:syntastic_puppet_validate_disable = 1

" syntastic configuration:

"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
" syntastic per-filetype checkers:
let g:syntastic_typescript_checkers = ['tslint']

let g:syntastic_lua_checkers = ['luacheck']
let g:syntastic_python_checkers = ['flake8']

" vim: fdm=marker fml=1

colorscheme skrewzscheme
syntax on
set nocompatible
set foldmethod=syntax
set foldminlines=10
" Extra space when scrolling:
set so=10
set switchbuf=useopen,usetab

set hlsearch
set incsearch

let mapleader = " "

set cursorline cursorcolumn
"highlight CursorLine   term=bold ctermbg=black cterm=none
"highlight CursorColumn term=bold ctermbg=black cterm=none
highlight CursorLine   term=none ctermbg=233 cterm=bold
highlight CursorColumn term=none ctermbg=233 cterm=none
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

autocmd VimEnter,Colorscheme * highlight SignColumn ctermbg=234



" listchars-highlight Bad Spacing (but in a whitespace-preserving way:)
set listchars=tab:\ \ ,trail:\ ,extends:·
highlight SpecialKey ctermbg=red

" skrewz@20150118: Not needed, turns ``bottom overflow'' $colour.
" highlight NonText    ctermbg=green

set list
set modeline
set number
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

" spelling in git commits:
autocmd FileType gitcommit setlocal spell

" python3 configuration: {{{
" https://github.com/tweekmonster/nvim-python-doctor/wiki/Advanced:-Using-pyenv suggests:
" (made with `cd ~/.config/nvim; virtualenv -p python3 py3venv; source $HOME/.config/nvim/py3venv/bin/activate; pip3 install neovim`).
let g:python3_host_prog = '/home/skrewz/.config/nvim/py3venv/bin/python3'
" }}}

" Setting up Vundle: {{{
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" Makes vundle handle itself:
Plugin 'vim-airline/vim-airline'
" Plugin 'chriskempson/tomorrow-theme'
Plugin 'VundleVim/Vundle.vim'
" Plugin 'scrooloose/nerdtree'
Plugin 'Lokaltog/vim-easymotion'
Plugin 'nathanaelkane/vim-indent-guides'
" Plugin 'Valloric/YouCompleteMe'
Plugin 'tomlion/vim-solidity'
Plugin 'hashivim/vim-terraform.git'
Plugin 'puppetlabs/puppet-syntax-vim'
Plugin 'vim-syntastic/syntastic'
Plugin 'tpope/vim-git'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-vinegar'
Plugin 'tpope/vim-commentary'
Plugin 'kien/rainbow_parentheses.vim'
Plugin 'leafgarland/typescript-vim'
Plugin 'pangloss/vim-javascript'
Plugin 'mbbill/undotree'
" https://github.com/Shougo/deoplete.nvim#install
Plugin 'Shougo/deoplete.nvim'
" not relevant on nvim:
"Plugin 'roxma/nvim-yarp'
"Plugin 'roxma/vim-hug-neovim-rpc'
Plugin 'ludovicchabant/vim-gutentags'
Plugin 'sirtaj/vim-openscad'
Plugin 'saltstack/salt-vim'
" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
"Plugin 'tpope/vim-fugitive'
" plugin from http://vim-scripts.org/vim/scripts.html
"Plugin 'L9'
" Git plugin not hosted on GitHub
"Plugin 'git://git.wincent.com/command-t.git'
" git repos on your local machine (i.e. when working on your own plugin)
"Plugin 'file:///home/gmarik/path/to/plugin'
" The sparkup vim script is in a subdirectory of this repo called vim.
" Pass the path to set the runtimepath properly.
"Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" Avoid a name conflict with L9
"Plugin 'user/L9', {'name': 'newL9'}

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList          - list configured plugins
" :PluginInstall(!)    - install (update) plugins
" :PluginSearch(!) foo - search (or refresh cache first) for foo
" :PluginClean(!)      - confirm (or auto-approve) removal of unused plugins
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" }}}

" Indent guides configuration: {{{
" :help indent_guides_auto_colors  for a start.

let g:indent_guides_auto_colors = 0
let g:indent_guides_enable_on_vim_startup=1

autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=black    ctermbg=234
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=darkgrey ctermbg=235

" }}}

" deoplete configuration: {{{
" (https://github.com/Shougo/deoplete.nvim#configuration)
let g:deoplete#enable_at_startup = 1

" }}}


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" MULTIPURPOSE TAB KEY
" Indent if we're at the beginning of a line. Else, do completion.
" Yanked off:
" https://github.com/garybernhardt/dotfiles/blob/99b7d2537ad98dd7a9d3c82b8775f0de1718b356/.vimrc#L166-L180.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<tab>"
    else
        return "\<c-p>"
    endif
endfunction
inoremap <expr> <tab> InsertTabWrapper()
inoremap <s-tab> <c-p><Paste>

" vim-terraform configuration: {{{
let g:terraform_align=1
autocmd FileType terraform setlocal commentstring=#%s
" }}}

" Rainbow Parentheses configuration: {{{

au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces

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
  noremap <S-k> <S-n>
  noremap k n

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

" Fuzzyfinder
" http://www.vim.org/scripts/script.php?script_id=1984
let g:fuf_modesDisable = []
" default; allows you to C-j or C-] one's way to 
let g:fuf_reuseWindow = 1
" Mind you: You can open a selected item in various ways:
"
" <CR>  - opens in a previous window.
" <C-j> - opens in a split window.
" <C-k> - opens in a vertical-split window.
" <C-]> - opens in a new tab page.

noremap <Leader>f :FufMruFileInCwd<Enter>
noremap <Leader>F :FufFile<Enter>
noremap <Leader>b :FufBuffer<Enter>
noremap <Leader>u :UndotreeToggle<Enter>
" Consider: https://www.reddit.com/r/vim/comments/21f4gm/best_workflow_when_using_fugitive/
noremap <Leader>gc :Gcommit -v<Enter>
noremap <Leader>gs :Gstatus<Enter>
noremap <Leader>gd :Gvdiff<Enter>

noremap <Leader>m <C-W>\|<C-W>_

nmap <Leader>s <Plug>(easymotion-sn)
xmap <Leader>s <Plug>(easymotion-sn)
omap <Leader>s <Plug>(easymotion-sn)

" netrw config:
" buggy tree list style surrounding symlinks:
" https://github.com/vim/vim/issues/2386

let g:netrw_liststyle = 3
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

let g:syntastic_python_checkers = ['flake8']

" vim: fdm=marker fml=1

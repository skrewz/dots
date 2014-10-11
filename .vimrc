syntax on
colorscheme delek
syntax on
set nocompatible
set foldmethod=syntax
set foldminlines=10
" Extra space when scrolling:
set so=10

set hlsearch
set incsearch

set cursorline
hi CursorLine term=bold cterm=bold
" Autoread is tremendously useful for long-running vim sessions on VCS'ed data
set autoread

set listchars=tab:>~,trail:.,extends:>
set list
set modeline
set number
" set relativenumber
set scroll=10
set shiftwidth=4
set softtabstop=2
set sw=2
set tabstop=8 " Conventional, see :help 30.5

set expandtab " Nobody likes tab characters.

silent !mkdir -p ~/.vim_local > /dev/null 2>&1


" Remember view upon enter/leave. In particular folds.
" http://vim.wikia.com/wiki/VimTip991 + http://stackoverflow.com/a/1549318
silent !mkdir -p ~/.vim_local/views > /dev/null 2>&1
set viewdir=~/.vim_local/views/
autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* silent loadview

" Setting up Vundle: {{{
filetype off
set rtp+=~/.vim/bundle/Vundle.vim 
call vundle#begin()

" Makes vundle handle itself:
Plugin 'gmarik/Vundle.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'Lokaltog/vim-easymotion'
Plugin 'nathanaelkane/vim-indent-guides'
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

" Indent guides configuration:
" :help indent_guides_auto_colors  for a start.

let g:indent_guides_auto_colors = 0
let g:indent_guides_enable_on_vim_startup=1
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=black    ctermbg=234
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=darkgrey ctermbg=235


" Easymotion configuration
" See :h easymotion.txt
let g:EasyMotion_smartcase = 1
" \ may be the default, but now it's conjiggered too:
map \ <Plug>(easymotion-prefix)

" nmap s         <Plug>(easymotion-s2)
" xmap s         <Plug>(easymotion-s2)
" omap z         <Plug>(easymotion-s2)
nmap <Leader>s <Plug>(easymotion-sn)
xmap <Leader>s <Plug>(easymotion-sn)
omap <Leader>z <Plug>(easymotion-sn)

silent !mkdir -p ~/.vim_local/spell > /dev/null 2>&1
silent !mkdir -p ~/.vim_local/swapfiles > /dev/null 2>&1
set dir=~/.vim_local/swapfiles

" spelling settings
setglobal spelllang=en_uk
setglobal nospell 
let g:tex_comment_nospell= 1

execute "set spellfile=~/.vim_local/spell/wordlist.".&g:spelllang.".add"




" Test if this is a host where Dvorak-style keybinds shouldn't be enacted.
" This is controlled through a file in .vim, in my case. Inspiration in
" http://stackoverflow.com/a/3098685
if ! filereadable($HOME . "/.vim/dont_do_dvorak_binds")
  " The following mappings get in the way of search hit traversal, so this:
  noremap <S-k> <S-n>
  noremap k n

  noremap h h
  noremap t j
  noremap <S-t> 10j
  noremap n k
  noremap <S-n> 10k
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
" noremap <C-b> :FufBuffer<Enter>
" Mind you: You can open a selected item in various ways:
"
" <CR>  - opens in a previous window.
" <C-j> - opens in a split window.
" <C-k> - opens in a vertical-split window.
" <C-]> - opens in a new tab page.
noremap <C-f>f :FufMruFileInCwd<Enter>
noremap <C-f>F :FufFile<Enter>

map <f1> vG$!~/bin/ol2sanity.pl<cr>


" Make the gnupg plugin prefer armored and symmetrically encrypted files:

let g:GPGPreferSymmetric = 1
let g:GPGPreferArmor = 1

let g:syntastic_puppet_lint_disable = 1
let g:syntastic_puppet_validate_disable = 1

" vim: fdm=marker fml=1

syntax on
colorscheme delek
syntax on
filetype on
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

filetype plugin indent on

" The following mappings get in the way of search hit traversal, so this:
noremap <S-k> <S-n>
noremap k n

noremap h h
noremap t j
noremap <S-t> 10j
noremap n k
noremap <S-n> 10k
noremap s l

" Fuzzyfinder bindings: http://www.vim.org/scripts/script.php?script_id=1984
noremap <C-b> :FufBuffer<Enter>
noremap <C-f> :new<Enter>:FufFile<Enter>

" Using the arrow keys to move between windows seems like a reasonable choice
map <Up> <c-w>k
map <Down> <c-w>j
map <Left> <c-w>h
map <Right> <c-w>l

" Make the gnupg plugin prefer armored and symmetrically encrypted files:

let g:GPGPreferSymmetric = 1
let g:GPGPreferArmor = 1

" As Fabian would say: Work around:
let g:syntastic_puppet_lint_disable = 1
let g:syntastic_puppet_validate_disable = 1

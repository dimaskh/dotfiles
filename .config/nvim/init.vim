""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax on
set title
set number relativenumber
set expandtab tabstop=2 softtabstop=2 shiftwidth=2 shiftround
set hidden noswapfile nobackup
set incsearch smartcase nohlsearch
set noerrorbells
set nowrap
set scrolloff=8
set signcolumn=yes
set smartindent
set termguicolors
set undofile undodir=~/.vim/undodir undolevels=1000
set history=1000
set clipboard=unnamed

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin('~/.vim/plugged')
Plug 'morhetz/gruvbox'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'sonph/onehalf', { 'rtp': 'vim' }
Plug 'EdenEast/nightfox.nvim', { 'tag': 'v1.0.0' }
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'preservim/tagbar'
Plug 'tpope/vim-fugitive'
Plug 'preservim/nerdtree' |
            \ Plug 'Xuyuanp/nerdtree-git-plugin' |
            \ Plug 'ryanoasis/vim-devicons' |
            \ Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'terryma/vim-multiple-cursors'
Plug 'easymotion/vim-easymotion'
Plug 'sheerun/vim-polyglot'
Plug 'leafgarland/typescript-vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'airblade/vim-gitgutter'
call plug#end()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Themes
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tokyonight
let g:tokyonight_style = "night"
" Theme
" colorscheme gruvbox
" colorscheme dracula
" colorscheme onehalfdark
" colorscheme duskfox
colorscheme tokyonight

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Keymaps
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Map leader to whitespace
let mapleader = " "
" Source configuratio by space + enter
nnoremap <leader><CR> :so ~/.config/nvim/init.vim<CR>
" Paste and remember selection by space + p
vnoremap <leader>p "_dP
" Yank to a system clipboard by space + y
vnoremap <leader>y "+y
nnoremap <leader>y "+y
" Yank the whole file
nnoremap <leader>Y gg"+yG
" Move lines by J / K
nnoremap J :m .+1<CR>==
vnoremap J :m '>+1<CR>gv=gv
nnoremap K :m .-2<CR>==
vnoremap K :m '<-2<CR>gv=gv
" Don't use arrow keys
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>
" Saving quicker
nnoremap <leader>s :w<CR>
" Quit
nnoremap <leader>q :q!<CR>
nnoremap <leader>w :wq<CR>
" Better escape
imap fj <esc>
imap jf <esc>
" Map colon to semicolon
nnoremap ; :

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Airline 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:airline_powerline_fonts = 1
let g:airline_theme='dracula'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" NERDTree
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <F2> :NERDTreeToggle<CR>
map <F3> :NERDTreeFind<CR>
" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Tagbar
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap <F8> :TagbarToggle<CR>

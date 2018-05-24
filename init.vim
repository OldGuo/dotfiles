set shell=/bin/bash

call plug#begin('~/.vim/plugged')

" Basic
Plug 'altercation/vim-colors-solarized'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'yggdroot/indentline'
Plug 'majutsushi/tagbar'
Plug 'christoomey/vim-tmux-navigator'
Plug 'mileszs/ack.vim'
Plug 'valloric/youcompleteme'
Plug 'alvan/vim-closetag'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-surround'
Plug 'christoomey/vim-system-copy'

" Syntax
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'leafgarland/typescript-vim'
Plug 'ianks/vim-tsx'
Plug 'jparise/vim-graphql'
Plug 'elzr/vim-json'
Plug 'davidhalter/jedi-vim'
Plug 'octol/vim-cpp-enhanced-highlight'
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rails'

" Formatting
Plug 'w0rp/ale'
Plug 'prettier/vim-prettier'

call plug#end()

filetype plugin on
filetype plugin indent on

" General
set encoding=utf8
set number
syntax enable
set expandtab
set ts=2 sw=2 sts=2
set showcmd
set wildmenu
set showmatch
set incsearch
set hlsearch
nnoremap j gj
nnoremap k gk
set background=light
colorscheme solarized
set pastetoggle=<F3>
set mouse=a
set backspace=2
set nofixendofline
set ignorecase
set smartcase
set lazyredraw
set shellpipe=>
" au FileType qf wincmd J

" Cursor Style
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" Split Movement
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Tab Navigation
nnoremap <C-t>     :tabnew<CR>
inoremap <C-t>     <Esc>:tabnew<CR>

" Command to move among tabs in Konsole-style
map <A-l> gt
map <A-h> gT
nnoremap <S-l>  :tabnext<CR>
nnoremap <S-h>  :tabprev<CR>
nnoremap <S-t>  :tabnew<CR>

" NERDTree
map <silent> <C-n> :NERDTreeToggle<CR> :NERDTreeMirror<CR>
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1

" Tags
nmap <F8> :TagbarToggle<CR>

" Airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'
let g:airline_powerline_fonts = 1
let g:airline_theme='solarized'
set laststatus=2

" lightline
let g:lightline = {
      \ 'colorscheme': 'solarized',
      \ }


" YCM
let g:ycm_collect_identifiers_from_tags_files = 1 " Let YCM read tags from Ctags file
let g:ycm_use_ultisnips_completer = 1 " Default 1, just ensure
let g:ycm_seed_identifiers_with_syntax = 1 " Completion for programming language's keyword
let g:ycm_complete_in_comments = 1 " Completion in comments
let g:ycm_complete_in_strings = 1 " Completion in string
let g:ycm_global_ycm_extra_conf = '~/.ycm_extra_conf.py'

" CloseTag
let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.jsx,*.js,*.tsx,*.py'
let g:closetag_xhtml_filenames = '*.xhtml,*.jsx'
let g:closetag_emptyTags_caseSensitive = 1
let g:closetag_shortcut = '>'
let g:closetag_close_shortcut = '<leader>>'

" JSX
let g:jsx_ext_required = 0

" JSON
let g:vim_json_syntax_conceal = 0

" TypeScript
autocmd QuickFixCmdPost [^l]* nested cwindow
autocmd QuickFixCmdPost    l* nested lwindow

" IndentLines
let g:indentLine_enabled = 1

" Ack
cnoreabbrev Ack Ack!
nnoremap <Leader>a :Ack!<Space>
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" fzf
set rtp+=/usr/local/opt/fzf
nmap ; :FZF<CR>
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }
nnoremap <C-i>  :Line<CR>

" Ale
let g:ale_sign_error = '!'
let g:ale_sign_warning = '?'

" jedi
let g:jedi#force_py_version = 3

autocmd Filetype c setlocal ts=2 sw=2 expandtab

" Quickfix window size
au FileType qf wincmd J

set shell=/bin/bash

call plug#begin('~/.vim/plugged')

" Basic
Plug 'altercation/vim-colors-solarized'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/nerdcommenter'
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
" Plug 'jiangmiao/auto-pairs'
" Plug 'Townk/vim-autoclose'
Plug 'Raimondi/delimitMate'
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
Plug 'vim-ruby/vim-ruby'
Plug 'tpope/vim-rbenv'
Plug 'chrisbra/Colorizer'
" Plug 'flowtype/vim-flow'
Plug 'kchmck/vim-coffee-script'
Plug 'fatih/vim-go'

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
set timeoutlen=1000 ttimeoutlen=0
set title
" au FileType qf wincmd J

" Cursor Style
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif

" Highlight
nnoremap <Leader><Esc> :noh<Cr>
" highlight last inserted text
nnoremap gV `[v`]

" Split Management
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <Leader>s :new<CR>
nnoremap <Leader>v :vnew<CR>
set splitright
set splitbelow
autocmd VimResized * wincmd =

" Command to move among tabs in Konsole-style
map <A-l> gt
map <A-h> g
nnoremap <S-l>  :tabnext<CR>
nnoremap <S-h>  :tabprev<CR>
nnoremap <S-t>  :tabnew<CR>

" NERDTree
map <silent> <C-n> :NERDTreeToggle<CR> :NERDTreeMirror<CR>
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1
let NERDTreeMapOpenInTab='<C-t>'
nnoremap <leader>f :NERDTreeFind<CR>

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
nnoremap <Leader>a :Ack! -i<Space>
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" fzf
let $FZF_DEFAULT_COMMAND = 'ag -g ""'
set rtp+=/usr/local/opt/fzf
nmap <C-p> :FZF<CR>
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
let g:fzf_action = {
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit',
  \ 'ctrl-t': 'tabnew'
  \ }
nnoremap <Leader>l  :BLines<CR>
nnoremap <Leader>b  :Buffers<CR>
nnoremap <Leader>% :let @*=@%<CR>

" Ale
let g:ale_sign_error = '!'
let g:ale_sign_warning = '?'
let g:ale_ruby_rubocop_executable = 'bundle'
let g:ale_linters = {
\  'javascript': ['flow', 'eslint'],
\}
let g:ale_fixers = {
\   'javascript': ['eslint', 'prettier'],
\}
" if you want to fix files automatically on save.
" This is off by default.
let g:ale_fix_on_save = 1
let g:ale_set_quickfix = 0

" Flow
let g:flow#typecheck = 1
let g:flow#autoclose = 1
let g:flow#showquickfix = 0

" jedi
let g:jedi#force_py_version = 3

autocmd Filetype c setlocal ts=2 sw=2 expandtab

" Quickfix window size
au FileType qf wincmd J
autocmd FileType qf setlocal wrap

set clipboard+=unnamedplus

" AutoClose
let g:AutoClosePumvisible = {"ENTER": "", "ESC": ""}

" DelimitMate
let g:closetag_filenames = "*.xml,*.html,*.xhtml,*.phtml,*.php"
au FileType xml,html,phtml,php,xhtml,js let b:delimitMate_matchpairs = "(:),[:],{:}"

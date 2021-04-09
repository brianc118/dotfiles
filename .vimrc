source $LOCAL_ADMIN_SCRIPTS/master.vimrc

call plug#begin('~/.vim/plugged')

"Plug 'preservim/nerdtree'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-dispatch'
Plug 'justinmk/vim-dirvish'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'majutsushi/tagbar'
Plug 'rust-lang/rust.vim'
Plug 'dense-analysis/ale'

"if has('nvim')
"  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"else
"  Plug 'Shougo/deoplete.nvim'
"  Plug 'roxma/nvim-yarp'
"  Plug 'roxma/vim-hug-neovim-rpc'
"endif

"if has('nvim') || has('patch-8.0.902')
"  Plug 'mhinz/vim-signify'
"else
"  Plug 'mhinz/vim-signify', { 'branch': 'legacy' }
"endif

"Themes
Plug 'itchyny/lightline.vim'
Plug 'patstockwell/vim-monokai-tasty'
Plug 'elzr/vim-json'

call plug#end()

"Handles filetype detection
if has("autocmd")
  filetype on
  filetype indent on
  filetype plugin on
endif

"""-------------------------------------------"""
"""          BUILT IN FUNCTIONALITY           """
"""-------------------------------------------"""
set number                "Line numbers"
set cursorline            "Highlight current line"
set showmode
set noerrorbells
set ignorecase            "Ignores case in searches
set smartcase             "Case sensitive if search starts with uppercase
set incsearch             "Incremental search
set showmatch             "Highlight matching bracket
set shiftwidth=2          "Makes the >> width 2
set softtabstop=2         "Number of insert mode columns for a tab when tab is hit"
set expandtab             "Spaces instead of tabs
set backspace=indent,eol,start  "More powerful backspace
set wildmenu              "Popup filelist on tab completion
set wildignorecase        "Ignore case in cmd tab completion
set hlsearch              "Highlight search terms
set splitbelow            "Split new horizontal splits below
set splitright            "Split new vertical splits to the right
set laststatus=2          "For lightline in 1 buffer
set list                  "Show tabs
set hidden                "Set hidden so we don't get prompted to write when opening new file
set nolist

"We want C-q for tmux prefix"
noremap <C-q> <Nop>
nnoremap <C-w>+ 10<C-w>+
nnoremap <C-w>- 10<C-w>-
nnoremap <C-w>< 10<C-w><
nnoremap <C-w>> 10<C-w>>

"Themes
let g:vim_monokai_tasty_italic = 1
colorscheme vim-monokai-tasty
let g:lightline = {
      \ 'colorscheme': 'monokai_tasty',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ], [ 'readonly', 'cwd', 'absolutepath', 'modified' ] ],
      \ },
      \ 'tab_component_function': {
      \   'cwd': 'LightlineCurrentDirectory'
      \ },
      \ }
function! LightlineCurrentDirectory(n) abort
  return fnamemodify(getcwd(tabpagewinnr(a:n), a:n), ':t')
endfunction

set autoread

"Don't open FZF file in NERDTree buffer
function! FZFOpen(command_str)
  if (expand('%') =~# 'NERD_tree' && winnr('$') > 1)
    exe "normal! \<c-w>\<c-w>"
  endif
  exe 'normal! ' . a:command_str . "\<cr>"
endfunction

"FZF
nnoremap <silent> <C-b> :call FZFOpen(':Buffers')<CR>
nnoremap <silent> <C-g>g :call FZFOpen(':Ag')<CR>
nnoremap <silent> <C-g>c :call FZFOpen(':Commands')<CR>
nnoremap <silent> <C-g>L :call FZFOpen(':Lines')<CR>
nnoremap <silent> <C-g>l :call FZFOpen(':BLines')<CR>
nnoremap <silent> <C-p> :call FZFOpen(':Files')<CR>
nmap <C-P> :FZF<CR>
command! LightlineReload call LightlineReload()

function! LightlineReload()
  call lightline#init()
  call lightline#colorscheme()
  call lightline#update()
endfunction

"Ale
"let g:ale_rust_analyzer_config = {
"	\ 'rust': {
"		\ 'all_targets': 1,
"		\ 'build_on_save': 1,
"		\ 'clippy_preference': 'on'
"	\ }
"	\ }
let g:ale_rust_analyzer_executable = ''
let g:ale_python_pyls_executable = '/usr/local/bin/pyls-language-server'
let g:ale_fixers = {'python': ['black'], 'cpp': ['clang-format'], "rust": ['rustfmt']}
let g:ale_linters = {'python': ['flake8', 'pyls'], 'cpp': ['cppls_fbcode'], 'rust': ['analyzer'], 'thrift': ['fbthrift']}
let g:ale_fix_on_save = 1
"let g:ale_lint_on_text_changed = 1
let g:ale_set_balloons = 1
"Signify
"set updatetime=100

"Deoplete
"let g:deoplete#enable_at_startup = 1

nmap gd <Plug>(ale_go_to_definition)
nmap gy <Plug>(ale_go_to_type_definition)
nmap gr <Plug>(ale_find_references)

"""-------------------------------------------"""
"""                 Facebook                  """
"""-------------------------------------------"""

"format build files automatically
autocmd BufWritePost TARGETS silent! exec
  \ '!~/fbsource/tools/third-party/buildifier/run_buildifier.py -i %' | :e

"buck build/test
nnoremap <Leader>bb :Dispatch buck build $(buck query "owner('$(realpath %)')" \| head -1) \| cat<CR>
nnoremap <Leader>bt :Dispatch buck test $(buck query "owner('$(realpath %)')" \| head -1) \| cat<CR>

"bg
let repo_path = system('hg root')
let repo_initial = 'f'
if repo_path =~# 'configerator'
  let repo_initial = 'c'
elseif repo_path =~# 'www'
  let repo_initial = 't'
elseif repo_path =~# 'fbcode'
  let repo_initial = 'f'
endif

command! -bang -nargs=* Bg
      \ call fzf#vim#grep(
      \   repo_initial . 'bgs --color=on '.shellescape(<q-args>) .
      \ '| sed "s,^[^/]*/,,"' .
      \ '| sed "s#^#$(hg root)/#g"', 1,
      \   <bang>0 ? fzf#vim#with_preview('up:60%')
      \           : fzf#vim#with_preview('up:55%:hidden', '?'),
      \   <bang>0)
noremap gs :Bg <C-r><C-w><CR>



function! SourceIfExists(file)
  if filereadable(expand(a:file))
    exe 'source' a:file
  endif
endfunction

call SourceIfExists("$LOCAL_ADMIN_SCRIPTS/master.vimrc")

call plug#begin('~/.vim/plugged')

"Plug 'preservim/nerdtree'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tpope/vim-dispatch'
Plug 'justinmk/vim-dirvish'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
"Plug 'majutsushi/tagbar'
Plug 'rust-lang/rust.vim'
"Plug 'dense-analysis/ale'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}
Plug 'vivien/vim-linux-coding-style'

"Meta lsp
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/completion-nvim'
Plug 'nvim-treesitter/nvim-treesitter'
Plug '/usr/share/fb-editor-support/nvim'


"if has('nvim')
"  "Deoplete only for nvim
"  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
"else
"  "Keep this here since installations between neovim and vim are shared
"  Plug 'Shougo/deoplete.nvim'
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

"""-------------------------------------------"""
"""                   LUA                     """
"""-------------------------------------------"""

lua << EOF
require("meta.lsp")
local nvim_lsp = require("lspconfig")
local servers = { "rusty@meta", "pyls@meta", "pyre@meta", "thriftlsp@meta", "cppls@meta" }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
  }
end

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
vim.api.nvim_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
vim.api.nvim_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
vim.api.nvim_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
vim.api.nvim_set_keymap('n', '<space>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

EOF

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
set mouse=

"We want C-q for tmux prefix"
noremap <C-q> <Nop>
nnoremap <C-w>+ 10<C-w>+
nnoremap <C-w>- 10<C-w>-
nnoremap <C-w>< 10<C-w><
nnoremap <C-w>> 10<C-w>>

map <C-a> <ESC>^
imap <C-a> <ESC>I
map <C-e> <ESC>$
imap <C-e> <ESC>A
inoremap <M-f> <ESC><Space>Wi
inoremap <M-b> <Esc>Bi
inoremap <M-d> <ESC>cW


"Turn off vim recording
map q <Nop>


"""-------------------------------------------"""
"""                  VISUALS                  """
"""-------------------------------------------"""

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

"""-------------------------------------------"""
"""                NAVIGATION                 """
"""-------------------------------------------"""

"FZF
nnoremap <silent> <C-b> :Buffers<CR>
nnoremap <silent> <C-g>g :Ag<CR>
nnoremap <silent> <C-g>c :Commands<CR>
nnoremap <silent> <C-g>L :Lines<CR>
nnoremap <silent> <C-g>l :BLines<CR>
nnoremap <silent> <C-p> :Files<CR>
nmap <C-P> :FZF<CR>

"""-------------------------------------------"""
"""             LANGUAGE SUPPORT              """
"""-------------------------------------------"""

"let g:ale_rust_analyzer_config = {
"      \ 'diagnostics': { 'disabled': ['unresolved-import'] },
"      \ 'cargo': { 'loadOutDirsFromCheck': v:true },
"      \ 'procMacro': { 'enable': v:true },
"      \ 'checkOnSave': { 'command': 'clippy', 'enable': v:true }
"      \ }
"let g:ale_python_pyls_executable = '/usr/local/bin/pyls-language-server'
"let g:ale_fixers = {
"      \ 'python': ['black'],
"      \ 'cpp': ['clang-format'],
"      \ 'rust': ['rustfmt'],
"      \ 'bzl': [],
"      \ }
"let g:ale_cpp_cppls_fbcode_executable = '/home/brianc118/scripts/cppls'
"let g:ale_linters = {
"      \ 'cpp': ['cppls_fbcode'],
"      \ 'rust': ['analyzer'],
"      \ 'thrift': ['fbthrift'],
"      \ 'c': [],
"      \ }
"let g:ale_fix_on_save = 0
"Some lsps are slow. Only lint on save.
"let g:ale_lint_on_text_changed = 'never'
"let g:ale_lint_on_insert_leave = 0
"
"let g:ale_set_balloons = 1
"nmap gd <Plug>(ale_go_to_definition)
"nmap gy <Plug>(ale_go_to_type_definition)
"nmap gr <Plug>(ale_find_references)

if has('nvim')
  let g:deoplete#enable_at_startup = 1
  
  function! s:check_back_space() abort "{{{
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~ '\s'
  endfunction"}}}
  "tab completion
  inoremap <silent><expr> <TAB>
        \ pumvisible() ? "\<C-n>" :
        \ <SID>check_back_space() ? "\<TAB>" :
        \ deoplete#manual_complete()
endif

"Signify
"set updatetime=100

call SourceIfExists("~/.fbvimrc")

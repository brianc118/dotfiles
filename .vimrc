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
"Distraction-free writing
Plug 'junegunn/goyo.vim'
"Plug 'majutsushi/tagbar'
Plug 'rust-lang/rust.vim'
"Plug 'dense-analysis/ale'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}

if has('nvim')
  Plug 'nvim-lua/completion-nvim'
  "json lsp
  Plug 'tamago324/nlsp-settings.nvim'

  "trouble (lsp errors)
  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'folke/trouble.nvim'
  "magical highlighting
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope.nvim'
  Plug 'jose-elias-alvarez/null-ls.nvim'
  "completion
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/cmp-path'
  Plug 'hrsh7th/cmp-cmdline'
  Plug 'hrsh7th/nvim-cmp'
  Plug 'L3MON4D3/LuaSnip'
  Plug 'saadparwaiz1/cmp_luasnip'
  Plug 'neovim/nvim-lspconfig'
  "Meta lsp
  if hostname() =~ '.*facebook.*'
    Plug '/usr/share/fb-editor-support/nvim', {'as': 'meta.nvim'}
  endif
endif

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
"monokai with tree-sitter
Plug 'tanvirtin/monokai.nvim'

call plug#end()

"""-------------------------------------------"""
"""                   LUA                     """
"""-------------------------------------------"""

if has('nvim')

lua << EOF
-- osc52 clipboar
--vim.g.clipboard = {
--  name = 'osc52',
--  copy = {['+'] = copy, ['*'] = copy},
--  paste = {['+'] = 'tmux save-buffer -', ['*'] = 'tmux save-buffer -'}
--}
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
        ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
      },
      paste = {
        ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
        ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
      },
    }

local is_fb = string.match(vim.fn.hostname(), ".*facebook.*")
local is_amazon = string.match(vim.fn.hostname(), ".*amazon.*")

if is_fb then
  require('meta.hg').setup()
  require("meta.lsp")
end

-- Global mappings taken from
-- https://github.com/neovim/nvim-lspconfig/blob/4deb72306a59b1a36e571f9d86d6c5a05b20b294/README.md
-- Keep this updated as vim.lsp API is not stable.

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

function bemol()
 local bemol_dir = vim.fs.find({ '.bemol' }, { upward = true, type = 'directory'})[1]
 local ws_folders_lsp = {}
 if bemol_dir then
  local file = io.open(bemol_dir .. '/ws_root_folders', 'r')
  if file then

   for line in file:lines() do
    table.insert(ws_folders_lsp, line)
   end
   file:close()
  end
 end

 for _, line in ipairs(ws_folders_lsp) do
  vim.lsp.buf.add_workspace_folder(line)
 end
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)

  if is_amazon then
    bemol()
  end
end


local nvim_lsp = require("lspconfig")
local servers = {}
if is_fb then
  servers = { 
    "buckls@meta", 
    "cppls@meta", 
    "rust-analyzer@meta", 
    "thriftlsp@meta",
    "pyls@meta",
    "pyre@meta",
  }
elseif is_amazon then
  -- TODO: Barium for config
  servers = {
    "pyright"
  }
else
  servers = {
    "clangd",
    "pyright",
    "rust_analyzer",
  }
end

for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
    flags = {
      allow_incremental_sync = false,
      -- This will be the default in neovim 0.7+
      debounce_text_changes = 150,
    },
    print_meta_ls_statuses_to_messages = false,
  }
end

local null_ls = require("null-ls")
local null_ls_sources = {}
if is_fb then
  local meta = require("meta")
  null_ls_sources = {
    meta.null_ls.diagnostics.arclint,
    meta.null_ls.formatting.arclint,
  }
end

null_ls.setup({
  on_attach = function(client, bufnr)
        -- format on save
        -- if client.resolved_capabilities.document_formatting then
        --     vim.cmd([[
        --     augroup LspFormatting
        --         autocmd! * <buffer>
        --         autocmd BufWritePre <buffer> silent noa w | lua vim.lsp.buf.formatting_sync(nil, 30000)
        --     augroup END
        --     ]])
        -- end

        return on_attach(client, bufnr)
  end,
  sources = null_ls_sources,
  debug = true
})

vim.lsp.handlers['window/showMessage'] = function(_, result, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local lvl = ({
    'ERROR',
    'WARN',
    'INFO',
    'DEBUG',
  })[result.type]
end

vim.lsp.handlers['window/showStatus'] = function(_, result, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local lvl = ({
    'ERROR',
    'WARN',
    'INFO',
    'DEBUG',
  })[result.type]
end


--completion
vim.opt.completeopt = { "menu", "menuone", "noselect" }

      local luasnip = require("luasnip")
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = {
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.close(),
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
          }),
          ["<Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end,
          ["<S-Tab>"] = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end,
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
        },
      })


--tree-sitter
require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all"
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "cpp", "rust", "python" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  highlight = {
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}

require("trouble").setup {
  -- your configuration comes here
  -- or leave it empty to use the default settings
  -- refer to the configuration section below
}

if is_fb then
  require("meta.metamate").init({
          -- // change the keymap used for accepting completion. defaults to <C-l>
          -- completionKeymap='<C-m>', 
          
          -- // change the highlight group used for showing the completion. defaults to Delimiter
          virtualTextHighlightGroup='DiagnosticHint',
          
          -- // change the languages to target. defaults to php, python, rust
          filetypes = {"cpp", "rust", "python"} 
  })
end


EOF
endif

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
set matchpairs+=<:>       "Match other things with %
set nolist
set mouse=
"true color
set termguicolors
"Disable sign column (for git and lsp warning/errors) as it's disruptive when
"it shifts
set signcolumn=no

"We want C-q for tmux prefix"
noremap <C-q> <Nop>
nnoremap <C-w>+ 10<C-w>+
nnoremap <C-w>- 10<C-w>-
nnoremap <C-w>< 10<C-w><
nnoremap <C-w>> 10<C-w>>

map <C-a> <ESC>^
imap <C-a> <ESC>I
cmap <C-a> <C-b>
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
let g:vim_monokai_tasty_italic = 0
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
nnoremap <silent> <C-g>g :Rg<CR>
"search Rg with word under cursor
nnoremap <silent> <C-g>r :Rg <C-R><C-W><CR>
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

"if has('nvim')
"  let g:deoplete#enable_at_startup = 1
"  
"  function! s:check_back_space() abort "{{{
"    let col = col('.') - 1
"    return !col || getline('.')[col - 1]  =~ '\s'
"  endfunction"}}}
"  "tab completion
"  inoremap <silent><expr> <TAB>
"        \ pumvisible() ? "\<C-n>" :
"        \ <SID>check_back_space() ? "\<TAB>" :
"        \ deoplete#manual_complete()
"endif

"Signify
"set updatetime=100

"Trouble
nnoremap <silent> <C-g>t :TroubleToggle<CR>

call SourceIfExists("~/.fbvimrc")

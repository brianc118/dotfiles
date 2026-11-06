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
Plug 'tpope/vim-surround'
Plug 'justinmk/vim-dirvish'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
"Distraction-free writing
Plug 'junegunn/goyo.vim'
"Plug 'majutsushi/tagbar'
Plug 'rust-lang/rust.vim'
"Plug 'dense-analysis/ale'
Plug 'mg979/vim-visual-multi', {'branch': 'master'}
Plug 'tpope/vim-fugitive'

if has('nvim')
  Plug 'nvim-lua/completion-nvim'
  "json lsp
  Plug 'tamago324/nlsp-settings.nvim'

  "trouble (lsp errors)
  Plug 'nvim-tree/nvim-web-devicons'
  Plug 'folke/trouble.nvim'
  "magical highlighting
  if has('nvim-0.12')
    Plug 'nvim-treesitter/nvim-treesitter', {'branch': 'main', 'do': ':TSUpdate'}
  else
    Plug 'nvim-treesitter/nvim-treesitter', {'branch': 'master', 'do': ':TSUpdate'}
  endif
  Plug 'nvim-treesitter/nvim-treesitter-context'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope.nvim'
  " jose-elias-alvarez/null-ls.nvim was archived in 2023 and the repo has since
  " been deleted (GitHub answers 401, not 404, for repos that no longer exist),
  " so :PlugInstall fails on it. none-ls.nvim is the community fork and keeps
  " the `require("null-ls")` module name, so the setup block below is unchanged.
  Plug 'nvimtools/none-ls.nvim'
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
  else
    Plug 'lewis6991/gitsigns.nvim'
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

"AI
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-tree/nvim-web-devicons'

call plug#end()

"""-------------------------------------------"""
"""                   LUA                     """
"""-------------------------------------------"""

if has('nvim')

lua << EOF
-- silence deprecation warnings from unmaintained plugins (null-ls, plenary)
vim.deprecate = function() end
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

if is_fb then
  -- No direct internet access here, and nvim-treesitter downloads parsers with
  -- curl, which cannot see git's proxy config. The proxy needs a client cert,
  -- which an http_proxy env var cannot carry, and install.prefer_git breaks
  -- whenever nvim runs as the git commit editor. A curlrc can carry both, so
  -- install.sh generates one; point CURL_HOME at it for this nvim process only.
  local curlrc_dir = vim.fn.expand("~/.config/fwdproxy-curl")
  if vim.fn.filereadable(curlrc_dir .. "/.curlrc") == 1 then
    vim.env.CURL_HOME = curlrc_dir
  end

  require("meta").setup()
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
vim.keymap.set('n', '[e', function()
    vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, opts)
vim.keymap.set('n', ']e', function()
    vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

local function meta_project_id(bufnr)
  if not is_fb then
    return nil
  end

  local ok, meta_util = pcall(require, "meta.util")
  if not ok then
    return nil
  end

  local config = select(1, meta_util.arc.get_config_and_project_root(
    vim.api.nvim_buf_get_name(bufnr)
  ))
  return meta_util.arc.get_project_id_from_config(config)
end

local function format_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
    method = "textDocument/formatting",
  })
  local project_id = meta_project_id(bufnr)
  local use_linttool = project_id == "fbsource" or project_id == "www"
  local selected = {}

  for _, client in ipairs(clients) do
    if not use_linttool or client.name == "linttool@meta" then
      selected[client.id] = true
    end
  end

  if vim.tbl_isempty(selected) then
    local message = use_linttool
      and "linttool formatter is not attached yet"
      or "no formatter is attached to this buffer"
    vim.notify(message, vim.log.levels.WARN)
    return
  end

  vim.lsp.buf.format({
    bufnr = bufnr,
    async = true,
    timeout_ms = 30000,
    filter = function(client)
      return selected[client.id] == true
    end,
  })
end

vim.keymap.set('n', '<space>f', format_buffer, {
  noremap = true,
  silent = true,
  desc = "Format buffer",
})

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
end


local nvim_lsp = require("lspconfig")
local servers = {}
if is_fb then
  servers = { 
    "buckls@meta", 
    "cppls@meta", 
    "rust-analyzer@meta", 
    "thriftlsp@meta",
    "pyrefly@meta",
    "linttool@meta",
  }
else
  servers = {
    "clangd",
    "pyright",
    "rust_analyzer",
  }
end

vim.lsp.config('*', {
  on_attach = on_attach,
  flags = {
    allow_incremental_sync = false,
    debounce_text_changes = 150,
  },
  print_meta_ls_statuses_to_messages = false,
})
if is_fb then
  -- Override the default command, which passes a flag the wrapper rejects.
  vim.lsp.config("linttool@meta", {
    cmd = function(dispatchers, config)
      return vim.lsp.rpc.start(
        { "arc", "linttool", "lsp", "--caller=neovim" },
        dispatchers,
        { cwd = config.root_dir }
      )
    end,
  })
end
vim.lsp.enable(servers)

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


-- tree-sitter's main branch is an incompatible rewrite for Neovim 0.12;
-- master remains the supported branch for Neovim 0.10 and 0.11.
local treesitter_languages = {
  "c", "lua", "vim", "vimdoc", "query", "cpp", "rust", "python",
}
vim.g.dotfiles_treesitter_languages = treesitter_languages

local treesitter_ready = false
if vim.fn.has("nvim-0.12") == 1 then
  local ok, treesitter = pcall(require, "nvim-treesitter")
  if ok and type(treesitter.setup) == "function" then
    treesitter.setup {
      install_dir = vim.fn.stdpath("data") .. "/site",
    }

    local enabled = {}
    for _, language in ipairs(treesitter_languages) do
      enabled[language] = true
    end

    local group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      callback = function(args)
        local language = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
        if language and enabled[language]
            and pcall(vim.treesitter.start, args.buf, language) then
          vim.bo[args.buf].indentexpr =
            "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
    treesitter_ready = true
  else
    vim.schedule(function()
      vim.notify(
        "Neovim 0.12 requires nvim-treesitter main; run :PlugUpdate nvim-treesitter",
        vim.log.levels.WARN
      )
    end)
  end
else
  require("nvim-treesitter.configs").setup {
    ensure_installed = treesitter_languages,
    sync_install = false,
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
    },
  }
  treesitter_ready = true
end

if treesitter_ready then
  require'treesitter-context'.setup{
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    max_lines = 1, -- How many lines the window should span. Values <= 0 mean no limit.
    min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
    line_numbers = true,
    multiline_threshold = 20, -- Maximum number of lines to show for a single context
    trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
    -- Separator between context and content. Should be a single character string, like '-'.
    -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
    separator = nil,
    zindex = 20, -- The Z-index of the context window
    on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
  }
end

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
else
  require('gitsigns').setup{
    on_attach = function(bufnr)
      local gitsigns = require('gitsigns')

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end
  
      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal({']c', bang = true})
        else
          gitsigns.nav_hunk('next')
        end
      end)
  
      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal({'[c', bang = true})
        else
          gitsigns.nav_hunk('prev')
        end
      end)

      -- Actions
      map('n', '<leader>hs', gitsigns.stage_hunk)
      map('n', '<leader>hr', gitsigns.reset_hunk)
      map('v', '<leader>hs', function() gitsigns.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
      map('v', '<leader>hr', function() gitsigns.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
      map('n', '<leader>hS', gitsigns.stage_buffer)
      map('n', '<leader>hu', gitsigns.undo_stage_hunk)
      map('n', '<leader>hR', gitsigns.reset_buffer)
      map('n', '<leader>hp', gitsigns.preview_hunk)
      map('n', '<leader>hb', function() gitsigns.blame_line{full=true} end)
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
      map('n', '<leader>hd', gitsigns.diffthis)
      map('n', '<leader>hD', function() gitsigns.diffthis('~') end)
      map('n', '<leader>td', gitsigns.toggle_deleted)

      -- Text object
      map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
    end
  }
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
if has('nvim')
  set signcolumn=yes:1
endif

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
" Avoid opening a file on every cursor movement through the result list.
let g:fzf_preview_window = ['hidden', 'ctrl-/']
nnoremap <silent> <C-b> :Buffers<CR>
" Wait for a search term instead of running ripgrep with an empty pattern.
nnoremap <C-g>g :Rg<Space>
"search Rg with word under cursor
nnoremap <silent> <C-g>r :Rg <C-R><C-W><CR>
nnoremap <silent> <C-g>c :Commands<CR>
nnoremap <silent> <C-g>L :Lines<CR>
nnoremap <silent> <C-g>l :BLines<CR>
nnoremap <silent> <C-p> :Files<CR>

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

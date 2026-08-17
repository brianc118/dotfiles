set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

" Neovim has no built-in python3 (plain vim is +python3); it shells out to a
" `pynvim` host instead. Nothing in this config needs it -- every plugin here is
" Lua or vimscript -- so don't pay for a pip bootstrap on every new host.
let g:loaded_python3_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
let g:loaded_node_provider = 0

source ~/.vimrc

" A system-wide vim directory on some hosts ships a plugin that opens with an
" unguarded `python3 << EOF` block, so with the provider off every startup
" prints
"   E319: No "python3" provider found
" It has no load guard to set, so drop the directory from 'runtimepath' for
" the plugin-loading phase.
"
" Only plugin/ scripts are affected -- they load once, right after this file.
" Everything else in that directory (syntax/, ftplugin/, autoload/, after/) is
" looked up lazily, so restore the path before the first buffer is read.
" VimEnter alone is too late: it fires after the startup file's ftplugin runs.
if has('nvim')
  set runtimepath-=/usr/facebook/ops/rc/vim
  augroup FbRtpRestore
    autocmd!
    autocmd BufReadPre,BufNewFile,VimEnter * ++once
      \ set runtimepath+=/usr/facebook/ops/rc/vim
  augroup END
endif

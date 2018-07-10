filetype on
syntax on
set cursorline
autocmd FileType * TSBufEnable highlight

function! SourceRelatively(relative_path)
  " let base_file = expand('%:p')
  " let base_dir = fnamemodify(base_file, ':h')
  " 根據 init.vim 讀取相對路徑上的其他設定檔
  let absolute_path = $HOME . '/.config/nvim/' . a:relative_path . '.vim'
  " let absolute_path = fnamemodify(base_dir . '/' . a:relative_path . '.vim', ':p')
  execute 'source' absolute_path
endfunction

call SourceRelatively('keybind')
call SourceRelatively('autocomplete')
call SourceRelatively('window')
call SourceRelatively('plugins')
call SourceRelatively('plugins-config/fzf')
call SourceRelatively('plugins-config/easymotion')
call SourceRelatively('plugins-config/commentary')

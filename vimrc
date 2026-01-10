" Tabs as 2 spaces
set tabstop=2
set shiftwidth=2
set expandtab

" Show whitespace characters
set list
set listchars=tab:»·,trail:·,nbsp:·

" Fix escape key delay
set ttimeoutlen=10

" No swap files
set noswapfile

" True colors
set termguicolors
set background=dark

" Cursor shape (bar in insert, block in normal)
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" Mouse support
set mouse=a

" Leader key
let mapleader = " "

" Notes shortcuts
nnoremap <leader>nn :edit ~/notes/
nnoremap <leader>ny :edit ~/notes/2026.md<CR>
nnoremap <leader>np :edit ~/notes/people/
nnoremap <leader>nr :edit ~/notes/reviews/
nnoremap <leader>nd :execute 'edit ~/notes/daily/' . strftime("%Y-%m-%d") . '.md'<CR>
nnoremap <leader>nm :execute 'edit ~/notes/meetings/' . strftime("%Y-%m-%d") . '-'

" Next business day (skips weekends)
function! NextBusinessDay()
  let dow = strftime("%w")
  if dow == 5
    let days = 3
  elseif dow == 6
    let days = 2
  else
    let days = 1
  endif
  return trim(system('date -v+' . days . 'd +%Y-%m-%d'))
endfunction
nnoremap <leader>nt :execute 'vsplit ~/notes/daily/' . NextBusinessDay() . '.md'<CR>

" Cycle checkbox: - → - [ ] → - [x] → -
function! CycleCheckbox()
  let line = getline('.')
  if match(line, '- \[x\]') >= 0
    call setline('.', substitute(line, '- \[x\] ', '- ', ''))
  elseif match(line, '- \[ \]') >= 0
    call setline('.', substitute(line, '\[ \]', '[x]', ''))
  elseif match(line, '^\s*- ') >= 0
    call setline('.', substitute(line, '- ', '- [ ] ', ''))
  endif
endfunction
nnoremap <leader>x :call CycleCheckbox()<CR>

" Follow [[wiki-link]] under cursor
nnoremap <CR> :execute 'edit ~/notes/' . substitute(expand('<cWORD>'), '[^a-zA-Z0-9_/-]', '', 'g') . '.md'<CR>

" Auto-load meeting template for new meeting files
autocmd BufNewFile ~/notes/meetings/*.md 0r ~/notes/templates/meeting.md
      \ | execute '%s/DATE/' . strftime("%Y-%m-%d") . '/e'
      \ | execute 'normal! gg0f:ll'

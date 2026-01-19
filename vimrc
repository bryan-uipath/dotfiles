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
nnoremap <leader>nw :execute 'edit ~/notes/weekly/' . strftime("%Y-w%V") . '.md'<CR>
nnoremap <leader>nm :execute 'edit ~/notes/meetings/' . strftime("%Y-%m-%d") . '-'

" Next week (opens next week's notes in vsplit)
function! NextWeek()
  return trim(system('date -v+7d +%Y-w%V'))
endfunction
nnoremap <leader>nt :execute 'vsplit ~/notes/weekly/' . NextWeek() . '.md'<CR>

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

" Follow markdown [text](path) links
nnoremap <leader>gf :execute 'edit ' . matchstr(getline('.'), '(\zs[^)]*\ze)')<CR>

" Help gf find files
set suffixesadd+=.md
set path+=**

" Completion settings
set completeopt=menuone,noinsert
set wildmenu
set wildmode=longest:full,full

" Tab/Enter to accept completion when popup is visible
inoremap <expr> <Tab> pumvisible() ? "\<C-y>" : "\<Tab>"
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"

" Easier filename completion (Ctrl+f in insert mode)
inoremap <C-f> <C-x><C-f>

" Auto-load meeting template for new meeting files
autocmd BufNewFile ~/notes/meetings/*.md 0r ~/notes/templates/meeting.md
      \ | execute '%s/DATE/' . strftime("%Y-%m-%d") . '/e'
      \ | execute 'normal! gg0f:ll'

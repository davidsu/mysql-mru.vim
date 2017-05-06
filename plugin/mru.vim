let s:bin_mrush = expand('<sfile>:h:h').'/bin/mru.zsh'
let s:previewrb = expand('<sfile>:h:h:h').'/fzf.vim/bin/preview.rb'

function! s:sinkMru(selectedFile)
    echom substitute(a:selectedFile, '^[^/]*/', '/', '')
    let cmd = substitute(a:selectedFile, '^[^/]*/', '/', '')
    let cmd = substitute(cmd, '\([^:]*\):\(\d*\)', '+\2 \1', '')  
    execute 'edit '.cmd
    call CursorPing()
endfunction

function! s:viewMru(mrufile)
    call fzf#run({
          \  'source': 'tail -r '.a:mrufile.' | nl', 
          \  'sink':    function('s:sinkMru'),
          \  'options': '--no-sort --exact  --preview-window up:50% '.
                    \'--preview "echo {} | sed ''s#^[^/]*##'' | xargs '''.s:previewrb.''' -v" '.
                    \'--bind ''ctrl-g:toggle-preview,'.
                    \'ctrl-e:execute:$DOTFILES/fzf/fhelp.sh {} > /dev/tty''', 
          \  'down':    '70%'})
endfunction

command! Mru call s:viewMru('$HOME/.mru')
command! Mrw call s:viewMru('$HOME/.mrw')

function! s:mruIgnore()
    if &ft =~? 'git' ||
        \ &ft =~? 'nerdtree' ||
        \ &ft =~? 'help' ||
        \ expand('%') =~ 'nvim.runtime' ||
        \ expand('%') =~? 'yankring]' ||
        \ expand('%') =~? 'fugitiveblame' ||
        \ expand('%') =~? '/var/folders/.*nvim' ||
        \ expand('%') =~? '\.git/index'
        return 1
    endif
    return 0
endfunction

function! MruWithLineNum()
    if s:mruIgnore()
        return
    endif
    let command = s:bin_mrush.' '.expand('%:p').' '.getpos('.')[1]
    call system(command)
endfunction

function! Mru()
    if s:mruIgnore()
        return
    endif
    let command = s:bin_mrush.' '.expand('%:p')
    call system(command)
endfunction

function! Mrw()
    if s:mruIgnore()
        return
    endif
    let command = s:bin_mrush.' '.expand('%:p').' '.getpos('.')[1].' $HOME/.mrw'
    call system(command)
endfunction

augroup mru
    autocmd!
    autocmd BufWritePost * call Mrw()
    autocmd BufReadPost * call Mru()
    autocmd BufHidden * call MruWithLineNum()
    autocmd VimLeave * call MruWithLineNum()
augroup END

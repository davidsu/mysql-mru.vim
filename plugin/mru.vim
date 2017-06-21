let s:bin_mrush = expand('<sfile>:h:h').'/bin/mru.zsh'
let s:previewrb = expand('<sfile>:h:h:h').'/fzf.vim/bin/preview.rb'
function! s:get_mru_withLineNum_command()
    return s:bin_mrush.' '.expand('%:p').' '.getpos('.')[1]
endfunction

function! s:get_mru_command()
    return s:bin_mrush.' '.expand('%:p')
endfunction

function! s:get_mrw_command()
    return s:bin_mrush.' '.expand('%:p').' '.getpos('.')[1].' $HOME/.mrw' 
endfunction

function! s:sinkMru(selectedFile)
    echom substitute(a:selectedFile, '^[^/]*/', '/', '')
    let cmd = substitute(a:selectedFile, '^[^/]*/', '/', '')
    let cmd = substitute(cmd, '\([^:]*\):\(\d*\)', '+\2 \1', '')  
    execute 'edit '.cmd
    if exists('*CursorPing')
        call CursorPing()
    endif
endfunction

function! s:viewMru(mrufile)
    call fzf#run({
          \  'source': 'tail -r '.a:mrufile.' | nl', 
          \  'sink':    function('s:sinkMru'),
          \  'options': '--no-sort --exact  --preview-window up:50% '.
                    \'--preview "echo {} | sed ''s#^[^/]*##'' | xargs '''.s:previewrb.''' -v" '.
                    \'--header ''CTRL-o - open without abort(LESS) :: CTRL-s - toggle sort :: CTRL-g - toggle preview window'' '.
                    \'--bind ''ctrl-g:toggle-preview,'.
                    \'ctrl-o:execute:$DOTFILES/fzf/fhelp.sh {} > /dev/tty''', 
          \  'down':    '70%'})
endfunction


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

function! s:runShellCommand(command)
    if s:mruIgnore()
        return
    endif
    call system(a:command)
endfunction

command! Mru call s:viewMru('$HOME/.mru')
command! Mrw call s:viewMru('$HOME/.mrw')

augroup mru
    autocmd!
    autocmd BufWritePost * call s:runShellCommand(s:get_mrw_command())
    autocmd BufReadPost * call s:runShellCommand(s:get_mru_command())
    autocmd BufHidden * call s:runShellCommand(s:get_mru_withLineNum_command())
    autocmd VimLeave * call s:runShellCommand(s:get_mru_withLineNum_command())
augroup END

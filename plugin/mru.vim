let s:bin = expand('<sfile>:h:h').'/bin/'
let s:previewrb = expand('<sfile>:h:h:h').'/fzf.vim/bin/preview.rb'
let s:mruselect='SELECT @rn:=@rn+1 AS rank, _file, linenum '
\.'    FROM ('
\.'      SELECT *'
\.'      FROM mru'
\.'      ORDER BY ts DESC'
\.'    ) t1, (SELECT @rn:=0) t2;'
let s:mrucmd='mysql -uroot --skip-column-names --batch -e "'.s:mruselect.'" mru_vim | xargs printf ''%5s %s:%s\n'''


let s:mrwselect='SELECT @rn:=@rn+1 AS rank, _file, linenum '
\.'    FROM ('
\.'      SELECT *'
\.'      FROM mrw'
\.'      ORDER BY ts DESC'
\.'    ) t1, (SELECT @rn:=0) t2;'
let s:mrwcmd='mysql -uroot --skip-column-names --batch -e "'.s:mrwselect.'" mru_vim | xargs printf ''%5s %s:%s\n'''

function! s:sinkMru(selectedFile)
    echom substitute(a:selectedFile, '^[^/]*/', '/', '')
    let cmd = substitute(a:selectedFile, '^[^/]*/', '/', '')
    let cmd = substitute(cmd, '\(\S*\):\(\d*\)', '+\2 \1', '')  
    let cmd = escape(cmd, '$')
    execute 'edit '.cmd
    if exists('*CursorPing')
        call CursorPing()
    endif
endfunction

function! s:viewMru(dbcmd)
    call fzf#run({
          \  'source': a:dbcmd, 
          \  'sink':    function('s:sinkMru'),
          \  'options': '--no-sort --exact  --preview-window up:50% '.
                    \'--preview "echo {} | sed ''s#^[^/]*##'' | xargs '''.s:previewrb.''' -v" '.
                    \'--header ''CTRL-o - open without abort(LESS) :: CTRL-s - toggle sort :: CTRL-g - toggle preview window'' '.
                    \'--bind ''ctrl-g:toggle-preview,'.
                    \'ctrl-o:execute:$DOTFILES/fzf/fhelp.sh {} > /dev/tty'''})
endfunction

function! s:_mruIgnore(fileName)
    if &ft =~? 'git' ||
        \ &ft =~? 'nerdtree' ||
        \ &ft =~? 'help' ||
        \ expand('%') =~ 'nvim.runtime' ||
        \ expand('%') =~? 'yankring]' ||
        \ expand('%') =~? 'fugitiveblame' ||
        \ expand('%') =~? '/var/folders/.*nvim' ||
        \ expand('%') =~? '\.git/index' ||
        \ !filereadable(a:fileName)
        return 1
    endif
    return 0
endfunction

command! Mru call s:viewMru(s:mrucmd)
command! Mrw call s:viewMru(s:mrwcmd)

function! InsertMru(tableName)
    if s:_mruIgnore(expand('%:p'))
        return
    endif
    let l:fileName = escape(expand('%:p'), '$')
    let l:lineNum = getpos('.')[1]
    let l:onDuplicateKey = 'ts=now()'
    if l:lineNum == 1
        let l:onDuplicateKey = 'ts=now()'
    else
        let l:onDuplicateKey = 'ts=now(), linenum='.l:lineNum
    endif
    let l:dbcmd = 'mysql -uroot -e "'
                \.'use mru_vim; '
                \.'INSERT INTO '.a:tableName.' (_file, linenum) VALUES ('''.l:fileName.''','.l:lineNum.') '
                \.'ON DUPLICATE KEY UPDATE '.l:onDuplicateKey.';"'
    echom l:dbcmd
    call system(l:dbcmd)
endfunction
let g:dbcmd = 'bash -c ''mysql -uroot -e status || { mysql.server start && mysql -uroot -e "source '.s:bin.'schema.sql"; } > $HOME/tmp''' 
augroup mru
    autocmd!
    autocmd BufWritePost * call InsertMru('mrw')
    "todo don't change linenum for bufReadPost
    autocmd BufReadPost * call InsertMru('mru')
    autocmd BufHidden * call InsertMru('mru')
    autocmd VimLeave * call InsertMru('mru')
    autocmd VimEnter * call system(g:dbcmd)
augroup END

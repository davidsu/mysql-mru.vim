function! GitRoot(dirname)
    " convert windows paths to unix style
    let l:curDir = substitute(a:dirname, '\\', '/', 'g')

    let l:gitPath = a:dirname . '/.git'
    if isdirectory(l:gitPath) 
        return a:dirname
    else
        " walk to the top of the dir tree
        let l:parentDir = strpart(l:curDir, 0, strridx(l:curDir, '/'))
        if isdirectory(l:parentDir)
            return GitRoot(l:parentDir)
        endif
    endif
endfunction

function! CdBasedOnProjectsRootDic(gitRoot)
    " echom 'gitRoot = '.a:gitRoot
    if has_key(g:projectsRootDic, a:gitRoot)
        execute 'cd '.g:projectsRootDic[a:gitRoot]
    else
        let g:projectsRootDic[a:gitRoot] = a:gitRoot
        execute 'cd '.a:gitRoot
        return
    endif
endfunction

function! CdOnBufferEnter(isBufEntering)
    if !exists('g:projectsRootDic')
        let g:projectsRootDic = {}
    endif
    let pwd = getcwd()
    let gitRoot = GitRoot(expand('%:p:h'))
    if strlen(gitRoot) < 2
        return
    endif
    if !a:isBufEntering
        let g:projectsRootDic[gitRoot] = pwd
        return
    endif
    if pwd =~ 'config/nvim/plugged'
        call CdBasedOnProjectsRootDic(gitRoot)
        return
    endif
    if pwd =~ gitRoot 
        "remember which directory we want when comming to the current project
        let g:projectsRootDic[gitRoot] = pwd
        return
    endif
    call CdBasedOnProjectsRootDic(gitRoot)
endfunction

augroup multiProjectAutoCd
   autocmd!
   autocmd BufEnter * call CdOnBufferEnter(1)
   autocmd DirChanged * call CdOnBufferEnter(0)
augroup END

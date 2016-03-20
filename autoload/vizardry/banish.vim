" Vim plugin for installing other vim plugins.
" Maintainer: David Beniamine
"
" Copyright (C) 2015,2016, David Beniamine. All rights reserved.
" Copyright (C) 2013, James Kolb. All rights reserved.
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU Affero General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU Affero General Public License for more details.
"
" You should have received a copy of the GNU Affero General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.

if !exists("g:loaded_vizardry")
  echoerr "Vizardry not loaded"
  finish
endif

let g:save_cpo = &cpo
set cpo&vim

" UnBannish {{{1
function! vizardry#banish#UnbanishCommand(bundle)
  let niceBundle = substitute(a:bundle, '\s\s*', '', 'g')
  let matchList = vizardry#ListBanished(a:bundle)
  if len(matchList) != 0
    let success=0
    for aMatch in matchList
      if vizardry#banish#Unbanish(aMatch, 0) != 0
        call vizardry#echo('Failed to unbanish "'.aMatch.'"','e')
      else
        call vizardry#echo("Unbanished ".aMatch,'')
      endif
    endfor
    call vizardry#ReloadScripts()
  else
    if len(vizardry#ListInvoked(a:bundle))!=0
      let msg='Bundle "'.niceBundle.'" is not banished.'
    else
      let msg='Bundle "'.niceBundle.'" does not exist.'
    endif
    call vizardry#echo(msg,'w')
  endif
endfunction

function! vizardry#banish#Unbanish(bundle, reload)
  " Retrieve paths
  let l:path=vizardry#git#PathToBundleAsList(a:bundle)
  " Prepare command
  let additionalFiles=vizardry#magic#UnbanishMagic(a:bundle)
  let cmd='cd '.l:path[0].' && '.vizardry#git#MvCmd(l:path[1].'~',l:path[1])
        \.' && '.vizardry#git#CommitCmd(l:path[0],
        \l:path[1].' '.l:path[1].'~ '.additionalFiles,l:path[1],'Invoke')
  call system(l:cmd)
  let ret=v:shell_error
  if a:reload
    call vizardry#ReloadScripts()
  endif
  return ret
endfunction

" Banish {{{1
" Temporarily deactivate a plugin
function! vizardry#banish#Banish(input, type)
  if a:input == ''
    call vizardry#echo('Banish what?','w')
    return
  endif
  let inputNice = substitute(a:input, '\s\s*', '', 'g')
  let matchList = vizardry#ListInvoked(inputNice)
  if len(matchList) == 0
    if len(vizardry#ListBanished(inputNice)) != 0
      call vizardry#echo('"'.inputNice.'" has already been banished','w')
    else
      call vizardry#echo('There is no plugin named "'.inputNice.'"','e')
    endif
  else
    for aMatch in matchList
      " Retrieve path and initialize command
      let l:path=vizardry#git#PathToBundleAsList(aMatch)
      let cmd='cd '.l:path[0].' && '
      let l:commitpath=l:path[1]

      " Add action (mv / rm) to cmd
      if a:type == 'Banish'
        let l:cmd.=vizardry#git#MvCmd(l:path[1],l:path[1].'~')
        let l:commitpath.=' '.l:path[1].'~'
      else
        let l:cmd.=vizardry#git#RmBundleCmd(l:path[1])
      endif

      let additionalFiles=vizardry#magic#BanishMagic(aMatch,a:type)
      " Add commit to cmd
      let l:cmd.=' && '.vizardry#git#CommitCmd(l:path[0],l:commitpath.
            \' '.additionalFiles,l:path[1],a:type)

      let error=system(l:cmd)
      if v:shell_error==0
        call vizardry#echo(a:type.'ed '.aMatch,'')
      else
        let error = strpart(error, 0, strlen(error)-1)
        call vizardry#echo("Error renaming file: ".error,'e')
      endif
    endfor
  endif
endfunction

let cpo=save_cpo
" vim:set et sw=2:

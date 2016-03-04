" Vim plugin for installing other vim plugins.
" Maintainer: David Beniamine
"
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

" Return the name of the bundle admitting that the origin address ends by
" /name[.git]
function vizardry#local#GetRepoName(path)
  return substitute(a:path,'.*/\([^\.]*\).*','\1','')
endfunction

" UnBannish {{{1
function! vizardry#local#UnbanishCommand(bundle)
  let niceBundle = substitute(a:bundle, '\s\s*', '', 'g')
  let matches = vizardry#ListBanished(a:bundle)
  if matches!=''
    let matchList = split(matches, "\n")
    let success=0
    for aMatch in matchList
      if vizardry#local#Unbanish(aMatch, 0) != 0
        call vizardry#echo('Failed to unbanish "'.aMatch.'"','e')
      else
        call vizardry#echo("Unbanished ".aMatch,'')
      endif
    endfor
    call vizardry#ReloadScripts()
  else
    if vizardry#ListInvoked(a:bundle)!=''
      let msg='Bundle "'.niceBundle.'" is not banished.'
    else
      let msg='Bundle "'.niceBundle.'" does not exist.'
    endif
    call vizardry#echo(msg,'w')
  endif
endfunction

function! vizardry#local#Unbanish(bundle, reload)
  " Retrieve paths
  let l:path=vizardry#git#PathToBundleAsList(a:bundle)
  " Prepare command
  let cmd='cd '.l:path[0].' && '.vizardry#git#MvCmd(l:path[1].'~',l:path[1])
        \.' && '.vizardry#git#CommitCmd(l:path[0],
        \l:path[1].' '.l:path[1].'~ ',l:path[1],'Invoke')
  call system(l:cmd)
  let ret=v:shell_error
  call vizardry#local#UnbanishMagic(a:bundle)
  if a:reload
    call vizardry#ReloadScripts()
  endif
  return ret
endfunction

" Banish {{{1
" Temporarily deactivate a plugin
function! vizardry#local#Banish(input, type)
  if a:input == ''
    call vizardry#echo('Banish what?','w')
    return
  endif
  let inputNice = substitute(a:input, '\s\s*', '', 'g')
  let matches = vizardry#ListInvoked(inputNice)
  if matches == ''
    if vizardry#ListBanished(inputNice) != ''
      call vizardry#echo('"'.inputNice.'" has already been banished','w')
    else
      call vizardry#echo('There is no plugin named "'.inputNice.'"','e')
    endif
  else
    let matchList = split(matches,'\n')
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
        let l:cmd.=vizardry#git#RmCmd(l:path[1])
      endif

      " Add commit to cmd
      let l:cmd.=' && '.vizardry#git#CommitCmd(l:path[0],l:commitpath,
            \l:path[1],a:type)

      let error=system(l:cmd)
      call vizardry#local#BanishMagic(aMatch)
      if v:shell_error!=0
        call vizardry#echo(a:type.'ed '.aMatch,'')
      else
        let error = strpart(error, 0, strlen(error)-1)
        call vizardry#echo("Error renaming file: ".error,'e')
      endif
    endfor
  endif
endfunction

" Magic {{{1
function! vizardry#local#MagicName(plugin)
  if a:plugin == '*'
    return g:vizardry#scriptDir.'/magic/magic.vim'
  else
    return g:vizardry#scriptDir.'/magic/magic_'.a:plugin.'.vim'
  endif
endfunction

function! vizardry#local#BanishMagic(plugin)
  let fileName = vizardry#local#MagicName(a:plugin)
  call system('mv '.fileName.' '.fileName.'~')
endfunction

function! vizardry#local#UnbanishMagic(plugin)
  let fileName = vizardry#local#MagicName(a:plugin)
  call system('mv '.fileName.'~ '.fileName)
endfunction

function! vizardry#local#Magic(incantation)
  let incantationList = split(a:incantation, ' ')
  if len(incantationList) == 0
    call vizardry#echo("No plugin given",'w')
    return
  endif
  let plugin = incantationList[0]
  let incantation = join(incantationList[1:],' ')

  try
    exec incantation
    call system('mkdir '.g:vizardry#scriptDir.'/magic')
    call system('cat >> '.vizardry#local#MagicName(plugin), incantation."\n")
  endtry
endfunction

function! vizardry#local#MagicEdit(incantation)
  exec "edit" vizardry#local#MagicName(a:incantation)."*"
endfunction

function! vizardry#local#MagicSplit(incantation)
  exec "split" vizardry#local#MagicName(a:incantation)."*"
endfunction

function! vizardry#local#MagicVSplit(incantation)
  exec "vsplit ".vizardry#local#MagicName(a:incantation)."*"
endfunction

let cpo=save_cpo
" vim:set et sw=2:

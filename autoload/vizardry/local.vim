" Vim plugin for installing other vim plugins.
" Last Change: August 22 2015
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
  if exists("g:VizardryGitBaseDir")
    let l:path=g:vizardry#relativeBundleDir.'/'.a:bundle
    let l:commit=' && git commit -m "'.g:VizardryCommitMsgs['Invoke'].' '.
          \ a:bundle.'" '.l:path.' '.l:path.'~ .gitmodules'
    let l:cmd='cd '.g:VizardryGitBaseDir.' && git mv '.l:path.'~ '.l:path.
          \ l:commit.' && git submodule update '.l:path
  else
    let l:path=g:vizardry#bundleDir.'/'.a:bundle
    let l:cmd='mv '.l:path.'~ '.l:path
  endif
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
      if exists("g:VizardryGitBaseDir")
        let l:commit=' && git commit -m "'.g:VizardryCommitMsgs[a:type].' '.
              \ aMatch.'" '.g:vizardry#relativeBundleDir.'/'.aMatch.' .gitmodules'
        if a:type== 'Banish'
          let l:commit.=' '.g:vizardry#relativeBundleDir.'/'.aMatch.'~'
          let l:cmd='cd '.g:VizardryGitBaseDir.' && git mv '.
                \ g:vizardry#relativeBundleDir.'/'.aMatch.' '.
                \g:vizardry#relativeBundleDir.'/'.aMatch.'~'.l:commit
        else
          let l:cmd='cd '.g:VizardryGitBaseDir.' && git submodule deinit -f '.
                \ g:vizardry#relativeBundleDir.'/'.aMatch.' && git rm -rf '.
                \ g:vizardry#relativeBundleDir.'/'.aMatch.
                \ ' && rm -rf .git/modules/'.g:vizardry#relativeBundleDir.'/'.
                \ aMatch.l:commit
        endif
      else
        if a:type== 'Banish'
          let l:cmd='mv '.g:vizardry#bundleDir.'/'.aMatch.' '.
                \g:vizardry#bundleDir.'/'.aMatch.'~ >/dev/null'
        else
          let l:cmd='rm -rf '.g:vizardry#bundleDir.'/'.aMatch.' >/dev/null'
        endif
      endif
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
" vim:set et sw=2:

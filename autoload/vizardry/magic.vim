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

" Magic dir
if g:VizardryGitMethod == "clone"
  if !exists("g:VizardryMagicDir")
    " default to vizardry/plugin/magic in clone mode
    let s:magicDir=g:vizardryScriptDir.'/magic'
  endif
else
  if !exists("g:VizardryMagicDir")
    call vizardry#echo('g:VizardryMagicDir must be defined in submodule mode, '
          \."see :help Vizardry-submodule \n",'e')
    let s:magicDir=g:VizardryGitBaseDir.'/vim/plugin/magic'
    call vizardry#echo("Defaulting to: '".s:magicDir."'\n",'w')
  else
    " User defined magicDir
    let s:magicDir=g:VizardryMagicDir
  endif
  let s:relativeMagicDir=substitute(s:magicDir,g:VizardryGitBaseDir.'/','','')
endif

" Create magicdir if not existing
if glob(s:magicDir.'/') == ""
  call system('mkdir -p '.s:magicDir)
endif


" Magic {{{1
function! vizardry#magic#MagicName(plugin)
  if a:plugin == '*'
    return s:magicDir.'/magic.vim'
  else
    return s:magicDir.'/magic_'.a:plugin.'.vim'
  endif
endfunction

" Return path and path~ as a list
" where path is:
"   + The relative path from gitbasedir in submodule mode
"   + The full path to filename in clone mode
function! vizardry#magic#ListPath(filename)
  if  exists("s:relativeMagicDir")
    let path=s:relativeMagicDir.'/'.substitute(a:filename, '^.*/', '','')
    return [ path, path.'~']
  endif
  return [ filename, filename.'~' ]
endfunction

" Commit will be done by banish
function! vizardry#magic#BanishMagic(plugin,type)
  let fileName = vizardry#magic#MagicName(a:plugin)
  if a:type == 'Banish'
    " Simple banish
    if glob(fileName) != ""
      let path=vizardry#magic#ListPath(fileName)
      let l:cmd='cd '.g:VizardryGitBaseDir.' && '.
            \vizardry#git#MvCmd(path[0],path[1])
      call system(l:cmd)
      return join(path,' ')
    endif
  else
    if glob(fileName) == ""
      let fileName.='~'
      if glob(fileName) == ""
        return ''
      endif
    endif
    " Do prompt for vanish configuration files
    let ans=vizardry#doPrompt('Vanish configuration file '.fileName.' ?',
          \['y', 'n'],1)
    if ans=='y'
      let path=vizardry#magic#ListPath(fileName)
      let l:cmd='cd '.g:VizardryGitBaseDir.' && '.vizardry#git#RmCmd(path[0])
      call system(l:cmd)
      return path[0]
    endif
  endif
  return ''
endfunction

function! vizardry#magic#UnbanishMagic(plugin)
  let fileName = vizardry#magic#MagicName(a:plugin)
  if glob(fileName.'~') != ""
    " Retrieve good path
    let path=vizardry#magic#ListPath(fileName)
    " prepare command
    let l:cmd='cd '.g:VizardryGitBaseDir.' && '.
          \vizardry#git#MvCmd(path[1],path[0])
    call system(l:cmd)
    return join(path,' ')
  endif
  return ''
endfunction

function! vizardry#magic#CommitMagic(filename)
  let nicename=substitute(a:filename, '.*/', '','')
  let path=s:relativeMagicDir.'/'.nicename
  let l:cmd=':!'.vizardry#git#AddFileCmd(g:VizardryGitBaseDir, path).' && '.
        \ substitute(vizardry#git#CommitCmd(g:VizardryGitBaseDir,
        \ path,nicename,'Magic'),'.gitmodules','','g')
  execute l:cmd
endfunction

function! vizardry#magic#ListAllMagic(A,L,P)
  return glob(s:magicDir.'/*')
endfunction

function! vizardry#magic#Magic(incantation)
  let incantationList = split(a:incantation, ' ')
  if len(incantationList) == 0
    call vizardry#echo("No plugin given",'w')
    return
  endif
  let plugin = incantationList[0]
  let incantation = join(incantationList[1:],' ')

  try
    exec incantation
    call system('cat >> '.vizardry#magic#MagicName(plugin), incantation."\n")
  endtry
endfunction

function! vizardry#magic#MagicEdit(incantation)
  exec 'edit '.vizardry#magic#MagicName(a:incantation)
endfunction

function! vizardry#magic#MagicSplit(incantation)
  exec 'split '.vizardry#magic#MagicName(a:incantation)
endfunction

function! vizardry#magic#MagicVSplit(incantation)
  exec 'vsplit '.vizardry#magic#MagicName(a:incantation)
endfunction

let cpo=save_cpo
" vim:set et sw=2:

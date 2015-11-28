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

" Settings {{{1

" A few path
let g:vizardry#scriptDir = expand('<sfile>:p:h').'/..'
let g:vizardry#bundleDir = substitute(g:vizardry#scriptDir, 
      \'/[^/]*/[^/]*/[^/]*$', '', '')
if exists("g:VizardryGitBaseDir")
  let g:vizardry#relativeBundleDir=substitute(
        \g:vizardry#bundleDir,g:VizardryGitBaseDir,'','')
  let g:vizardry#relativeBundleDir=substitute(
        \g:vizardry#relativeBundleDir,'^/','','')
endif

" Prompt {{{1

" Colored echo
" If extra argument is >0, then return the input
function! vizardry#echo(msg,type,...)
  let ret=''
  if a:type=='e'
    let group='ErrorMsg'
  elseif a:type=='w'
    let group='WarningMsg'
  elseif a:type=='q'
    let group='Question'
  elseif a:type=='s'
    let group='Define'
  elseif a:type=='D'
    if !exists("g:VizardryDebug")
      return
    else
      let group='WarningMsg'
    endif
  else
    let group='Normal'
  endif
  execute 'echohl '.group
  if a:0 > 0 && a:1 > 0
    let ret=input(a:msg)
  else
    echo a:msg
  endif
  echohl None
  return ret
endfunction

function! vizardry#usage()
  call vizardry#echo("Welcome to vizardry ".g:loaded_vizardry,"q")
  echo "\n"
  call vizardry#echo("You can search and list plugins with :Scry","n")
  call vizardry#echo("or install them with :Invoke.","n")
  echo "\n"
  call vizardry#echo("Then it is possible to temporay :Banish a plugin","n")
  call vizardry#echo("or even :Vanish it completly.","n")
  echo "\n"
  call vizardry#echo("You can also :Evolve on or all of them","n")
  echo "\n"
  call vizardry#echo("For more info look at :help vizardry","w")
endfunction

function! vizardry#listChoices(choices)
  let length = len(a:choices)
  if length == 0
    return ""
  elseif length == 1
    return a:choices[0]
  elseif length == 2
    return a:choices[0]." or ".a:choices[1]
  endif

  let i = 0
  let ret=''
  while(i < length-1)
    let ret = ret.a:choices[i].', '
    let i+=1
  endwhile
  return ret.'or '.a:choices[length-1]
endfunction

function! vizardry#doPrompt(prompt, inputChoices)
  while 1
    let choice=vizardry#echo(a:prompt."\n",'q',1)
    if index(a:inputChoices,choice,0,1) >= 0
      echo "\n"
      return choice
    endif
    call vizardry#echo("\nInvalid choice: Type ".vizardry#listChoices(a:inputChoices).
          \": ",'w')
  endwhile
endfunction

" bundle management {{{1

" Test existing bundle
function! vizardry#testBundle(bundle)
  if a:bundle!=""
    return system('ls -d '.g:vizardry#bundleDir.'/'.a:bundle.' 2>/dev/null')!=''
  endif
endfunction

function! vizardry#formValidBundle(bundle)
  if !vizardry#testBundle(a:bundle) && !vizardry#testBundle(a:bundle.'~')
    return a:bundle
  endif

  let counter = 0
  while vizardry#testBundle(a:bundle.counter)
        \ || vizardry#testBundle(a:bundle.counter.'~')
    let counter += 1
  endwhile
  return a:bundle.counter
endfunction

" List Invoked / Banished plugins {{{2
function! vizardry#ListAllInvoked(A,L,P)
  return vizardry#ListInvoked('*')
endfunction

function! vizardry#ListAllBanished(A,L,P)
  return vizardry#ListBanished('*')
endfunction

function! vizardry#ListInvoked(match)
  let invokedList = system('ls -d '.g:vizardry#bundleDir.'/'.a:match.
        \ ' 2>/dev/null | grep -v "~$" | sed -n "s,.*/\(.*\),\1,p"')
  return invokedList
endfunction

function! vizardry#ListBanished(match)
  let banishedList = system('ls -d '.g:vizardry#bundleDir.'/'.a:match.
        \ '~ 2>/dev/null | sed -n "s,.*/\(.*\)~,\1,p"')
  return banishedList
endfunction

function! vizardry#DisplayInvoked()
  let invokedList = split(vizardry#ListInvoked('*'),'\n')
  if len(invokedList) == ''
    call vizardry#echo("No plugins invoked",'w')
  else
    call vizardry#echo("Invoked: ",'')
    let maxlen=0
    for invoked in invokedList
      if len(invoked)>maxlen
        let maxlen=len(invoked)
      endif
    endfor
    for invoked in invokedList
      let origin = system('(cd '.g:vizardry#bundleDir.'/'.invoked.
            \ '&& git config --get remote.origin.url) 2>/dev/null')
      let origin = strpart(origin, 0, strlen(origin)-1)
      if origin==''
        call vizardry#echo(invoked,'')
      else
        call vizardry#echo(invoked.repeat(' ',maxlen-len(invoked)+3).
              \"(".origin.")",'')
      endif
    endfor
  endif
endfunction

function! vizardry#DisplayBanished()
  let banishedList = split(vizardry#ListBanished('*'),'\n')
  if len(banishedList) == ''
    call vizardry#echo("No plugins banished",'w')
  else
    call vizardry#echo("Banished: ",'')
    let maxlen=0
    for banished in banishedList
      if len(banished)>maxlen
        let maxlen=len(banished)
      endif
    endfor
    for banished in banishedList
      let origin = system('(cd '.g:vizardry#bundleDir.'/'.banished.
            \ '~ && git config --get remote.origin.url) 2>/dev/null')
      let origin = strpart(origin, 0, strlen(origin)-1)
      if origin==''
        call vizardry#echo(banished,'')
      else
        call vizardry#echo(banished.repeat(' ',maxlen-len(banished)+3).
              \"(".origin.")",'')
      endif
    endfor
  endif
endfunction

" Reload scripts {{{2
function! vizardry#ReloadScripts()
  " Force pathogen reload
  unlet g:loaded_pathogen
  source $MYVIMRC
  let files=[]
  for plugin in split(&runtimepath,',')
    for file in split(system ("find ".plugin.
          \ '/plugin -name "*.vim" 2>/dev/null'),'\n')
      try
        exec 'silent source '.file
      catch
      endtry
    endfor
    for file in split(system ("find ".plugin.
          \ '/after -name "*.vim" 2>/dev/null'),'\n')
      try
        exec 'silent source '.file
      catch
      endtry
    endfor
  endfor
  execute ':Helptags'
endfunction

" vim:set et sw=2:

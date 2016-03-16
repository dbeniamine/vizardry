" Vim plugin for installing other vim plugins.
" Maintainer: David Beniamine
"
" Copyright (C) 2015, David Beniamine. All rights reserved.
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

" This files contains usefull function that might be used by any other
" autoloaded file

let g:save_cpo = &cpo
set cpo&vim

" Settings {{{1
" Bundle path
let g:vizardry#bundleDir = substitute(g:vizardryScriptDir.'/..',
      \'/[^/]*/[^/]*/[^/]*$', '', '')


" Path to bundle from gitbasedir
if g:VizardryGitMethod != "clone"
  let g:vizardry#relativeBundleDir=substitute(
        \g:vizardry#bundleDir,g:VizardryGitBaseDir,'','')
  let g:vizardry#relativeBundleDir=substitute(
        \g:vizardry#relativeBundleDir,'^/','','')
endif

" Repo name from path{{{1

" Return the name of the bundle admitting that the origin address ends by
" /name[.git]
function vizardry#GetRepoName(path)
  return substitute(a:path,'.*/\([^\.]*\).*','\1','')
endfunction


" Prompt {{{1

" Should be used for every messages
" Type can be:
"   e for error
"   w for warning
"   q for asking a question
"   s to tell the user Vizardry is doing something (searching for instance)
"   D to print only in debug mode
" If extra argument is >0, then return the user answer
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

" Show Vizardry usage, called by :Vizardry
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

" Helper to print choises properly
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

" Prompt the user with prompt
" Ensure the answer is correct aka is a string contained in the list
" inputChoises
" if echoChoices is 1, show the list of choices in the prompt
function! vizardry#doPrompt(prompt, inputChoices, echoChoices)
  if a:echoChoices == 0
    let prompt=a:prompt."\n"
  else
    let prompt=a:prompt.' ['.join(a:inputChoices,'/')."]\n"
  endif
  while 1
    let choice=vizardry#echo(prompt,'q',1)
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
" Returns "" if the bundle does not exists
"            the full path to the bundle if it exists
function! vizardry#testBundle(bundle)
  if a:bundle!=""
    return glob(g:vizardry#bundleDir.'/'.a:bundle.'/')!=''
  endif
endfunction

" Find a valid bundle name for bundle avoiding to erase existing bundles
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

" Providers {{{1
" List existing grimoires
function! vizardry#ListGrimoires()
  return s:VizardryAvailableGrimoires
endfunction

" List Invoked / Banished plugins {{{2
" List are returne as a string
function! vizardry#ListAllInvoked(A,L,P)
  return join(vizardry#ListInvoked('*'),"\n")
endfunction

function! vizardry#ListAllBanished(A,L,P)
  return join(vizardry#ListBanished('*'),"\n")
endfunction

" List invoked bundle matching "match"
" return a list of matches
function! vizardry#ListInvoked(match)
  if a:match =~'\(*\)$'
    let l:match=a:match.'[^~]'
  else
    let l:match=a:match
  endif
  return split(substitute(glob(g:vizardry#bundleDir.'/'.l:match),
        \'[^\n]*/\([^\n]*\(\n\|$\)\)','\1','g'),'\n')
endfunction

" List banished bundle matching "match"
" return a list of matches
function! vizardry#ListBanished(match)
  return split(substitute(glob(g:vizardry#bundleDir.'/'.a:match.'~'),
        \'[^\n]*/\([^\~]*\)\~\(\n\|$\)','\1\2','g'),'\n')
endfunction

function! vizardry#DisplayInvoked()
  let invokedList = vizardry#ListInvoked('*')
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
      let origin = vizardry#git#GetOrigin(g:vizardry#bundleDir.'/'.invoked)
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
  let banishedList = vizardry#ListBanished('*')
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
      let origin = vizardry#git#GetOrigin(g:vizardry#bundleDir.'/'.banished.'~')
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
" TODO: autoloaded files
function! vizardry#ReloadScripts()
  " Force pathogen reload
  unlet g:loaded_pathogen
  source $MYVIMRC
  let files=[]
  for plugin in split(&runtimepath,',')
    for file in glob(plugin.'/plugin/**/*.vim',0,1)
      try
        exec 'silent source '.file
      catch
      endtry
    endfor
    for file in glob(plugin.'/after/**/*.vim',0,1)
      try
        exec 'silent source '.file
      catch
      endtry
    endfor
  endfor
  execute ':Helptags'
endfunction

let cpo=save_cpo
" vim:set et sw=2:

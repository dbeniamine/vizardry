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

let g:save_cpo = &cpo
set cpo&vim

" How to read Readme files
if !exists("g:VizardryReadmeReader")
  let g:VizardryReadmeReader='view -c "set ft=markdown"'
endif

" How to read help files
if !exists("g:VizardryHelpReader")
  let g:VizardryHelpReader='view -c "set ft=help"'
endif

" Allow fallback to help/readme
if !exists("g:VizardryReadmeHelpFallback")
  let g:VizardryReadmeHelpFallback=1
endif

" Functions {{{1
" Call curl on the given url
" Returns the result as a list
function! vizardry#remote#GetURL(url)
  return systemlist("curl -silent '".a:url."'")
endfunction

" Use the commmand reader to read the content at url
function! vizardry#remote#ReadUrl(reader,url)
  " Remove trailing '-' for retrocompatibility with vizardry v1.x
  let l:reader=substitute(a:reader,'-$','','')
  let tmpfile = tempname()
  let contents=vizardry#remote#GetURL(a:url)
  execute 'redir > '.tmpfile
  " Remove everything until first empty line and print the contents
  silent echo join(contents[match(contents,'^$'):],"\n")
  redir END
  " Read the temporary file
  execute ':!'.l:reader.' '.tmpfile
endfunction

" Display documentation for site
" If fallback == 1 Display the other type is the requested type is not found
" type MUST be 'Readme' or 'Help'
function! vizardry#remote#DisplayDoc(site,fallback,type)
  " Prepare functions
  if a:type=='Readme'
    let l:Fun=function('vizardry#grimoire#ReadmeUrl')
    let l:reader=g:VizardryReadmeReader
    let l:otype='Help'
  else
    let l:Fun=function('vizardry#grimoire#HelpUrl')
    let l:reader=g:VizardryHelpReader
    let l:otype='Readme'
  endif
  " Retrieve url
  call vizardry#echo('Looking for '.a:type.' url','s')
  let l:url=l:Fun(a:site)
  call vizardry#echo('Retrieving '.a:type,'s')
  " test url
  if l:url== ""
    let fourofour="404"
  else
    let fourofour=matchstr(vizardry#remote#GetURL(l:url)[0],'404')
  endif
  " Fallback
  if fourofour != ""
    call vizardry#echo('No '.a:type.' found', "e")
    if a:fallback == 1 && g:VizardryReadmeHelpFallback == 1
      call vizardry#remote#DisplayDoc(a:site,0,l:otype)
    endif
  else
    call vizardry#remote#ReadUrl(l:reader,url)
  endif
endfunction

let cpo=save_cpo
" vim:set et sw=2:

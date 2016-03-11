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

" This file provide the github provider API
let s:baseURL='https://github.com/'
let s:APIUrl="https://api.github.com/"
let s:rawUrl="https://raw.githubusercontent.com/"
let s:SearchUrl=s:APIUrl.'search/repositories?q='

" Return the clone url for site/name
function! vizardry#github#CloneUrl(repo)
  return s:baseURL.a:repo
endfunction

" Return the Readme.md url for site/name
function! vizardry#github#ReadmeUrl(repo)
  let answer=join(vizardry#remote#GetURL(s:APIUrl.'repos/'.a:repo.'/readme'),"\n")
  return substitute(answer,'.*download_url"[^"]*"\([^"]*\)",.*','\1','')
endfunction

" Return the Help url for repo (doc/name.txt)
function! vizardry#github#HelpUrl(repo)
  let answers=vizardry#remote#GetURL(s:APIUrl.'repos/'.a:repo.'/contents/doc')
  let found=0
  " Look for a help matching the exact name then ony the last word of the
  " name, finally or any .txt file in doc directory
  let name=vizardry#GetRepoName(a:repo)
  let docnames=[name.'.txt',substitute(name,'.*\A\(\a*\)\A*.*','\1.*.txt',''),
        \".*.txt"]
  for doc in docnames
    for ans in answers
      if ans=~?'"name": "'.doc
        let found=1
      elseif ans=~'download_url' && found==1
        return substitute(ans,'.*download_url"[^"]*"\([^"]*\)",.*','\1','')
      endif
    endfor
  endfor
  return ""
endfunction

" Return the repo name from the origin url
function vizardry#github#SiteFromOrigin(path)
  return vizardry#grimoire#SiteFromOrigin(a:path,
        \substitute(s:baseURL,'.*/\([^/]*\)/$','\1',''))
endfunction

" Handle query at github search API format
" https://api.github.com/search/repositories?q=user:dbeniamine+vim+fork:true+sort:stars
" Return a list of repo
"   a repo is a dictionnary with two values:
"       + site: the site name e.g: dbeniamine/vizardry
"       + description: the description
function! vizardry#github#HandleQuery(input)
  let l:results=vizardry#remote#GetURL(s:SearchUrl.a:input)
  let parsedList=[]
  for line in results
    if line =~ 'full_name'
      let item={}
      let item.site=substitute(line, '\s*"full_name"[^"]*"\([^"]*\)"[^\n]*','\1','g')
    elseif line =~ 'description'
      if line=~' null,'
        let item.description="No description available"
      else
        let item.description=substitute(line,'\s*\S* "\(.*\)",','\1','')
      endif
      call add(parsedList,item)
    endif
  endfor
  return parsedList
endfunction

let cpo=save_cpo
" vim:set et sw=2:

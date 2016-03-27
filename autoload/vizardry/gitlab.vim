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

" This file provide the gitlab provider API
if !exists("g:VizardryGitlabInstanceUrl")
  let s:instanceUrl='gitlab.com/'
else
  let s:instanceUrl=g:VizardryGitlabInstanceUrl
endif

let s:baseURL='https://'.s:instanceUrl
"let s:APIUrl=s:baseURL.'/api/2.0/repositories'
let s:SearchUrl=s:baseURL.'search?search='

" Return the clone url for site/name
function! vizardry#gitlab#CloneUrl(repo)
  return s:baseURL.a:repo.'.git'
endfunction

function! vizardry#gitlab#RawFileUrlFromHref(href)
  return s:baseURL.substitute(substitute(a:href,'.*href="\([^"]*\)".*','\1','')
        \,'/blob/','/raw/','')
endfunction

" Return the Readme.md url for site/name
function! vizardry#gitlab#ReadmeUrl(repo,branch)
  " List sources
  let ans=vizardry#remote#GetURL(s:baseURL.'/'.a:repo.'/tree/'.a:branch)
  let icase=&ignorecase
  set ignorecase
  " Get readme url
  let readmeurl=ans[match(ans,'.*href.*strong')]
  let ignorecase=icase
  return vizardry#gitlab#RawFileUrlFromHref(readmeurl)
endfunction

" Return the Help url for repo (doc/name.txt)
function! vizardry#gitlab#HelpUrl(repo,branch)
  " List sources
  let links=vizardry#remote#GetURL(s:baseURL.'/'.a:repo.'/tree/'.a:branch.'/doc/')
  let id=0
  let docnames=vizardry#grimoire#GetDocNames(a:repo)
  for doc in docnames
    while 1
      let id=match(links,'/doc/.*\.txt',id+1)
      if id < 0
        " No more links
        break
      elseif links[id] =~ doc
        " Matching documentation
        return vizardry#gitlab#RawFileUrlFromHref(links[id])
      endif
    endwhile
  endfor
  return ""
endfunction

" Return the repo name from the origin url
function vizardry#gitlab#SiteFromOrigin(path)
  return vizardry#grimoire#SiteFromOriginHelper(a:path,
        \substitute(s:baseURL,'.*/\([^/]*\)/$','\1',''))
endfunction

" Handle query at github search API format
" https://api.github.com/search/repositories?q=user:dbeniamine+vim+fork:true+sort:stars
" Return a list of repo
"   a repo is a dictionnary with two values:
"       + site: the site name e.g: dbeniamine/vizardry
"       + description: the description
function! vizardry#gitlab#FormatQuery(input)
  " Handle users
  let query=substitute(a:input,'user:\([^+]*\)','\1', '')
  " Remove +vim in the end
  let query=substitute(query,'+vim+','+', '')
  " Ignore every other fields
  let query=substitute(substitute(query,'[^+]*:[^+]*','','g'),'^+*\([^+].*[^+]\)+*$','\1','')
  " vim should appear at the beggining for gitlab lame search
  return 'vim+'.query
endfunction

function! vizardry#gitlab#HandleQuery(input)
  let l:query=vizardry#gitlab#FormatQuery(a:input)
  let l:results=vizardry#remote#GetURL(s:SearchUrl.l:query)
  let parsedList=[]
  let inside=0
  for line in results
    if line =~ '<a class="project" href='
      let inside=1
      let item={}
      let item.site=substitute(line, '.*href="\s*\/\([^"]*\)".*','\1','g')
    elseif inside==1 && line =~ '<p>'
      let item.description=substitute(line,'.*<p>\s*\(.*\)\s*</p>.*','\1','')
      let item.description=substitute(item.description,'<.*img.*>','','')
      let inside=0
      call add(parsedList,item)
    endif
  endfor
  return parsedList
endfunction

let cpo=save_cpo
" vim:set et sw=2:

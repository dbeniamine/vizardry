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
  let readmeurl=system("curl -silent '".s:APIUrl."repos/".
        \a:repo."/readme' | grep download_url")
  return substitute(readmeurl,'\s*"download_url"[^"]*"\(.*\)",.*','\1','')
endfunction

" Return the Help url for repo (doc/name.txt)
function! vizardry#github#HelpUrl(repo)
  return vizardry#grimoire#HelpUrl(s:rawUrl.a:repo,
        \vizardry#local#GetRepoName(a:repo))
endfunction

" Return the repo name from the origin url
function vizardry#github#SiteFromOrigin(path)
  return vizardry#grimoire#SiteFromOrigin(a:path,
        \substitute(s:baseURL,'.*/\([^/]*\)/$','\1',''))
endfunction

" Format query for the provider and return the url including query, as:
" https://api.github.com/search/repositories?q=user:dbeniamine+vim+fork:true+sort:stars
function! vizardry#github#GenerateQuery(input)
  return s:SearchUrl.a:input
endfunction

let cpo=save_cpo
" vim:set et sw=2:

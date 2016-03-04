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

" This file provide the github provider API

" Return the clone url for site/name
function! vizardry#github#CloneUrl(repo)
  return 'https://github.com/'.a:repo
endfunction

" Return the Readme.md url for site/name
function! vizardry#github#ReadmeUrl(repo)
  let readmeurl=system("curl -silent 'https://api.github.com/repos/".
              \a:repo."/readme' | grep download_url")
  return substitute(readmeurl,'\s*"download_url"[^"]*"\(.*\)",.*','\1','')
endfunction

" Return the Help url for repo (doc/name.txt)
function! vizardry#github#HelpUrl(repo)
  let l:name=substitute(a:repo,'.*/\([^\.]*\).*','\1','')
  return 'https://raw.githubusercontent.com/'.a:repo.'/master/doc/'.
              \l:name.'.txt'
endfunction

" Return the repo name from the origin url
function vizardry#github#SiteFromOrigin(path)
  let l:site=system('cd '.a:path.' && git remote -v')
  let l:site=substitute(site,'origin\s*\(\S*\).*','\1','')
  let l:site=substitute(site,'.*github\.com.\(.*\)','\1','')
  return substitute(site,'\(.*\).git','\1','')
endfunction

" Format query for the provider and return the url including query, as:
" https://api.github.com/search/repositories?q=user:dbeniamine+vim+fork:true+sort:stars
"TODO input should already be at github's api format
function! vizardry#github#GenerateQuery(input)
  " Sanitize input / prepare query
  let user=substitute(a:input, '.*-u\s\s*\(\S*\).*','\1','')
  let l:input=substitute(substitute(a:input, '-u\s\s*\S*','',''),
        \'^\s\s*','','')
  let g:vizardry#lastScry = substitute(l:input, '\s\s*', '', 'g')
  let lastScryPlus = substitute(l:input, '\s\s*', '+', 'g')
  let query=lastScryPlus
  if match(a:input, '-u') != -1
    let query=substitute(query,'+$','','') "Remove useless '+' if no keyword
    let query.='+user:'.user
  endif
  call vizardry#echo("Searching for ".query."...",'s')
  let query.='+vim+'.g:VizardrySearchOptions
  call vizardry#echo("(actual query: '".query."')",'')
  return 'https://api.github.com/search/repositories?q='.query
endfunction


" vim:set et sw=2:

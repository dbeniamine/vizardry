" Vim plugin for installing other vim plugins.
" Maintainer: David Beniamine
"
" Copyright (C) 2015, David Beniamine. All rights reserved.
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

" To add a grimoire (provider):
"  + create a file autoload/vizardry/mygrimoire.vim which implement each of
"   the function described below:
"       + vizardry#mygrimoire#CloneUrl(repo)
"           + return the url for cloning repo
"       + vizardry#mygrimoires#ReadmeUrl(site,name)
"           + return the url to the readme (markdown not HTML)
"       + vizardry#mygrimoires#HelpUrl(site,name)
"           + return the url to the help (vim help something like '/doc/name.txt')
"       + vizardry#mygrimoires#HandleQuery(query)
"           + Handle query at github API format (https://api.github.com/search/repositories?q=user:dbeniamine+vim+fork:true+sort:stars)
"           + return a list a repo
"               a repo is a dictionnary with two values:
"                   + site: the site eg: dbeniamine/vizardry
"                   + description: the repo description
"           + This function MUST use vizardry#remote#GetURL(url) instead of
"            system('curl '.url) this function returns the result as a list
"      You can use the provided generic helper defined in the end of this
"      file. For more info see: autoload/vizardry/github.vim
"  + Add the grimoire name to the list below
"  + Update the documentation to add the grimoire and the search api
"  + Please test before creating a pull request

let s:VizardryAvailableGrimoires = ['github']

" Vizardry grimoires API {{{1
function! vizardry#grimoire#SetGrimoire(grimoire)
  let l:grimoire=a:grimoire
  while(match(s:VizardryAvailableGrimoires, '\<'.l:grimoire.'\>') < 0)
    call vizardry#echo("Unknown grimoire '".a:grimoire."'",'e')
    let l:grimoire=vizardry#doPrompt('Please select a grimoire',
          \s:VizardryAvailableGrimoires,1)
  endwhile
  let g:VizardryCloneUrl=function('vizardry#'.l:grimoire.'#CloneUrl')
  let g:VizardryReadmeUrl=function('vizardry#'.l:grimoire.'#ReadmeUrl')
  let g:VizardryHelpUrl=function('vizardry#'.l:grimoire.'#HelpUrl')
  let g:VizardrySiteFromOrigin=function('vizardry#'.l:grimoire.'#SiteFromOrigin')
  let g:VizardryHandleQuery=function('vizardry#'.l:grimoire.'#HandleQuery')
endfunction

" Vizardry grimoire generic helper {{{1
" see autoload/vizardry/github.vim for usage example


" Return the Help url admitting that baseurl is the url to the roots of the
" plugin contents and name is the name of the bundle
function! vizardry#grimoire#HelpUrl(baseurl,name)
  return a:baseurl.'/master/doc/'.a:name.'.txt'
endfunction

" Extract site from origin if origin looks like
" .*baseurl.site[.git]
" for instance https://github.com/dbeniamine/vizardry.git, github.com
" will return dbeniamine/vizardry.git
function! vizardry#grimoire#SiteFromOrigin(origin,baseurl)
  let l:site=substitute(a:origin,'origin\s*\(\S*\).*','\1','')
  let l:site=substitute(l:site,'.*'.a:baseurl.'[:/]\(.*\)','\1','')
  return substitute(site,'\(.*\).git$','\1','')
endfunction

let cpo=save_cpo
" vim:set et sw=2:

" Vim plugin for installing other vim plugins.
" Maintainer: David Beniamine
"
" Copyright (C) 2015,2016, David Beniamine. All rights reserved.
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

" Initialization {{{1

if !exists("g:VizardryDefaultGrimoire")
  let g:VizardryDefaultGrimoire='github'
endif

let s:currentGrimoire=g:VizardryDefaultGrimoire


" Vizardry grimoires API {{{1

" To add a grimoire (provider) one only need to create a file
" autoload/vizardry/grimoires/mygrimoire.vim which implement each of the
" functions described below:
"   + vizardry#grimoires#mygrimoire#CloneUrl(repo)
"       + return the url for cloning repo
"   + vizardry#grimoires#mygrimoires#ReadmeUrl(repo,branch)
"       + return the url to the readme (markdown not HTML)
"   + vizardry#grimoires#mygrimoires#HelpUrl(repo,branch)
"       + return the url to the help (vim help something like '/doc/name.txt')
"   + vizardry#grimoires#mygrimoires#HandleQuery(query)
"       + Handle query at github API format (https://api.github.com/search/repositories?q=user:dbeniamine+vim+fork:true+sort:stars)
"       + return a list a repo
"           a repo is a dictionnary with two values:
"               + site: the site eg: dbeniamine/vizardry
"               + description: the repo description
"       + This function MUST use vizardry#remote#GetURL(url) instead of
"        system('curl '.url) this function returns the result as a list
"      You can use the provided generic helper defined in the end of this
"      file. For more info see:
"      autoload/vizardry/grimoires/[github,gitlab,bitbucket].vim
"  Once a grimoire is done, please update the documentation (user and
"  developper) accordingly.

" List all files in autoload/grimoires/*.vim
let s:VizardryAvailableGrimoires = split(substitute(glob(expand('<sfile>:p:h')
      \.'/grimoires/*.vim'),'[^\n]*\/\([^\.]*\)\.vim','\1','g'),'\n')

" Grimoires command functions {{{2

function! vizardry#grimoire#ListGrimoires(A,L,P)
  return join(s:VizardryAvailableGrimoires,"\n")
endfunction

function! vizardry#grimoire#SetGrimoire(grimoire,silent)
  let l:grimoire=s:currentGrimoire
  if a:silent==0
    " Verbose mode
    if a:grimoire==""
      call vizardry#echo('Available grimoires: ['.join(s:VizardryAvailableGrimoires,
          \',').']', 'n')
    else
      let l:grimoire=a:grimoire
      while(match(s:VizardryAvailableGrimoires, '\<'.l:grimoire.'\>') < 0)
        call vizardry#echo("Unknown grimoire '".a:grimoire."'",'e')
        let l:grimoire=vizardry#doPrompt('Please select a grimoire',
              \s:VizardryAvailableGrimoires,1)
      endwhile
    endif
    call vizardry#echo("Current Grimoire : ".l:grimoire, "s")
  endif
  let s:currentGrimoire=l:grimoire
endfunction

" Wrappers arround grimoire specific functions {{{2
function! vizardry#grimoire#CloneUrl(site)
  return function('vizardry#grimoires#'.s:currentGrimoire.'#CloneUrl')(a:site)
endfunction

function! vizardry#grimoire#ReadmeUrl(site,branch)
  return function('vizardry#grimoires#'.s:currentGrimoire.'#ReadmeUrl')(a:site,a:branch)
endfunction

function! vizardry#grimoire#HelpUrl(site,branch)
  return function('vizardry#grimoires#'.s:currentGrimoire.'#HelpUrl')(a:site,a:branch)
endfunction

function! vizardry#grimoire#HandleQuery(query)
  return function('vizardry#grimoires#'.s:currentGrimoire.'#HandleQuery')(a:query)
endfunction

function! vizardry#grimoire#GetCurrentGrimoire()
  return s:currentGrimoire
endfunction

" Vizardry grimoire generic helper {{{1
" see autoload/vizardry/github.vim for usage example


" Returns the grimoire corresponding to url
" Side effect: change the grimoire
function! vizardry#grimoire#GrimoireFromOrigin(url)
  for g in s:VizardryAvailableGrimoires
    if a:url =~ g
      call vizardry#grimoire#SetGrimoire(g,1)
      return g
    endif
  endfor
  return ""
endfunction

" Return the site from url
" Side effect: change the grimoire
function! vizardry#grimoire#SiteFromOrigin(url)
  let grimoire=vizardry#grimoire#GrimoireFromOrigin(a:url)
  return function('vizardry#grimoires#'.grimoire.'#SiteFromOrigin')(a:url)
endfunction

" Extract site from origin if origin looks like
" .*baseurl.site[.git]
" for instance https://github.com/dbeniamine/vizardry.git, github.com
" will return dbeniamine/vizardry.git
function! vizardry#grimoire#SiteFromOriginHelper(origin,baseurl)
  let l:site=substitute(a:origin,'origin\s*\(\S*\).*','\1','')
  let l:site=substitute(l:site,'.*'.a:baseurl.'[:/]\(.*\)','\1','')
  return substitute(site,'\(.*\).git$','\1','')
endfunction

" Returns a list of possible matches for documentation names for repo a:repo
" sorted by pertinence
function! vizardry#grimoire#GetDocNames(repo)
  let name=vizardry#GetRepoName(a:repo)
  " Look for a help matching the exact name then ony the last word of the
  " name, finally or any .txt file in doc directory
  return [name.'.txt',substitute(name,'.*\A\(\a*\)\A*.*','\1.*.txt',''),
        \".*.txt"]
endfunction

let cpo=save_cpo
" vim:set et sw=2:

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

" This file provide the bitbucket provider API
if !exists("g:VizardryBitbucketInstanceUrl")
  let s:instanceUrl='bitbucket.org/'
else
  let s:instanceUrl=g:VizardryBitbucketInstanceUrl
endif

let s:baseURL='https://'.s:instanceUrl
let s:APIUrl=s:baseURL.'/api/2.0/repositories'
"let s:rawUrl="https://raw.bitbucketusercontent.com/"
let s:SearchUrl=s:baseURL.'/repo/all/?name='

" Return the clone url for site/name
function! vizardry#grimoires#bitbucket#CloneUrl(repo)
  let ans=join(vizardry#remote#GetURL(s:APIUrl.'/'.a:repo), ' ')
  let scm=substitute(ans,'.*"scm": "\([^"]*\)".*','\1','')
  if scm != "git"
    call vizardry#echo("This bundle is not versioned under git, clone won't work",
          \"w")
    return ""
  endif
  return s:baseURL.a:repo
endfunction

function! vizardry#grimoires#bitbucket#RawFileUrlFromHref(href)
  return s:baseURL.substitute(substitute(a:href,'.*href="\([^"]*\)".*','\1','')
        \,'/src/','/raw/','')
endfunction

" Return the Readme.md url for site/name
function! vizardry#grimoires#bitbucket#ReadmeUrl(repo,branch)
  " List sources
  let ans=vizardry#remote#GetURL(s:baseURL.'/'.a:repo.'/src/?at='.a:branch)
  let icase=&ignorecase
  set ignorecase
  " Get readme
  let readmeurl=ans[match(ans,'[^\.]readme')]
  let ignorecase=icase
  return vizardry#grimoires#bitbucket#RawFileUrlFromHref(readmeurl)
endfunction

" Return the Help url for repo (doc/name.txt)
function! vizardry#grimoires#bitbucket#HelpUrl(repo,branch)
  " List sources
  let ans=vizardry#remote#GetURL(s:baseURL.'/'.a:repo.'/src/?at='.a:branch)
  " Get contents of doc directory
  let docurl=ans[match(ans,'/doc/')]
  let docurl=substitute(docurl,'.*href="\([^"]*\)".*','\1','')
  let doclinks=join(vizardry#remote#GetURL(s:baseURL.docurl),"\n")
  " Extract doc links
  let links=split(doclinks,"\n")
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
        return vizardry#grimoires#bitbucket#RawFileUrlFromHref(links[id])
      endif
    endwhile
  endfor
  return ""
endfunction

" Return the repo name from the origin url
function vizardry#grimoires#bitbucket#SiteFromOrigin(path)
  return vizardry#grimoire#SiteFromOriginHelper(a:path,
        \substitute(s:baseURL,'.*/\([^/]*\)/$','\1',''))
endfunction

" Handle query at github search API format
" https://api.github.com/search/repositories?q=user:dbeniamine+vim+fork:true+sort:stars
" Return a list of repo
"   a repo is a dictionnary with two values:
"       + site: the site name e.g: dbeniamine/vizardry
"       + description: the description
function! vizardry#grimoires#bitbucket#FormatQuery(input)
  " Handle users
  let query=substitute(a:input,'user:\([^+]*\)','\1\/', '')
  " Handle language
  let language=substitute(query,'.*language:\([^+]*\).*','\&language=\1', '')
  if l:language == query
    let language=""
  endif
  " Ignore every other fields
  let query=substitute(substitute(query,'[^+]*:[^+]*','','g'),'^+*\([^+].*[^+]\)+*$','\1','')
  " Append language options
  let query.=tolower(l:language)
  return query
endfunction

function! vizardry#grimoires#bitbucket#HandleQuery(input)
  let l:query=vizardry#grimoires#bitbucket#FormatQuery(a:input)
  let l:results=vizardry#remote#GetURL(s:SearchUrl.l:query)
  let parsedList=[]
  let inside=0
  for line in results
    if line =~ 'h1.*repo'
      let inside=1
      let item={}
      let item.site=substitute(line, '.*href="\s*\/\([^"]*\)".*','\1','g')
    elseif inside==1 && line =~ '<p>'
      let item.description=substitute(line,'.*<p>\s*\(.*\)\s*</p>.*','\1','')
      let inside=0
      call add(parsedList,item)
    endif
  endfor
  return parsedList
endfunction

let cpo=save_cpo
" vim:set et sw=2:

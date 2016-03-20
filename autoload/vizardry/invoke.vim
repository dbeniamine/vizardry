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

" Settings {{{1

" Number of results displayed by Scry
if !exists("g:VizardryNbScryResults")
  let g:VizardryNbScryResults=10
endif

" Search options using github API
" https://developer.github.com/v3/search/#search-repositories
if !exists("g:VizardrySearchOptions")
  let g:VizardrySearchOptions='fork:true'
endif

" Invoke helpers {{{1

" Clone a Repo {{{2
function! vizardry#invoke#grabRepo(site, name)
  let l:path=vizardry#git#PathToBundleAsList(a:name)
  let l:commitPath=l:path[1]
  let l:cmd=':!cd '.l:path[0].' && '
  let l:url=vizardry#grimoire#CloneUrl(a:site)
  let l:cmd.=vizardry#git#CloneCmd(l:url,l:path[1]).' && '.
        \vizardry#git#CommitCmd(l:path[0],l:commitPath,l:path[1],'Invoke')
  execute l:cmd
endfunction

" Test existing repo {{{2
function! vizardry#invoke#testRepo(repository)
  redraw
  let name=vizardry#GetRepoName(a:repository)
  let bundleList = vizardry#ListInvoked(name) + vizardry#ListBanished(name)
  let origin=vizardry#git#RemoveProto(vizardry#grimoire#CloneUrl(a:repository))
  for bundle in bundleList
    if origin == vizardry#git#RemoveProto(vizardry#git#GetOrigin(
          \g:vizardry#bundleDir.'/'.bundle))
      return bundle
    endif
  endfor
  return ""
endfunction

" Invoke handler {{{2
function! vizardry#invoke#handleInvokation(site, description, inputNice, index)
  let valid = 0
  let bundle=substitute(a:site, '.*/','','')
  let inputNice = vizardry#formValidBundle(bundle)
  let ret=-1
  let len=len(s:siteList)-1
  while valid == 0
    call vizardry#echo("Result ".a:index."/".len.
          \ ": ".a:site."\n(".a:description.")\n\n",'')
    let response = vizardry#doPrompt("Clone as \"".inputNice.
          \ "\": [Yes/Rename/Displayreadme/displayHelp/Next/Previous/Abort]",
          \ ['y','r','d','h','n','p','a'],0)
    if response ==? 'y'
      call vizardry#invoke#grabRepo(a:site, inputNice)
      call vizardry#ReloadScripts()
      let valid=1
    elseif response ==? 'r'
      let newName = ""
      let inputting = 1
      while inputting
        redraw
        call vizardry#echo("Clone as: ".newName,'')
        let oneChar=getchar()
        if nr2char(oneChar) == "\<CR>"
          let inputting=0
        elseif oneChar == "\<BS>"
          if newName!=""
            let newName = strpart(newName, 0, strlen(newName)-1)
            call vizardry#echo("gClone as: ".newName,'')
          endif
        else
          let newName=newName.nr2char(oneChar)
        endif
      endwhile
      if vizardry#testBundle(newName)
        redraw
        call vizardry#echo("Name already taken",'w')
      else
        call vizardry#invoke#grabRepo(a:site, newName)
        call vizardry#ReloadScripts()
        let valid = 1
      endif
    elseif response ==? 'n'
      let ret=a:index+1
      let valid = 1
    elseif response ==? 'd'
      call vizardry#remote#DisplayDoc(a:site,1,'Readme')
    elseif response ==? 'h'
      call vizardry#remote#DisplayDoc(a:site,1,'Help')
    elseif response ==? 'a'
      let valid=1
    elseif response ==? 'p'
      let ret=a:index-1
      let valid=1
    endif
  endwhile
  redraw
  return ret
endfunction

" Query provider {{{2

" Remove 'a:args option' from query
" Returns a list:
"   First element is the new query
"   Second is the option
function! vizardry#invoke#ExtractArgsFromQuery(input, args)
  if a:input =~ a:args
    let value =substitute(a:input, '.*'.a:args.'\s\s*\(\S*\).*','\1','')
    let query=substitute(substitute(a:input, a:args.'\s\s*\S*','',''),
        \'^\s*\(\S.*\S\)\s*$','\1','')
    return [query,value]
  endif
  return [a:input,""]
endfunction

" Format query to github API
function! vizardry#invoke#FormatQuery(input)
  " Parse Vizardry arguments
  let [query,user]=vizardry#invoke#ExtractArgsFromQuery(a:input,'-u')
  let [query,grimoire]=vizardry#invoke#ExtractArgsFromQuery(query,'-g')
  "remove spaces
  let s:lastScry = substitute(query, '\s\s*', '', 'g')
  let lastScryPlus = substitute(query, '\s\s*', '+', 'g')
  let query=lastScryPlus
  if user!=""
    let query.='+user:'.user
  endif
  if grimoire!=""
    call vizardry#grimoire#SetGrimoire(grimoire,0)
  endif
  call vizardry#echo("Searching for ".query."...",'s')
  let query.='+vim+'.g:VizardrySearchOptions
  return query
endfunction

" Retrieve repo lists
function! vizardry#invoke#InitLists(input)
  let query=vizardry#invoke#FormatQuery(a:input)
  call vizardry#echo("(actual query: '".query."')",'')
  " Do query
  let s:siteList=vizardry#grimoire#HandleQuery(l:query)
  call  vizardry#echo(s:siteList,'D' )
  let ret=len(s:siteList)
  if ret == 0
    call vizardry#echo("No results found for query '".a:input."'",'w')
  endif
  return ret
endfunction

" Commands {{{ 1

" Invoke {{{2
" Install or unBannish a plugin
function! vizardry#invoke#Invoke(input)
  if a:input == '' " No input, reload plugins
    call vizardry#ReloadScripts()
    call vizardry#echo("Updated scripts",'')
    return
  endif

  if a:input =~ '^\d\+$'
    " No previous Scry
    if !exists("s:lastScry")
      call vizardry#echo("':Invoke ".a:input."' does not make sense without ".
            \"a previous call to :Scry","e")
      return
    endif
    let inputNumber = str2nr(a:input)
    " Input is a number search from previous search results
    if exists("s:siteList") && inputNumber < len(s:siteList)
          \|| a:input=="0"
      let l:index=inputNumber
      call vizardry#echo("Index ".inputNumber.' from scry search for "'.
            \s:lastScry.'":','s')
      let inputNice = s:lastScry
    else
      if !exists("s:siteList")
        call vizardry#echo("Invalid command :'Invoke ".a:input.
              \"' numeric argument can only be used after an actual search ".
              \ "(Scry or invoke)",'e')
      else
        let max=len(s:siteList)-1
        call vizardry#echo("Invalid plugin number ".inputNumber." while max is "
              \.max,'e')
      endif
      return
    endif
  else
    " Actual query
    let inputNice = substitute(substitute(a:input, '\s*-u\s\s*\S*\s*','',''),
          \ '\s\s*', '', 'g')
    let exists = vizardry#testBundle(inputNice)
    if exists
      let response = vizardry#doPrompt('You already have a bundle called '
            \ .inputNice.'. Search anyway ?',['y','n'],1)
      if response == 'n'
        return
      endif
    endif
    let len=vizardry#invoke#InitLists(a:input)
    let l:index=0
  endif

  " Installation prompt / navigation trough results
  while( l:index >= 0 && l:index < len(s:siteList))
    let site=s:siteList[l:index].site
    let description=s:siteList[l:index].description
    let matchingBundle = vizardry#invoke#testRepo(site)
    if matchingBundle != ""
      call vizardry#echo('Found '.site,'s')
      call vizardry#echo('('.description.')','')
      if(matchingBundle[len(matchingBundle)-1] == '~')
        let matchingBundle = strpart(matchingBundle,0,strlen(matchingBundle)-1)
        call vizardry#echo('This is the repository for banished bundle "'.
              \matchingBundle.'"','w')
        if( vizardry#doPrompt("Unbanish it ?", ['y', 'n'])== 'y',1)
          call vizardry#local#Unbanish(matchingBundle, 1)
          execute ':Helptags'
        endif
        redraw
      else
        call vizardry#echo('This has already been invoked as "'.
              \matchingBundle.'"','w')
      endif
      return
    else
      let l:index=vizardry#invoke#handleInvokation(site, description, inputNice,index)
      redraw
    endif
  endwhile
endfunction

" Scry {{{2
function! vizardry#invoke#Scry(input)
  if a:input == ''
    call vizardry#DisplayInvoked()
    echo "\n"
    call vizardry#DisplayBanished()
  else
    let length=vizardry#invoke#InitLists(a:input)
    let index=0
    let choices=[]
    if length == 0
      return
    endif
    redraw
    while index<length
      call vizardry#echo(index.": ".s:siteList[index].site,'')
      call vizardry#echo('('.s:siteList[index].description.')','')
      call add(choices,string(index))
      let index=index+1
      if index<length
        echo "\n"
      endif
    endwhile
    call add(choices,'q')
    let ans=vizardry#doPrompt("Invoke script number [0:".length.
          \"] or quit Scry (q) ?",choices,0)
    if ans!='q'
      call vizardry#invoke#Invoke(ans)
    endif
  endif
endfunction

let cpo=save_cpo
" vim:set et sw=2:

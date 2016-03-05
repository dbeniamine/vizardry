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

" Settings {{{1
if !exists("g:VizardryDefaultGrimoire")
  let g:VizardryDefaultGrimoire='github'
endif

" Initialize grimoires
call vizardry#grimoire#SetGrimoire(g:VizardryDefaultGrimoire)

" Number of results displayed by Scry
if !exists("g:VizardryNbScryResults")
  let g:VizardryNbScryResults=10
endif

" How to read Readme files
if !exists("g:VizardryReadmeReader")
  let g:VizardryReadmeReader='view -c "set ft=markdown" -'
endif

" How to read help files
if !exists("g:VizardryHelpReader")
  let g:VizardryHelpReader='view -c "set ft=help" -'
endif

" Allow fallback to help/readme
if !exists("g:VizardryReadmeHelpFallback")
  let g:VizardryReadmeHelpFallback=1
endif

" Search options using github API
" https://developer.github.com/v3/search/#search-repositories
if !exists("g:VizardrySearchOptions")
  let g:VizardrySearchOptions='fork:true'
endif

if !exists("g:VizardryViewReadmeOnEvolve")
  let g:VizardryViewReadmeOnEvolve=0
endif

let g:vizardry#remote#EvolveVimOrgPath = g:vizardry#scriptDir.'/plugin/EvolveVimOrgPlugins.sh'
" Functions {{{1
" Call curl
function! vizardry#remote#GetURL(url)
  return system("curl -silent '".a:url."'")
endfunction

" Clone a Repo {{{2
function! vizardry#remote#grabRepo(site, name)
  let l:path=vizardry#git#PathToBundleAsList(a:name)
  let l:commitPath=l:path[1]
  let l:cmd=':!cd '.l:path[0].' && '
  let l:url=g:VizardryCloneUrl(a:site)
  let l:cmd.=vizardry#git#CloneCmd(l:url,l:path[1]).' && '.
        \vizardry#git#CommitCmd(l:path[0],l:commitPath,l:path[1],'Invoke')
  execute l:cmd
endfunction

" Test existing repo {{{2
function! vizardry#remote#testRepo(repository)
  redraw
  let name=vizardry#local#GetRepoName(a:repository)
  let bundleList = split(vizardry#ListInvoked(name),'\n') +
        \split(vizardry#ListBanished(name),'\n')
  let origin=vizardry#git#RemoveProto(g:VizardryCloneUrl(a:repository))
  for bundle in bundleList
    if origin == vizardry#git#RemoveProto(vizardry#git#GetOrigin(
          \g:vizardry#bundleDir.'/'.bundle))
      return bundle
    endif
  endfor
  return ""
endfunction

" Use the commmand reader to read the content at url
function! vizardry#remote#readurl(reader,url)
  execute ":!curl -silent '".a:url."'".' | sed "1,/^$/ d" | '.a:reader
endfunction

" Display help or Readme
" type MUST be 'Readme' or 'Help'
function! vizardry#remote#DisplayDoc(site,fallback,path,type)
  " Prepare functions
  if a:type=='Readme'
    let l:Fun=g:VizardryReadmeUrl
    let l:reader=g:VizardryReadmeReader
    let l:otype='Help'
  else
    let l:Fun=g:VizardryHelpUrl
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
    let fourofour=matchstr(split(vizardry#remote#GetURL(l:url),'\n')[0],'404')
  endif
  " Fallback
  if fourofour != ""
    call vizardry#echo('No '.a:type.' found', "e")
    if a:fallback == 1
      call vizardry#remote#DisplayDoc(a:site,0,a:path,l:otype)
    endif
  else
    call vizardry#remote#readurl(l:reader,url)
  endif
endfunction

" Invoke helper {{{2
function! vizardry#remote#handleInvokation(site, description, inputNice, index)
  let valid = 0
  let bundle=substitute(a:site, '.*/','','')
  let inputNice = vizardry#formValidBundle(bundle)
  let ret=-1
  let len=len(g:vizardry#siteList)-1
  while valid == 0
    call vizardry#echo("Result ".a:index."/".len.
          \ ": ".a:site."\n(".a:description.")\n\n",'')
    let response = vizardry#doPrompt("Clone as \"".inputNice.
          \ "\"? (Yes/Rename/Displayreadme/displayHelp/Next/Previous/Abort)",
          \ ['y','r','d','h','n','p','a'])
    if response ==? 'y'
      call vizardry#remote#grabRepo(a:site, inputNice)
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
        call vizardry#remote#grabRepo(a:site, newName)
        call vizardry#ReloadScripts()
        let valid = 1
      endif
    elseif response ==? 'n'
      let ret=a:index+1
      let valid = 1
    elseif response ==? 'd'
      call vizardry#remote#DisplayDoc(a:site,g:VizardryReadmeHelpFallback,"",
            \'Readme')
    elseif response ==? 'h'
      call vizardry#remote#DisplayDoc(a:site,g:VizardryReadmeHelpFallback,"",
            \'Help')
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

" Format query to github API
function! vizardry#remote#FormatQuery(input)
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
  return query
endfunction

" Retrieve repo lists
function! vizardry#remote#InitLists(input)
  let query=vizardry#remote#FormatQuery(a:input)
  call vizardry#echo("(actual query: '".query."')",'')
  " Do query
  let g:vizardry#siteList=g:VizardryHandleQuery(l:query)
  call  vizardry#echo(g:vizardry#siteList,'D' )
  let ret=len(g:vizardry#siteList)
  if ret == 0
    call vizardry#echo("No results found for query '".a:input."'",'w')
  endif
  return ret
endfunction

" Commands {{{ 1

" Invoke {{{2
" Install or unBannish a plugin
function! vizardry#remote#Invoke(input)
  if a:input == '' " No input, reload plugins
    call vizardry#ReloadScripts()
    call vizardry#echo("Updated scripts",'')
    return
  endif

  if a:input =~ '^\d\+$'
    let inputNumber = str2nr(a:input)
    " Input is a number search from previous search results
    if exists("g:vizardry#siteList") && inputNumber < len(g:vizardry#siteList)
          \|| a:input=="0"
      let l:index=inputNumber
      call vizardry#echo("Index ".inputNumber.' from scry search for "'.
            \g:vizardry#lastScry.'":','s')
      let inputNice = g:vizardry#lastScry
    else
      if !exists("g:vizardry#siteList")
        call vizardry#echo("Invalid command :'Invoke ".a:input.
              \"' numeric argument can only be used after an actual search ".
              \ "(Scry or invoke)",'e')
      else
        let max=len(g:vizardry#siteList)-1
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
            \ .inputNice.'. Search anyway? (Yes/No)',['y','n'])
      if response == 'n'
        return
      endif
    endif
    let len=vizardry#remote#InitLists(a:input)
    let l:index=0
  endif

  " Installation prompt / navigation trough results
  while( l:index >= 0 && l:index < len(g:vizardry#siteList))
    let site=g:vizardry#siteList[l:index].site
    let description=g:vizardry#siteList[l:index].description
    let matchingBundle = vizardry#remote#testRepo(site)
    if matchingBundle != ""
      call vizardry#echo('Found '.site,'s')
      call vizardry#echo('('.description.')','')
      if(matchingBundle[len(matchingBundle)-1] == '~')
        let matchingBundle = strpart(matchingBundle,0,strlen(matchingBundle)-1)
        call vizardry#echo('This is the repository for banished bundle "'.
              \matchingBundle.'"','w')
        if( vizardry#doPrompt("Unbanish it? (Yes/No)", ['y', 'n'])== 'y')
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
      let l:index=vizardry#remote#handleInvokation(site, description, inputNice,index)
      redraw
    endif
  endwhile
endfunction

" Evolve {{{2

" Upgrade a specific plugin (git repo)
function s:GitEvolve(path, branch)
  let curbranch=system(vizardry#git#GetCurrentBranch(a:path))
  let commitreq=0
  " Specific branch required ?
  if curbranch != a:branch
    call vizardry#git#CheckoutBranch(a:path,a:branch)
    " Force commiting
    let commitreq=1
  endif
  let curbranch=a:branch
  " Do upgrade
  let l:ret=vizardry#git#Upgrade(a:path,curbranch)
  call vizardry#echo(l:ret,'')
  " Do we need a commit ?
  if commitreq==0 && l:ret=~'Already up-to-date'
    return ''
  endif
  " Handle readme/log/help display
  if g:VizardryViewReadmeOnEvolve == 1
    let continue=0
    let name=vizardry#local#GetRepoName(a:path)
    while continue==0
      let response=vizardry#doPrompt(name.' Evolved, show Readme, Log or Continue ? (r,l,c,h)',
            \['r','l','c', 'h'])
      if response ==? 'r' || response ==? 'h'
        let l:site=g:VizardrySiteFromOrigin(vizardry#git#GetOrigin(a:path))
        if response ==? 'r'
          let l:doctype='Readme'
        else
          let l:doctype='Help'
        endif
        call vizardry#remote#DisplayDoc(site,g:VizardryReadmeHelpFallback,
              \a:path,l:doctype)
      elseif response ==? 'l'
        call vizardry#git#Log(a:path)
      elseif response ==? 'c'
        let continue=1
      endif
    endwhile
  endif
  " Return upgraded path
  return a:path
endfunction

" Upgrade a specific plugin (vim.org)
function s:VimOrgEvolve(path)
  let name=substitute(a:path,'.*/','','')
  call vizardry#echo(name.' is not a git repo, trying to update it as a vim.org script', 's')
  call vizardry#echo("Directly updating from vim.org is deprecated\n".
        \"You can install ".name." from vim.org's github account:\n".
        \":Scry -u vim-scripts ".name, 'w')
  let l:ret=system(g:vizardry#remote#EvolveVimOrgPath.' '.a:path)
  call vizardry#echo(l:ret,'')
  if l:ret=~'upgrading .*'
    return a:path
  endif
  return ''
endfunction

" Upgrade one or every plugins
function! vizardry#remote#Evolve(input, rec)
  if a:input==""
    " Try evolve every plugins
    let invokedList = split(vizardry#ListInvoked('*'),'\n')
    let l:files=''
    for plug in invokedList
      let l:files.=' '.vizardry#remote#Evolve(plug,1)
    endfor
  else
    " Try evolve a particular plugin
    let inarray=split(substitute(a:input, '^\s\s*', '', ''), '\s\s*')
    let inputNice=inarray[0]
    if len(inarray) >= 2
      let branch=inarray[1]
    else
      let branch="master"
    endif
    let exists = vizardry#testBundle(inputNice)
    if !exists
      call vizardry#echo("No plugin named '".inputNice."', aborting upgrade",'e')
      return
    endif
    if vizardry#git#IsAGitRepo(g:vizardry#bundleDir.'/'.inputNice)
      let l:files=s:GitEvolve(g:vizardry#bundleDir.'/'.inputNice, branch)
    else
      let l:files=s:VimOrgEvolve(g:vizardry#bundleDir.'/'.inputNice)
    endif
  endif
  let l:files=substitute(l:files,'^\s*$','','')
  if a:rec==0
    " Commit / echo result
    if l:files!=""
      let l:basefiles=substitute(
            \ substitute(l:files,g:vizardry#bundleDir.'/','','g'),'\s\s*', ' ','g')
      let cmd=vizardry#git#CommitCmd(g:VizardryGitBaseDir,l:files,
            \l:basefiles,'Evolve')
      execute ':!'.cmd
      if cmd == 'true'
        call vizardry#echo("Evolved plugins: ".l:files,'')
      endif
    else
      call vizardry#echo("No plugin upgraded",'w')
    endif
  else
    return l:files
  endif
endfunction


" Evolve completion:
" arg1: Invoked plugin
" arg2: Available branch
function! vizardry#remote#EvolveCompletion(A,L,P)
  if a:L =~ '^\s*\S\S*\s\s*\S\S*\s\s*'
    let bundle=substitute(a:L,'\s*\S\S*\s\s*\(\S\S*\)\s.*', '\1','')
    let l:path=g:vizardry#bundleDir.'/'.bundle
    if !empty(glob(l:path))
      return vizardry#git#CompleteBranches(l:path)
    else
      return ""
    endif
  else
    return vizardry#ListAllInvoked(a:A,a:L,a:P)
  endif
endfunction

" Scry {{{2
function! vizardry#remote#Scry(input)
  if a:input == ''
    call vizardry#DisplayInvoked()
    echo "\n"
    call vizardry#DisplayBanished()
  else
    let length=vizardry#remote#InitLists(a:input)
    let index=0
    let choices=[]
    if length == 0
      return
    endif
    redraw
    while index<length
      call vizardry#echo(index.": ".g:vizardry#siteList[index].site,'')
      call vizardry#echo('('.g:vizardry#siteList[index].description.')','')
      call add(choices,string(index))
      let index=index+1
      if index<length
        echo "\n"
      endif
    endwhile
    call add(choices,'q')
    let ans=vizardry#doPrompt("Invoke script number [0:".length.
          \"] or quit Scry (q) ?",choices)
    if ans!='q'
      call vizardry#remote#Invoke(ans)
    endif
  endif
endfunction

let cpo=save_cpo
" vim:set et sw=2:

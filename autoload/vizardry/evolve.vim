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

if !exists("g:VizardryViewReadmeOnEvolve")
  let g:VizardryViewReadmeOnEvolve=0
endif

" Evolve {{{1

" Upgrade a specific plugin (git repo)
function s:GitEvolve(path, branch)
  let curbranch=vizardry#git#GetCurrentBranch(a:path)
  let commitreq=0
  " Specific branch required ?
  if (curbranch =~ 'detached' || (a:branch != "" && curbranch != a:branch))
    if a:branch == ""
      let curbranch="master"
    else
      let curbranch=a:branch
    endif
    call vizardry#git#CheckoutBranch(a:path,curbranch)
    " Force commiting
    let commitreq=1
  endif
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
    let name=vizardry#GetRepoName(a:path)
    while continue==0
      let response=vizardry#doPrompt(name.' Evolved, show Readme, Log or Continue ?',
            \['r','l','c', 'h'],1)
      if response ==? 'r' || response ==? 'h'
        let l:site=vizardry#grimoire#SiteFromOrigin(vizardry#git#GetOrigin(a:path))
        if response ==? 'r'
          let l:doctype='Readme'
        else
          let l:doctype='Help'
        endif
        call vizardry#remote#DisplayDoc(site,1,l:doctype)
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
  let name=vizardry#GetRepoName(a:path)
  call vizardry#echo(name.' is not a git repo, trying to update it as a vim.org script', 'w')
  call vizardry#echo("Directly updating from vim.org is deprecated\n".
        \"You can install ".name." from vim.org's github account:\n".
        \":Scry -u vim-scripts ".name, 'e')
  return ''
endfunction

" Upgrade one or every plugins
function! vizardry#evolve#Evolve(input, rec)
  let oldgrim=vizardry#grimoire#GetCurrentGrimoire()
  if a:input==""
    " Try evolve every plugins
    let invokedList = vizardry#ListInvoked('*')
    let l:files=''
    for plug in invokedList
      let l:files.=' '.vizardry#evolve#Evolve(plug,1)
    endfor
  else
    " Try evolve a particular plugin
    let inarray=split(substitute(a:input, '^\s\s*', '', ''), '\s\s*')
    let inputNice=inarray[0]
    if len(inarray) >= 2
      let branch=inarray[1]
    else
      let branch=""
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
  if oldgrim !=  vizardry#grimoire#GetCurrentGrimoire()
    call vizardry#grimoire#SetGrimoire(oldgrim, 1)
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
function! vizardry#evolve#EvolveCompletion(A,L,P)
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



let cpo=save_cpo
" vim:set et sw=2:

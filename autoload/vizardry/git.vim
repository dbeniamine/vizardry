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


" This file provides wrapper arount git commands to avoid git command
" replication inside vizardry

" General git function {{{1

" Remove '\n' in git answers
function! vizardry#git#RemoveEndline(line)
  return strpart(a:line,0,len(a:line)-1)
endfunction

" Get the origin repository addresses
function! vizardry#git#GetOrigin(path)
  let l:ret=system('(cd '.a:path.
        \' && git config --get remote.origin.url) 2>/dev/null')
  return vizardry#git#RemoveEndline(l:ret)
endfunction

" Return the init submodule cmd as a string
function! vizardry#git#InitSubmoduleCmd(path)
  return 'cd '.a:path.' && git submodule init && git submodule update'
endfunction

" Return the current branch for path
function! vizardry#git#GetCurrentBranch(path)
  return 'cd '.a:path.
        \" && git branch | grep '^*' | sed 's/^* //' | tr -d  '\n'"
endfunction

" Checkout branch in repo at path
function! vizardry#git#CheckoutBranch(path,branch)
  if empty(system('cd '.a:path.' && git branch | grep '.a:branch))
    " Create a branch
    let checkoutArg=' -b '
  else
    " Existing branch
    let checkoutArg=' '
  endif
  call system('cd '.a:path.' && git checkout '.checkoutArg.a:branch)
endfunction

" Pull branch on origin
function! vizardry#git#Upgrade(path, branch)
  return system('cd '.a:path.' && git pull origin '.a:branch.
        \' && git submodule init && git submodule update')
endfunction

" Show git log
function! vizardry#git#Log(path)
  execute ':!cd '.a:path .' && git log'
endfunction

" Test if path is a git repository
function! vizardry#git#IsAGitRepo(path)
  return  glob(a:path.'/.git')!=""
endfunction

function! vizardry#git#CompleteBranches(path)
  return system('cd '.a:path.'; git ls-remote --heads 2>/dev/null'.
        \' | sed "s/.*heads\///"')
endfunction

" Function depending on git metchod used {{{1
if(g:VizardryGitMethod == "clone")
  " Return the path to a bundle {{{2
  " The first element of the list is the base path (from which we execute
  " commands)
  " The second is the path to the bundle
  function! vizardry#git#PathToBundleAsList(bundle)
    return [g:vizardry#bundleDir,a:bundle]
  endfunction

  " Return the commit command as a string {{{2
  function vizardry#git#CommitCmd(bundlePath, commitPath, messagePath, messageType)
    return 'true' " We do not commit anything in clone mode
  endfunction

  " Return the mv command as a string
  function! vizardry#git#MvCmd(src, dest)
    return 'mv '.a:src.' '.a:dest
  endfunction

  " Return the rm command as a string
  function! vizardry#git#RmCmd(path)
    return 'rm -rf '.a:path.' > /dev/null'
  endfunction

  " Return the clone command as a string
  function! vizardry#git#CloneCmd(repo,path)
    return 'git clone '.a:repo.' '.a:path.' && '.
          \vizardry#git#InitSubmoduleCmd(a:path)
  endfunction
else
  " Return the path to a bundle {{{2
  " The first element of the list is the base path (from which we execute
  " commands)
  " The second is the path to the bundle
  function! vizardry#git#PathToBundleAsList(bundle)
    return [g:VizardryGitBaseDir,g:vizardry#relativeBundleDir.'/'.a:bundle]
  endfunction

  " Return the commit command as a string {{{2
  function vizardry#git#CommitCmd(bundlePath, commitPath, messagePath, messageType)
    return 'cd '.a:bundlePath.' && git commit -m "'.
          \g:VizardryCommitMsgs[a:messageType].' '.a:messagePath.
          \'" '.a:commitPath.' .gitmodules'
  endfunction

  " Return the mv command as a string
  function! vizardry#git#MvCmd(src, dest)
    return 'git mv '.a:src.' '.a:dest
  endfunction

  " Return the rm command as a string
  function! vizardry#git#RmCmd(path)
    return 'git submodule deinit -f '.a:path.' && git rm -rf '.a:path.
          \ ' && rm -rf .git/modules/'.a:path
  endfunction

  " Return the clone command as a string
  function! vizardry#git#CloneCmd(repo,path)
    return 'git submodule add '.a:repo.' '.a:path.' && '.
          \vizardry#git#InitSubmoduleCmd(a:path)
  endfunction
endif

" vim:set et sw=2:

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

if exists("g:loaded_vizardry")
  finish
endif

let g:save_cpo = &cpo
set cpo&vim

let g:loaded_vizardry = "v1.4"

" Plugin Settings {{{1

" Installation method simple clone / submodules
if !exists("g:VizardryGitMethod")
  let g:VizardryGitMethod = "clone"
elseif (g:VizardryGitMethod =="submodule add")
  " Commit message for submodule method
  if !exists("g:VizardryCommitMsgs")
    let g:VizardryCommitMsgs={'Invoke': "[Vizardry] Invoked vim submodule:",
          \'Banish': "[Vizardry] Banished vim submodule:",
          \'Vanish': "[Vizardry] Vanished vim submodule:",
          \'Evolve': "[Vizardry] Evolved vim submodule:",
          \}
  endif
  " Git root directory for submodules
  if !exists("g:VizardryGitBaseDir")
    echoerr "g:VizardryGitBaseDir must be set when VizardryGitMethod is submodule"
    echoerr "Vizardry not loaded"
    unlet g:loaded_vizardry
    finish
  endif
endif

" Commands definitions {{{1
command! -nargs=0 Vizardry call vizardry#usage()
command! -nargs=? Invoke call vizardry#remote#Invoke(<q-args>)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Banish
      \ call vizardry#local#Banish(<q-args>, 'Banish')
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Vanish
      \ call vizardry#local#Banish(<q-args>, 'Vanish')
command! -nargs=? -complete=custom,vizardry#ListAllBanished Unbanish
      \ call vizardry#local#UnbanishCommand(<q-args>)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Evolve
      \ call vizardry#remote#Evolve(<q-args>,0)
command! -nargs=? Scry
      \ call vizardry#remote#Scry(<q-args>)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Magic
      \ call vizardry#local#Magic(<q-args>)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Magicedit
      \ call vizardry#local#MagicEdit(<q-args>)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Magicsplit
      \ call vizardry#local#MagicSplit(<q-args>)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Magicvsplit
      \ call vizardry#local#MagicVSplit(<q-args>)

" Vim plugin for installing other vim plugins.
" Maintainer: David Beniamine
"
" Copyright (C) 2015,2016 David Beniamine. All rights reserved.
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

let g:loaded_vizardry = "v2.0"

" Plugin Settings {{{1

" Vizardry base path
let g:vizardryScriptDir = expand('<sfile>:p:h')


" Installation method simple clone / submodules
if !exists("g:VizardryGitMethod")
  let g:VizardryGitMethod = "clone"
  " Git basedir is not needed for clone, but should be defined to avoid errors
  let g:VizardryGitBaseDir=""
elseif (g:VizardryGitMethod !="clone")
  " Commit message for submodule method
  if !exists("g:VizardryCommitMsgs")
    let g:VizardryCommitMsgs={'Invoke': "[Vizardry] Invoked vim submodule:",
          \'Banish': "[Vizardry] Banished vim submodule:",
          \'Vanish': "[Vizardry] Vanished vim submodule:",
          \'Evolve': "[Vizardry] Evolved vim submodule:",
          \'Magic':  "[Vizardry] Updated Magic file:",
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
" :Vizardry (version/usage)
command! -nargs=0 Vizardry call vizardry#usage()
" :Grimoire (choose / list bundle providers)
command! -nargs=? -complete=custom,vizardry#grimoire#ListGrimoires Grimoire
      \ call vizardry#grimoire#SetGrimoire(<q-args>,'0')
" :Invoke (install / reload bundles)
command! -nargs=? Invoke call vizardry#invoke#Invoke(<q-args>)
" :Banish (disable a bundle)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Banish
      \ call vizardry#banish#Banish(<q-args>, 'Banish')
" :Unbanish (reenable a bundle)
command! -nargs=? -complete=custom,vizardry#ListAllBanished Unbanish
      \ call vizardry#banish#UnbanishCommand(<q-args>)
" :Vanish (remove a bundle)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Vanish
      \ call vizardry#banish#Banish(<q-args>, 'Vanish')
" :Evolve (upgrade a bundle)
command! -nargs=? -complete=custom,vizardry#evolve#EvolveCompletion Evolve
      \ call vizardry#evolve#Evolve(<q-args>,0)
" :Scry (list / search bundles)
command! -nargs=? Scry
      \ call vizardry#invoke#Scry(<q-args>)
" :Magic (manage configuration, not activelly maintained)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Magic
      \ call vizardry#magic#Magic(<q-args>)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Magicedit
      \ call vizardry#magic#MagicEdit(<q-args>)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Magicsplit
      \ call vizardry#magic#MagicSplit(<q-args>)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Magicvsplit
      \ call vizardry#magic#MagicVSplit(<q-args>)
command! -nargs=? -complete=custom,vizardry#magic#ListAllMagic MagicCommit
      \ call vizardry#magic#CommitMagic(<q-args>)

let cpo=save_cpo
" vim:set et sw=2:

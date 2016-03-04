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
command! -nargs=1 -complete=custom,vizardry#ListGrimoires Grimoire
            \ call VizardrySetGrimoire(<q-args>)
command! -nargs=? Invoke call vizardry#remote#Invoke(<q-args>)
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Banish
            \ call vizardry#local#Banish(<q-args>, 'Banish')
command! -nargs=? -complete=custom,vizardry#ListAllInvoked Vanish
            \ call vizardry#local#Banish(<q-args>, 'Vanish')
command! -nargs=? -complete=custom,vizardry#ListAllBanished Unbanish
            \ call vizardry#local#UnbanishCommand(<q-args>)
command! -nargs=? -complete=custom,vizardry#remote#EvolveCompletion Evolve
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

" Vizardry grimoires API {{{1
if !exists("g:VizardryDefaultGitGrimoire")
    let g:VizardryDefaultGitGrimoire='github'
endif

" To add a grimoire (provider):
"  + create a file autoload/vizardry/mygrimoire.vim which implement each of
"   the function described below (for more info see
"   autoload/vizardry/github.vim):
"       + vizardry#mygrimoire#CloneUrl(repo)
"           + return the url for cloning repo
"       + vizardry#mygrimoires#ReadmeUrl(site,name)
"           + return the url to the readme (markdown not HTML)
"       + vizardry#mygrimoires#HelpUrl(site,name)
"           + return the url to the help (vim help something like '/doc/name.txt')
"       + vizardry#mygrimoire#SiteFromOrigin(path)
"           + Return the repo name from the origin url
"       + vizardry#mygrimoires#GenerateQuery(query)
"           + Format query from vizardry format to the grimoire api
"           + return the full query
"  + Add the grimoire name to the list below
"  + Update the documentation to add the grimoire and the search api
"  + Please test before creating a pull request
let s:VizardryAvailableGrimoires = ['github']

function! VizardrySetGrimoire(grimoire)
    let l:grimoire=a:grimoire
    if(match(s:VizardryAvailableGrimoires, '\<'.l:grimoire.'\>') < 0)
        call vizardry#echo("Unknown grimoire '".a:grimoire."'",'e')
        call vizardry#echo("No grimoire defined",'e')
        call vizardry#echo("Vizardry not loaded",'e')
        unlet g:loaded_vizardry
    endif
    let g:VizardryCloneUrl=function('vizardry#'.l:grimoire.'#CloneUrl')
    let g:VizardryReadmeUrl=function('vizardry#'.l:grimoire.'#ReadmeUrl')
    let g:VizardryHelpUrl=function('vizardry#'.l:grimoire.'#HelpUrl')
    let g:VizardrySiteFromOrigin=function('vizardry#'.l:grimoire.'#SiteFromOrigin')
    let g:VizardryGenerateQuery=function('vizardry#'.l:grimoire.'#GenerateQuery')
endfunction

call VizardrySetGrimoire(g:VizardryDefaultGitGrimoire)

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

" Magic {{{1
" TODO: handle in submodule mode
" TODO: Clean code
function! vizardry#magic#MagicName(plugin)
  if a:plugin == '*'
    return g:vizardry#scriptDir.'/magic/magic.vim'
  else
    return g:vizardry#scriptDir.'/magic/magic_'.a:plugin.'.vim'
  endif
endfunction

function! vizardry#magic#BanishMagic(plugin)
  let fileName = vizardry#magic#MagicName(a:plugin)
  call system('mv '.fileName.' '.fileName.'~')
endfunction

function! vizardry#magic#UnbanishMagic(plugin)
  let fileName = vizardry#magic#MagicName(a:plugin)
  call system('mv '.fileName.'~ '.fileName)
endfunction

function! vizardry#magic#Magic(incantation)
  let incantationList = split(a:incantation, ' ')
  if len(incantationList) == 0
    call vizardry#echo("No plugin given",'w')
    return
  endif
  let plugin = incantationList[0]
  let incantation = join(incantationList[1:],' ')

  try
    exec incantation
    call system('mkdir '.g:vizardry#scriptDir.'/magic')
    call system('cat >> '.vizardry#magic#MagicName(plugin), incantation."\n")
  endtry
endfunction

function! vizardry#magic#MagicEdit(incantation)
  exec "edit" vizardry#magic#MagicName(a:incantation)."*"
endfunction

function! vizardry#magic#MagicSplit(incantation)
  exec "split" vizardry#magic#MagicName(a:incantation)."*"
endfunction

function! vizardry#magic#MagicVSplit(incantation)
  exec "vsplit ".vizardry#magic#MagicName(a:incantation)."*"
endfunction



let cpo=save_cpo
" vim:set et sw=2:

" in plugin/jira.vim
if exists('g:loaded_jira') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run our plugin
" command! Jira lua require'jira'.()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_jira = 1

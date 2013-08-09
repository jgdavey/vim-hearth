" hearth.vim - TDD stuff for fireplace.vim
" Author:      Joshua Davey <josh@joshuadavey.com>
" Version:     0.1
"
" Licensed under the same terms as Vim itself.
" ========================================================================

if (exists("g:loaded_hearth") && g:loaded_hearth) || &cp
  finish
endif
let g:loaded_hearth = 1

" Test runners {{{1
function! s:runner()
  " If unset, determine the correct test runner
  if !exists("g:hearth_runner")
    let g:hearth_runner = s:default_runner()
  endif

  let fn = 's:run_command_with_'.g:hearth_runner
  if exists("*".fn)
    return fn
  else
    echo "No such runner: ". g:hearth_runner." . Setting runner to 'vim'."
    let g:hearth_runner = 'vim'
    return ''
  endif
endfunction

function! s:run_command_with_dispatch(command)
  :execute ":Dispatch " a:command
endfunction

function! s:run_command_with_vimux(command)
  return VimuxRunCommand(a:command)
endfunction

function! s:run_command_with_tslime(command)
  let executable = "".a:command
  return Send_to_Tmux(executable."\n")
endfunction

function! s:run_command_with_vim(command)
  exec ':silent !echo;echo;echo;echo;echo;echo;echo;echo'
  exec ':!'.a:command
endfunction

function! s:run_command_with_fireplace(command)
  call fireplace#echo_session_eval(a:command)
endfunction

function! s:run_command_with_echo(command)
  echo 'Command: `'.a:command.'`'
endfunction

function! s:run_command(command)
  return call(s:runner(), [a:command])
endfunction

function! s:default_runner()
  if exists("*VimuxRunCommand")
    return 'vimux'
  elseif exists("*Send_to_Tmux")
    return 'tslime'
  else
    return 'fireplace'
  endif
endfunction
" }}}1

" Test command building {{{1
function! s:clojure_test_file()
  let ns = fireplace#ns()
  if ns =~# '\.test\|-\(test\|spec\)$'
    return { "ns": ns, "file": expand("%") }
  endif

  let alts = [ns.'-test', substitute(ns, '\.', '.test.', ''), ns.'-spec']
  for ns in alts
    let file = tr(ns, '.-', '/_') . ".clj"
    if !empty(fireplace#findresource(file))
      return { "ns": ns, "file": file }
    endif
  endfor
  return {}
endfunction

function! s:run_clojure_test()
  let test = s:clojure_test_file()
  if !empty(test)
    write
    try
      silent Require
      return s:run_command("(clojure.test/run-tests '" . test.ns . ")")
    catch /^.*Clojure:/
      return s:run_command_with_vim("clj " . test.file)
    endtry
  else
    echo "No clojure test file found"
  endif
endfunction
" }}}1

map <Plug>RunClojureTest :<C-U>call <SID>run_clojure_test()<CR>

augroup hearth_map
  autocmd FileType clojure nmap <buffer> <leader>t <Plug>RunClojureTest
augroup END

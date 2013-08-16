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

" Adapters {{{1
function! s:run_command_with_dispatch(command)
  execute "Dispatch " . a:command
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
  exec 'Eval '.a:command
endfunction

function! s:run_command_with_echo(command)
  echo 'Command: `'.a:command.'`'
endfunction
" }}}1
" Test running {{{1
function! s:repl_runner()
  " If unset, determine the correct test runner
  if !exists("g:hearth_repl_runner")
    let g:hearth_repl_runner = s:default_repl_runner()
  endif

  let fn = 's:run_command_with_'.g:hearth_repl_runner
  if exists("*".fn)
    return fn
  else
    echo "No such runner: ". g:hearth_repl_runner." . Setting runner to 'vim'."
    let g:hearth_repl_runner = 'vim'
    return ''
  endif
endfunction

function! s:command_runner()
  " If unset, determine the correct test runner
  if !exists("g:hearth_command_runner")
    let g:hearth_command_runner = s:default_command_runner()
  endif

  let fn = 's:run_command_with_'.g:hearth_command_runner
  if exists("*".fn)
    return fn
  else
    echo "No such runner: ". g:hearth_command_runner." . Setting runner to 'vim'."
    let g:hearth_command_runner = 'vim'
    return ''
  endif
endfunction

function! s:run_command(runner, command)
  return call(a:runner, [a:command])
endfunction

function! s:default_repl_runner()
  if exists("*VimuxRunCommand")
    return 'vimux'
  elseif exists("*Send_to_Tmux")
    return 'tslime'
  else
    return 'fireplace'
  endif
endfunction

function! s:default_command_runner()
  if exists("*VimuxRunCommand")
    return 'vimux'
  elseif exists("*Send_to_Tmux")
    return 'tslime'
  else
    return 'vim'
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

function! s:require(ns)
  let cmd = ("(clojure.core/require '". a:ns .' :reload-all)')
  silent call fireplace#session_eval(cmd)
endfunction

function! s:run_clojure_test_command(test)
  if exists("b:leiningen_root")
    let comm="lein test :only ".a:test.ns
  else
    let comm="clj " . a:test.file
  endif
  return s:run_command(s:command_runner(), comm)
endfunction

function! s:connect_standalone_client(port)
  try
    let connection='nrepl://localhost:'.a:port
    let folder=expand("%:p:h")
    exec 'Connect '.connection . ' ' .folder
    return a:port
  catch
    echo v:errmsg
    return ''
  endtry
endfunction

function! s:portfile()
  if exists('b:leiningen_root')
    let folder = b:leiningen_root
  else
    let folder = expand("%:p:h")
  endif
  let possiblities = [folder.'/target/repl-port', folder.'/target/repl/repl-port' , $HOME."/.lein/repl-port"]

  for file in possiblities
    if filereadable(file)
      return file
    endif
  endfor
  return ''
endfunction

function! s:port()
  let portfile = s:portfile()
  if empty(portfile)
    return ''
  endif

  if getfsize(portfile) > 0
    let port = matchstr(readfile(portfile, 'b', 1)[0], '\d\+')
  else
    return ''
  endif

  if has_key(fireplace#client(), 'connection')
    let fport = fireplace#client().connection.port
    if fport == port
      return port
    endif
  elseif exists('b:leiningen_root')
    return port
  else
    return s:connect_standalone_client(port)
  endif
endfunction

function! s:run_clojure_test()
  let test = s:clojure_test_file()
  if !empty(test)
    write
    try
      if !empty(s:port())
        call s:require(test.ns)
        return s:run_command(s:repl_runner(), "(clojure.test/run-tests '" . test.ns . ")")
      else
        return s:run_clojure_test_command(test)
      endif
    catch
      echo v:errmsg . v:exception
    endtry
  else
    echo "No clojure test file found"
  endif
endfunction
" }}}1
" Mappings {{{1
nnoremap <Plug>RunClojureTest :<C-U>call <SID>run_clojure_test()<CR>

if !exists("g:no_hearth_mappings")
augroup hearth_map
  autocmd FileType clojure map <buffer> <leader>t <Plug>RunClojureTest
augroup END
endif
"}}}1

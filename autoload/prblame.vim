function! prblame#getpr(copy)
  let s:hub_json = ''
  let l:hash = s:getLineBlameHash()
  let l:hubCommand = 'hub api -XGET search/issues '
        \ . '--raw-field '
        \ . '"q=type:pr ' . l:hash . '"'
  let l:hubJob = job_start(l:hubCommand, {
        \ "out_cb" : function("s:job_out_handler"),
        \ "err_cb" : function("s:job_error_handler"),
        \ "exit_cb" : function("s:job_exit_handler", [a:copy, l:hash])
        \ })
endfunction

function! s:getLineBlameHash()
  let l:currentFile = expand('%')
  let l:currentLineNumber = line('.')
  let l:hash_cmd = 'git blame ' 
        \ . l:currentFile
        \ . ' -L ' 
        \ . l:currentLineNumber 
        \ . ',' 
        \ . l:currentLineNumber 
        \ . " | awk '{print $1}'"
  if v:shell_error == 0
    return system(l:hash_cmd)
  else
    throw "Could not get blame hash of current line"
  endif
endfunction

function! s:job_exit_handler(copy, hash, channel, message)
  let l:items = json_decode(s:hub_json)['items']
  if len(l:items) > 0
    let l:url = l:items[0]['html_url']
    if a:copy
      echom("Copied " . l:url . " to the clipboard")
      call setreg("*", l:url)
    else
      silent exec "!open '" . l:url . "'"
    endif
  else
    echom('PR was not found for ' . a:hash)
  endif
endfunction

function! s:job_error_handler(channel, message)
  echoerr(a:message)
endfunction

function! s:job_out_handler(channel, message)
  let s:hub_json = s:hub_json . a:message
endfunction


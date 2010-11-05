if !exists('g:pastubuntu_poster')
  let g:pastubuntu_poster = 'anonymous'
endif

function! s:nr2hex(nr)
  let n = a:nr
  let r = ""
  while n
    let r = '0123456789ABCDEF'[n % 16] . r
    let n = n / 16
  endwhile
  return r
endfunction

function! s:encodeURIComponent(instr)
  let instr = iconv(a:instr, &enc, "utf-8")
  let len = strlen(instr)
  let i = 0
  let outstr = ''
  while i < len
    let ch = instr[i]
    if ch =~# '[0-9A-Za-z-._~!''()*]'
      let outstr = outstr . ch
    elseif ch == ' '
      let outstr = outstr . '+'
    else
      let outstr = outstr . '%' . substitute('0' . s:nr2hex(char2nr(ch)), '^.*\(..\)$', '\1', '')
    endif
    let i = i + 1
  endwhile
  return outstr
endfunction

function! PasteUbuntu(line1, line2)
  let content = join(getline(a:line1, a:line2), "\n")
  let query = [
    \ 'poster=%s',
    \ 'content=%s',
    \ 'syntax=%s',
    \ ]

  let squery = printf(join(query, '&'),
    \ s:encodeURIComponent(g:pastubuntu_poster),
    \ s:encodeURIComponent(content),
    \ s:encodeURIComponent(&ft))
  unlet query
  let file = tempname()
  call writefile([squery], file)
  let quote = &shellxquote == '"' ?  "'" : '"'
  let url = 'http://paste.ubuntu.com/'
  let res = system('curl -i -s -d @'.quote.file.quote.' '.url)
  call delete(file)
  let res = matchstr(split(res, '\(\r\?\n\|\r\n\?\)'), '^location: ')
  let res = substitute(res, '^.*: ', '', '')
  if len(res) > 0
    echo res
  else
    echoerr 'Pasting failed'
  endif
endfunction

command! -nargs=? -range=% PasteUbuntu :call PasteUbuntu(<line1>, <line2>)


function! s:BufferKeywordOmni(findstart, base) abort
  if a:findstart
    " 找補全起始點
    let line = getline('.')
    let col = col('.') - 1
    while col > 0 && line[col - 1] =~ '\k'
      let col -= 1
    endwhile
    return col
  else
    " 提供候選字串
    let res = []
    let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    let words = {}

    for b in buffers
      if bufloaded(b)
        let lines = getbufline(b, 1, '$')
        for l in lines
          for w in split(l, '[ ()"'']\+')
            if w =~# '' . a:base && strlen(w) > 2
              let words[w] = 1
            endif
          endfor
        endfor
      endif
    endfor

    return sort(keys(words))
  endif
endfunction

set omnifunc=<SID>BufferKeywordOmni

" 簡易的補全
im <C-o><C-o> <C-x><C-o>
im <C-o><C-l> <C-x><C-f>

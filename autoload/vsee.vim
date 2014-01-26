" Example of how to use:
" autocmd FileType javascript inoremap <silent> <S-CR> <ESC>:call vsee#vimShiftEnterSemicolonOrComma()<CR>
" autocmd FileType javascript nmap <silent> <S-CR> <ESC>:call vsee#vimShiftEnterSemicolonOrComma()<CR>

" ==============
" Main function:
" ==============

function! vsee#vimShiftEnterSemicolonOrComma()

    let b:originalLineNum = line('.')
    let b:originalCursorPosition = getpos('.')

    let b:currentLine = getline(b:originalLineNum)
    let b:nextLine = s:getNextNonBlankLine(b:originalLineNum)
    let b:prevLine = s:getPrevNonBlankLine(b:originalLineNum)

    let b:prevLineLastChar = matchstr(b:prevLine, '.$')
    let b:nextLineLastChar = matchstr(b:nextLine, '.$')

    let b:nextLineFirstChar = matchstr(s:strip(b:nextLine), '^.')

    let b:surroundings = strpart(getline('.'), col('.') -1, 2)

    "{|} 
    "->
    "{
    "   |
    "};
    if b:surroundings == "{}"
        return s:semicolonEnterBetweenDelimiters()
    endif

    if b:prevLineLastChar == '{'
        " function hello(params) {
        "   var foo = params[0|]
        " } 
        " ->
        " function hello(params) {
        "   var foo = params[0];
        "   |
        " }
        if s:lineContainsFunctionDeclaration(b:prevLine)
            return s:semicolonEnterAfter()
        " {
        "   foo: bar|
        " } 
        " ->
        " {
        "   foo:bar,
        "   |
        " }
        elseif b:nextLineFirstChar == '}'
            return s:commaEnterAfter()
        endif

    " (
    "   foo|
    " ) 
    " ->
    " (
    "   foo,
    "   |
    " )
    elseif b:prevLineLastChar == '('
        if b:nextLineFirstChar == ')'
            return s:commaEnterAfter()
        endif
     
    " [
    "   foo|
    " [
    " ->
    " [
    "   foo,
    "   |
    " [
    elseif b:prevLineLastChar == '['
        if b:nextLineFirstChar == ']'
            return s:commaEnterAfter()
        endif

    " foo,
    " bar|
    " ->
    " foo,
    " bar,
    " |
    elseif b:prevLineLastChar == ','
        return s:commaEnterAfter()
        
    " foo();
    " bar(|)
    " ->
    " foo();
    " bar();
    " |
    elseif b:prevLineLastChar == ';'
        return s:semicolonEnterAfter()

    endif

    return
endfunction

" =================
" Helper functions:
" =================

function! s:commaEnterAfter()
    exec("s/[,;]\\?$/,/e")
    call feedkeys("A\<CR>")
    return
endfunction

function! s:semicolonEnterAfter()
    exec("s/[,;]\\?$/;/e")
    call feedkeys("A\<CR>")
    return
endfunction

function! s:semicolonEnterBetweenDelimiters()
    exec("s/[,;]\\?$/;/e")
    call setpos('.', b:originalCursorPosition)
    call feedkeys("a\<CR>")
    return
endfunction

function! s:strip(string)
    return substitute(a:string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! s:getNextNonBlankLineNum(lineNum)
    return s:getFutureNonBlankLineNum(a:lineNum, 1, line('$'))
endfunction

function! s:getPrevNonBlankLineNum(lineNum)
    return s:getFutureNonBlankLineNum(a:lineNum, -1, 1)
endfunction

function! s:getNextNonBlankLine(lineNum)
    return getline(s:getNextNonBlankLineNum(a:lineNum))
endfunction

function! s:getPrevNonBlankLine(lineNum)
    return getline(s:getPrevNonBlankLineNum(a:lineNum))
endfunction

function! s:lineContainsFunctionDeclaration(line)
    return s:strip(a:line) =~ '^.*function.*(.*$'
endfunction

function! s:getFutureNonBlankLineNum(lineNum, direction, limitLineNum)
    if (a:lineNum == a:limitLineNum)
        return ''
    endif

    let l:futureLineNum = a:lineNum + (1 * a:direction)
    let l:futureLine = s:strip(getline(l:futureLineNum))

    if (l:futureLine == '')
        return s:getFutureNonBlankLineNum(l:futureLineNum, a:direction, a:limitLineNum)
    endif

    return l:futureLineNum
endfunction
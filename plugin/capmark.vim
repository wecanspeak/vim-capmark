"      PLUGIN: capmark.vim                          "{{{1
" DESCRIPTION: Dashboard of capital mark (A~Z)
"     VERSION: 0.0.1
"     LICENSE: MIT. Copyright (c) Enzo Wang <wecanspeak@hotmail.com>
" SIDE EFFECT:
"     (1) no longer keep track of unused capital mark in viminfo file
"     (2) default change updatetime to 1000
"

" Initialize ================================= {{{1
"
" {{{2
"
" global setting
if exists("g:loadedCapmark")
    finish
endif
if v:version < 700
    echoerr "CapMark: this plugin requires at least vim 7"
    finish
endif
let g:loadedCapmark = 1

if !exists("g:capmarkStoreFile")
  let g:capmarkStoreFile = $HOME."/.vim-capmark"
endif

if !exists("g:capmarkViminfoPath")
  let g:capmarkViminfoPath = $HOME."/.viminfo"
endif
if !exists("g:capmarkUpdatetime")
  let g:capmarkUpdatetime = 1000
endif

scriptencoding utf-8

" apply global setting
exec "set updatetime=" . g:capmarkUpdatetime

augroup capmarkAutoGroup
  autocmd!
  autocmd CursorHold * call s:ActionMarkMenuRefresh()
augroup END

" script variables
let s:aToZMarkSymbol = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
let s:markDict = {}


" }}}2
"
" ============================================
" Main Functions ============================= {{{1
"
function! s:CapmarkDbFileDefault() " {{{2
  " Description: create or reset capmark database file to default
  " Arguments: none
  " Return: none

  if !filereadable(g:capmarkStoreFile)
    "echo "capmark file do not exsit"
  endif
  let defaultContent = [
      \ 'A:', 'B:', 'C:', 'D:', 'E:', 'F:', 'G:', 'H:', 'I:', 'J:',
      \ 'K:', 'L:', 'M:', 'N:', 'O:', 'P:', 'Q:', 'R:', 'S:', 'T:',
      \ 'U:', 'V:', 'W:', 'X:', 'Y:', 'Z:']
  " create or reset to default file
  call writefile(defaultContent, g:capmarkStoreFile)
endfunction

function! s:MarkInfoResetForMark(mark)  "{{{2
  " Description: reset specific mark information for this plugin
  " Arguments: mark - assigned mark
  " Return: none

  let s:markDict[a:mark].used = 0
  let s:markDict[a:mark].line = 0
  let s:markDict[a:mark].filepath = ""
  let s:markDict[a:mark].filename = ""
  let s:markDict[a:mark].bookmark = ""
  call s:DbFileWrite(a:mark, "")
endfunction

function! s:MarkInfoGet()  " {{{2
  " Description: get mark info dictionay
  "       mark info dictionar =
  "       {'A': {
  "              'used': 1 or 0,
  "              'markLineNum' : line number of mark,
  "              'filepath' : absoulute file path of mark buffer,
  "              'filename' : filename,
  "              'bookmark': bookmark name
  "             },
  "        'B': {
  "              ....
  "             },
  "        ...
  "        'Z': {
  "              'used': 1 or 0,
  "              'markLineNum' : line number of mark,
  "              'filepath' : absoulute file path of mark buffer,
  "              'filename' : filename,
  "              'bookmark': bookmark name
  "             }
  "        }
  "
  " Arguments: none
  " Return: dictionary containing all mark information

  let aToZMarkSymbol = s:aToZMarkSymbol
  let l:markDict = {}

  for mksymbol in split(aToZMarkSymbol, '\zs')
    let [ bufNum, markLineNum, colNum, off ] = getpos("'" . mksymbol)
    let l:markDict[mksymbol] = {}
    let l:markDict[mksymbol].used = (markLineNum != 0) ? 1 : 0
    let l:markDict[mksymbol].line = markLineNum
    if (l:markDict[mksymbol].used)
      let l:markDict[mksymbol].filepath = expand( "#" . bufNum . ":p")
      let l:markDict[mksymbol].filename = expand( "#" . bufNum . ":p:t")
    else
      let l:markDict[mksymbol].filepath = ""
      let l:markDict[mksymbol].filename = ""
    endif
  endfor

  let bookmarkDict = s:DbFileRead()
  for [key, value] in items(bookmarkDict)
    let l:markDict[key].bookmark = value
  endfor

  return l:markDict
endfunction

function! s:MarkMenuRender(markDict)  " {{{2
  " Description: render mark menu
  " Arguments: markDict - mark info dictionary
  " Return: none

  let maxBkLen = s:MaxBookmarkLenGet()
  let maxFnLen = s:MaxFilenameLenGet(a:markDict)
  let bookmarkDashLine = ""
  let filenameDashLine = ""
  let headerSpace = ""

  " adjust header and dash line
  if (maxBkLen < 9)
    let maxBkLen = 8
  endif
  if (maxFnLen < 5)
    let maxFnLen = 4
  endif
  let i = 0
  while i < maxBkLen
    let bookmarkDashLine .= "-"
    let i += 1
  endwhile
  let i = 0
  while i < maxFnLen
    let filenameDashLine .= "-"
    let i += 1
  endwhile
  let i = 0
  while i < (maxBkLen - 8)
    let headerSpace .= " "
    let i += 1
  endwhile

  " render menu
  let lineCnt = 1
  call setline(lineCnt,"mark  bookmark" . headerSpace . "  file")
  let lineCnt += 1
  call setline(lineCnt,"----  " .  bookmarkDashLine . "  " .filenameDashLine)
  for mksymbol in keys(a:markDict)
    if (a:markDict[mksymbol].used == 1)
      let bookmarkSpace = ""
      let bkLen = strlen(a:markDict[mksymbol].bookmark)
      let lineCnt+=1

      let i = 0
      while i < (maxBkLen - bkLen)
        let bookmarkSpace .= " "
        let i += 1
      endwhile
      let line = "  " . mksymbol . "   " . a:markDict[mksymbol].bookmark .
               \  bookmarkSpace . "  " . a:markDict[mksymbol].filename
      cal setline(lineCnt, line)
    endif
  endfor
endfunction

function! s:CapmarkWinOpen()  " {{{2
  " Description: create mark dashboard window
  " Arguments: none
  " Return: none

  if !filereadable(g:capmarkStoreFile)
    call s:CapmarkDbFileDefault()
  endif

  if (s:IsWindowOpened("CapMark") == 1)
    echo "CapMark has been opened."
    return
  endif

  call s:RecordSrcWin()

  let markDict = s:MarkInfoGet()
  let s:markDict = deepcopy(markDict)

  new
  exec "file CapMark"
  setlocal bufhidden=wipe buftype=nofile nonu fdc=0
  call s:MarkMenuRender(markDict)
  setlocal filetype=capmark
  setlocal nomodifiable
  setlocal cursorline
  setlocal noswapfile
  let cnt = s:MarkUsedNumGet(markDict)
  let cnt += 2
  exec "resize " . cnt
  call s:ActionMap()
endfunction

function! s:CapmarkWinClose()  " {{{2
  " Description: close capmark window
  " Arguments: none
  " Return: none

  if (s:IsWindowOpened("CapMark") == 0) | return | endif

  let isin = s:IsAtCapmarkWindow()
  if (isin == 0)
    call s:RecordSrcWin()
  endif
  exec "bdelete! CapMark"
  call s:GoToSrcWin()
endfunction

function! s:CapmarkWinToggle()  " {{{2
  " Description: toggle capmark window
  " Arguments: none
  " Return: none

  let isopen = s:IsWindowOpened("CapMark")
  if (isopen == 1)
    call s:CapmarkWinClose()
  else
    call s:CapmarkWinOpen()
  endif
endfunction()

function! s:DbFileWrite(mark, bookmark) " {{{2
  " Description: write capmark databasefile
  " Arguments: mark - capital mark
  "            bookmark - bookmark without wrapping
  " Return: none

  if a:mark !~# '\u'
    echo "[CapMark] input mark is not capital mark"
  endif

  let markInfo = s:DbFileRead()
  let markInfo[a:mark] = a:bookmark
  let newContent = []
  for [key, value] in items(markInfo)
    let writeline = key . ":" . value
    call add(newContent, writeline)
  endfor
  call writefile(newContent, g:capmarkStoreFile)
endfunction

function! s:DbFileRead() " {{{2
  " Description: get the capmark database inforamtion
  " Arguments: none
  " Return: dictionary with format
  "         {'A': '"bookmark1"',
  "          'B': '"BOOKMARK2"',
  "           ...
  "          'Y': '"tmpbookmark",
  "          'Z': '"iambookmark"'}

  if !filereadable(g:capmarkStoreFile) | return | endif

  let db = {}
  for line in readfile(g:capmarkStoreFile, '', 26)
    " tranfer 'A:"bookmark"' to ['A:', '"bookmark"']
    let lineList = split(line, '^\u:\{1}\zs')
    let len = len(lineList)
    let mark = strpart(lineList[0], 0, 1)
    " fix empty bookmark name setting
    if (len <= 1)
      let db[mark] = ""
    else
      let bookmark = lineList[1]
      "echo " mark  " . mark . " with bookmark " . bookmark
      let db[mark] = bookmark
    endif
  endfor
  return db
endfunction

function! s:ActionMarkMenuRefresh()   " {{{2
  " Description: refresh mark menu
  " Arguments: none
  " Return: none

  "echom "ActionMarkMenuRefresh() is calling"
  if (s:IsWindowOpened("CapMark") == 0) | return | endif

  let isin = s:IsAtCapmarkWindow()
  if (isin == 0)
    call s:RecordSrcWin()
    call s:GoToWin(bufwinnr("CapMark"))
  endif

  " in case remove mark not in capmark window, need to update .viminfo
  let markDict = s:MarkInfoGet()
  let rmList = s:RemovedMarkGet(s:markDict, markDict)
  for mark in rmList 
    call s:RemoveFileMarkerInViminfo(mark)
  endfor
  " in case relocate mark
  let chList = s:ChangedMarkGet(s:markDict, markDict)
  for mark in chList 
    call s:ResetBookmark(mark)
  endfor

  let s:markDict = deepcopy(markDict)

  setlocal modifiable
  let cursor = getpos('.')
  silent 1,$ delete _
  call s:MarkMenuRender(markDict)
  setlocal nomodifiable
  " TODO: do not resize when bottomed window 
  "let cnt = s:MarkUsedNumGet(markDict)
  "let cnt += 2
  "exec "resize " . cnt

  call setpos('.', cursor)

  if (isin == 0)
    call s:GoToSrcWin()
  endif
endfunction

function! s:ActionMap() " {{{2
  " Description: map mark menu action
  " Arguments: none
  " Return: none

  nnoremap <buffer> <silent> b       :call <SID>ActionBookmarkAdd()<CR>
  nnoremap <buffer> <silent> d       :call <SID>ActionMarkRemove()<CR>
  nnoremap <buffer> <silent> D       :call <SID>ActionBookmarkReset()<CR>
  nnoremap <buffer> <silent> t       :call <SID>ActionMarkJumpTo()<CR>
  nnoremap <buffer> <silent> <Enter> :call <SID>ActionMarkJumpTo()<CR>
  nnoremap <buffer> <silent> <C-N>   :call <SID>ActionMarkTraverseForward()<CR>
  nnoremap <buffer> <silent> <C-P>   :call <SID>ActionMarkTraverseBackword()<CR>
  nnoremap <buffer> <silent> R       :call <SID>ActionMarkMenuRefresh()<CR>

endfunction

function! <SID>ActionBookmarkAdd()  " {{{2
  " Description: create bookmark
  " Arguments: none
  " Return: none

  if (s:IsValidMarkLine() == 0) | return | endif

  if !filereadable(g:capmarkStoreFile)
    call s:CapmarkDbFileDefault()
  endif

  let mark = getline('.')[2]
  let markDict = s:MarkInfoGet()
  call inputsave()
  let bookmarkName = input('For "' . mark . '", add bookmark name: ', markDict[mark].bookmark)
  call inputrestore()
  call s:DbFileWrite(mark, bookmarkName)
  call s:ActionMarkMenuRefresh()
endfunction

function! <SID>ActionMarkFirstAvailableAdd() " {{{2
  " Description: add next available mark. for example:
  "              'A','B', and 'E' are used marks, next available mark is 'C'
  " Arguments: none
  " Return: none
  
  let markDict = s:MarkInfoGet()
  for key in split(s:aToZMarkSymbol, '\zs')
    if (markDict[key].used == 0) 
      exec "normal! m" . key
      return
    endif
  endfor
endfunction

function! <SID>ActionMarkJumpTo() " {{{2
  " Description: jump to mark location and switch cursor
  " Arguments: none
  " Return: none

  if (s:IsValidMarkLine() == 0) | return | endif

  if !filereadable(g:capmarkStoreFile)
    call s:CapmarkDbFileDefault()
  endif

  let markSymbol = getline('.')[2]
  silent call s:GoToSrcWin()
  try
    exec "normal! '" . markSymbol
  catch /^Vim\%((\a\+)\)\=:E37/
    echoerr "[CapMark] Please save file first."
  catch /^Vim\%((\a\+)\)\=:E325/
    echom "[CapMark] E325 (swp file existed) is caught"
  endtry
  call s:RecordSrcWin()
endfunction

function! <SID>ActionMarkTraverseForward() " {{{2
  " Description: forward quickview mark location but not jump to
  " Arguments: none
  " Return: none

  exec "normal j"

  if (s:IsValidMarkLine() == 0) | return | endif

  call s:ActionMarkJumpTo() " concern swp file, never use silent command.
  silent normal! zz
  call s:GoToWin(bufwinnr("CapMark"))
endfunction

function! <SID>ActionMarkTraverseBackword() " {{{2
  " Description: backword quickview mark location but not jump to
  " Arguments: none
  " Return: none

  exec "normal k"

  if (s:IsValidMarkLine() == 0) | return | endif

  call s:ActionMarkJumpTo() " concern swp file, never use silent command.
  silent normal! zz
  call s:GoToWin(bufwinnr("CapMark"))
endfunction

function! <SID>ActionMarkRemove() " {{{2
  " Description: remove mark
  " Arguments: none
  " Return: none

  "echom "ActionMarkRemove() is calling"
  if (s:IsValidMarkLine() == 0) | return | endif

  if !filereadable(g:capmarkStoreFile)
    call s:CapmarkDbFileDefault()
  endif

  let markSymbol = getline('.')[2]
  "echom "remove mark symbol is " . markSymbol
  call s:ResetMarkInfo(markSymbol)
  call s:ActionMarkMenuRefresh()
endfunction

function! <SID>ActionMarkRemoveAll() " {{{2
  " Description: remove all used mark
  " Arguments: none
  " Return: none

  let markDict = s:MarkInfoGet()
  for key in split(s:aToZMarkSymbol, '\zs')
    if (markDict[key].used == 1) 
      call s:ResetMarkInfo(key)
    endif
  endfor
  call s:ActionMarkMenuRefresh()
endfunction

function! <SID>ActionBookmarkReset() " {{{2
  " Description: reset bookmark
  " Arguments: none
  " Return: none
  
  call s:CapmarkDbFileDefault()
endfunction

" }}}2
"
" ============================================
" Utility Functions  ========================= {{{1
"
function! s:MaxBookmarkLenGet() " {{{2
  " Description: get maximum string length of bookmarks
  " Arguments: none
  " Return: maximum length of bookmarks

  let bookmarkDict = s:DbFileRead()
  let len = 0
  for [key, value] in items(bookmarkDict)
    let tmp = strdisplaywidth(value)
    if (tmp > len)
      let len = tmp
    endif
  endfor
  return len
endfunction

function! s:MaxFilenameLenGet(markDict) " {{{2
  " Description: get maximum string length of filename
  " Arguments: none
  " Return: maximum length of filename

  let len = 0
  for key in keys(a:markDict)
    let tmp = strdisplaywidth(a:markDict[key].filename)
    if (tmp > len)
      let len = tmp
    endif
  endfor
  return len
endfunction

function! s:MarkUsedNumGet(markDict) " {{{2
  " Description: get number of used mark
  " Arguments: markDict - mark info dictionary
  " Return: number of used marks

  let cnt = 0
  let aToZMarkSymbol = s:aToZMarkSymbol
  for mksymbol in split(aToZMarkSymbol, '\zs')
    if (a:markDict[mksymbol].used == 1)
      let cnt += 1
    endif
  endfor
  return cnt
endfunction

function! s:IsValidMarkLine() " {{{2
  " Description: check cursour line is on mark line or header section
  " Arguments: none
  " Return: 1 - mark line
  "         0 - header section

  let currLine = line(".")
  if (currLine > 2)
    return 1
  else
    return 0
  endif
endfunction

function! s:IsWindowOpened(bufferName) " {{{2
  " Description: check window opened
  " Arguments: bufferName - buffer name
  " Return: 1 - window opened
  "         0 - window closed

  "echo "IsWindowOpened is calling"

  let winnr = bufwinnr(a:bufferName)
  if l:winnr != -1 | return 1
  else | return 0 | endif
endfunction

function! s:IsAtCapmarkWindow() " {{{2
  " Description: check now cursor location in capmark window
  " Arguments: none
  " Return: 1 - now in capmark window
  "         0 - otherwise

  let capmarkWinnr = bufwinnr("CapMark")
  let nowWinnr = winnr()
  if (nowWinnr != capmarkWinnr)
    return 0
  else
    return 1
  endif
endfunction

function! s:RemovedMarkGet(oldMarkDict, newMarkDict) " {{{2
  " Description: get removed mark by comparing old and new mark dictionary.
  " Arguments: oldMarkDict - old mark info
  "            newMarkDict - new mark info
  " Return: list containing removed mark. for example, ['A', 'E'].

  let rmList=[]
  for key in split(s:aToZMarkSymbol, '\zs')
    if ((a:oldMarkDict[key].used == 1) && (a:newMarkDict[key].used == 0))
      "echom "removed mark is " . key
      call add(rmList, key)
    endif
  endfor
  return rmList
endfunction

function! s:ChangedMarkGet(oldMarkDict, newMarkDict) " {{{2
  " Description: get changed mark (not removed) by comparing old and new mark dictionary.
  " Arguments: oldMarkDict - old mark info
  "            newMarkDict - new mark info
  " Return: list containing changed mark. for example, ['A', 'E'].

  let chList=[]
  for key in split(s:aToZMarkSymbol, '\zs')
    if ((a:oldMarkDict[key].line != a:newMarkDict[key].line) || 
        \ (a:oldMarkDict[key].filepath !=# a:newMarkDict[key].filepath) ||
        \ (a:oldMarkDict[key].filename !=# a:newMarkDict[key].filename))
      "echom "changed mark is " . key
      call add(chList, key)
    endif
  endfor
  return chList
endfunction

function! s:RecordSrcWin() " {{{2
  " Description: record the source window which open the capmark window
  " Arguments: none
  " Return: none
  " Note: refer to tagbar.vim

  let w:triggerWin = 1
endfunction

function! s:GoToWin(winnr) " {{{2
  " Description: go to window
  " Arguments: winnr
  " Return: none

  exec a:winnr . 'wincmd w'
endfunction

function! s:GoToSrcWin() " {{{2
  " Description: go to source window
  " Arguments: winnr
  " Return: none
  " Note: refer to tagbar.vim

  for window in range(1, winnr('$'))
    call s:GoToWin(window)
    if exists('w:triggerWin')
      "echom "Go to window " . window
      unlet w:triggerWin
      break
    endif
  endfor
endfunction

function! s:RemoveFileMarkerInViminfo(mark) " {{{2
  " Description: remove capital mark information in viminfo file
  " Arguments: mark - capital mark
  " Return: none

  " now use brutal method, read each line, skip matched line, then write line
  " TODO: use more efficient method
  let pattern = "^'" . a:mark . "\\s"
  let writeList = []
  for line in readfile(g:capmarkViminfoPath)
    if line !~ pattern | call add(writeList, line) | endif
  endfor
  call writefile(writeList, g:capmarkViminfoPath)
endfunction

function! s:ResetMarkInfo(mark) " {{{2
  " Description: reset mark info 
  " Arguments: mark - capital mark
  " Return: none
  
  " TODO
  " need workaround for disabling keeping A~Z file mark in .viminfo
  " ---- workaround start
  exec "delmarks " . a:mark
  call s:RemoveFileMarkerInViminfo(a:mark) 
  " ---- workaround end
  call s:MarkInfoResetForMark(a:mark)
endfunction

function! s:ResetBookmark(mark) " {{{2
  " Description: reset bookmark for mark
  " Arguments: mark - capital mark
  " Return: none

  "echo "Reset bookmark for mark " . a:mark
  let pattern = "^" . a:mark 
  let writeList = []
  for line in readfile(g:capmarkStoreFile)
    if (line !~ pattern)
      call add(writeList, line) 
    else
      let c = a:mark . ":"
      call add(writeList, c)
    endif
  endfor
  call writefile(writeList, g:capmarkStoreFile)
endfunction

" }}}2
"
" ============================================
" Commands =================================== {{{1
"
command! CapmarkOpen           :call s:CapmarkWinOpen()
command! CapmarkClose          :call s:CapmarkWinClose()
command! CapmarkToggle         :call s:CapmarkWinToggle()
command! CapmarkBookmarkReset  :call s:ActionBookmarkReset()
command! CapmarkMarkNext       :call s:ActionMarkFirstAvailableAdd()
command! CapmarkResetAll       :call s:ActionMarkRemoveAll()

" }}}2
"
" ============================================

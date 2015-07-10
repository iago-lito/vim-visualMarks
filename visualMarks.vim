" 2015-07-09: This small vimScript just wants to provide the following feature:
" - - - Save visually selected blocks by associating them to custom marks. - - -
" Just like with ma in normal mode, to mark the position of the cursor, then `a
" to retrieve it, you would mark visually selected areas then get them back in a
" few keystrokes.
"
" I shall thank here Steven Hall for having launched this on StackOverflow :)
" http://stackoverflow.com/q/31296394/3719101
" Feel free to contribute of course.
"
" The way this works so far:
"   - the global variable g:visualMarks is a dictionnary whose keys are the
"     marks and whose entries are the position of the start/end of the
"     selection.
"   - the function VisualMark(), when called from visual mode, waits for input
"     from the user (which mark to use), and saves the current coordinates of
"     the selected area to the dictionnary.
"   - the function GetVisualMark(), when called from normal mode, waits for
"     input from the user (which mark to retrieve), then enters visual mode and
"     retrieves the previously marked selection.
"
" Things that are still missing, in my opinion:
" TODO:
"   - make the warning softer?
"   - utility functions to clean the dictionnary, change filenames, move files,
"     etc.
"   - make all this a Pathogen-friendly?
" DONE:
"   - use and save/read a `dictionnary`
"   - warn the user when trying to get a unexistent mark
"   - make the marks specific to each file.
"   - merged hallzy-master
"   - find the file in one's home whatever name one has ;)
"   - corrected a bug due to unconsistent variable names `mark` vs `register`
" This DOES begin to look like something! :)

" Here we go.

" A kind utility function to save a vimScript variable to a file? "{{{
function! SaveVariable(var, file)
    " the `writefile` function only take lists, so wrap it in a list
    call writefile([string(a:var)], a:file)
endfun
" And its other side: restore a variable from a file:
function! ReadVariable(file)
    " don't forget to unwrap it!
    let recover = readfile(a:file)[0]
    " watch out, it is so far just a string, make it what it should be:
    execute "let result = " . recover
    return result
endfun
"}}}

" the file where the big dictionnary will be stored.
let g:filen = $HOME . "/.vim-vis-mark"
" the big dictionnary itself:
" Its organization is simple:
"  - each *key* is the full path to a file
"  - each *entry* is also a dictionnary, for which:
"      - each *key* is a mark identifier
"      - each *entry* is the position of the recorded selection, a list:
"           - [startLine, startColumn, endLine, endColumn]
if filereadable(g:filen)
    let g:visualMarks = ReadVariable(g:filen)
else
    " create the file if it does not exist
    let g:visualMarks = {}
    call SaveVariable(g:visualMarks, g:filen)
endif

" This is the function setting a mark, called from visual mode.
function! VisualMark() "{{{
    " get the current file path
    let filePath = expand('%:p')

    " get the mark ID
    let mark = GetVisualMarkInput("mark selection ")

    " retrieve the position starting the selection
    normal! gv
    let [startLine, startCol] = [line('.'), col('.')]

    " retrieve the position ending the selection
    normal! o
    let [endLine, endCol] = [line('.'), col('.')]

    " update the dictionnary:
    " Initialize the file entry if didn't existed yet:
    if !has_key(g:visualMarks, filePath)
        let g:visualMarks[filePath] = {}
    endif
    " and fill it up!
    let g:visualMarks[filePath][mark] = [startLine, startCol, endLine, endCol]

    " and save it to the file. But I am sure we don't need to do this each time.
    call SaveVariable(g:visualMarks, g:filen)
endfun
"}}}

" This is the function retrieving a marked selection, called from normal mode.
function! GetVisualMark() "{{{
    " get the current file path
    let filePath = expand('%:p')

    " get the mark ID
    let mark = GetVisualMarkInput("restore selection ")

    " retrieve the latest version of the dictionnary. (No need each time?)
    let g:visualMarks = ReadVariable(g:filen)

    " check whether the mark has already been recorded, then put the flag down.
    let noSuchMark = 1
    if has_key(g:visualMarks, filePath)
        if has_key(g:visualMarks[filePath], mark)
            let noSuchMark = 0
        endif
    endif

    if noSuchMark
        echom "no Such mark " . mark . " for file " . filePath
    else
        " Then we can safely get back to this selection!
        let coordinates = g:visualMarks[filePath][mark]
        "move to the start pos, go to visual mode, and go to the end pos
        call cursor(coordinates[0], coordinates[1])
        "enter visual mode to select the rest
        exec "normal! v"
        call cursor(coordinates[2], coordinates[3])
    endif

    " And that's it! :)
endfun
"}}}

" Here is the function retrieving user input characterizing the mark. It returns
" an appropriate key for the dictionnary.
" For now, it uses `input` with a custom prompt message, and this is why it
" requires the enter key to be pressed
" TODO: would be great with no need to hit enter
function! GetVisualMarkInput(prompt) "{{{
    echom a:prompt
    let mark = nr2char(getchar())
    return mark
endfun
"}}}

" And we're done. Now map it to something cool:
vnoremap m <esc>:call VisualMark()<cr>
nnoremap < :call GetVisualMark()<cr>

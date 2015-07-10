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
"   - handle the case where the user wants to retrieve a mark that has not been
"     defined yet. (you get an error yet if you do so)
"   - make it possible to get the input in a way that don't need the <CR> key to
"     be pressed (a mark will then consists in a fixed number of characters. 1
"     would be enough to me.)
"   - make the dictionnary local to a buffer.
"   - make the marks persistent once Vim is closed (save'em to a file)

" Here we go.

" This is the dictionnary. Each mark will be stored as:
" {<mark ID>: [line number (start), column (start), line (end), column (end)]}
let g:visualMarks={}

" This is the function setting a mark, called from visual mode.
function! VisualMark() "{{{

    " get the mark ID
    let mark = GetVisualMarkInput("mark selection ")

    " retrieve the position starting the selection
    normal! gv
    let [startLine, startColumn] = [line('.'), col('.')]

    " retrieve the position ending the selection
    normal! o
    let [endLine, endColumn] = [line('.'), col('.')]

    " save the mark!
    exec "let g:visualMarks.".mark
                \."=[startLine, startColumn, endLine, endColumn]"

    " exit visual mode
    exec "normal! \<esc>"

endfun
"}}}

" This is the function retrieving a marked selection, called from normal mode.
function! GetVisualMark() "{{{

    " get the mark ID
    let mark = GetVisualMarkInput("restore selection ")

    " restore the corresponding selection:
    exec "let [startLine, startColumn, endLine, endColumn]"
                \ ." = g:visualMarks.".mark
    call setpos('.', [0, startLine, startColumn, 0])
    normal! v
    call setpos('.', [0, endLine, endColumn, 0])

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


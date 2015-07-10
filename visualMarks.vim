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

" This is the function setting a mark, called from visual mode.
function! VisualMark() "{{{

    " get the mark ID
    let mark = GetVisualMarkInput("mark selection ")

    " retrieve the position starting the selection
    normal! gv
    let [startLine, startCol] = [line('.'), col('.')]

    " retrieve the position ending the selection
    normal! o
    let [endLine, endCol] = [line('.'), col('.')]

    let output = register . " " . startLine . " " . startCol . " " . endLine . " " . endCol

    for line in readfile("/home/steven/.vim-vis-mark", " ")
      "If the first character of the line is the mark, then delete it from the
      "list because we are about to add a new definition for that mark
      if line[0] =~ mark
        new ~/.vim-vis-mark
        exec "normal! /^" . register . ".\\+\<cr>dd"
        :wq
      endif
    endfor
    "Add the new mark definition to the file
    new ~/.vim-vis-mark
    put =output
    :wq
  endfun
"}}}

" This is the function retrieving a marked selection, called from normal mode.
function! GetVisualMark() "{{{
    " get the mark ID
    let mark = GetVisualMarkInput("restore selection ")

    "get pos from file
    for line in readfile("/home/steven/.vim-vis-mark", " ")
      "if the register value is the firt character on the line
      if line[0] =~ mark
        "This creates a list of the 5 different values saved in the file
        let coordinates = split(line)
        "move to the start pos, go to visual mode, and go to the end pos
        call cursor(coordinates[1], coordinates[2])
        "enter visual mode to select the rest
        exec "normal! v"
        call cursor(coordinates[3], coordinates[4])
      endif
    endfor
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


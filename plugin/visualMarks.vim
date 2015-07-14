" Vim global plugin for saving and recovering visually selected text areas
" Last Change:	2015/07/13
" Maintainer:	Iago-lito <iago.bonnici@gmail.com>
" License:	This file is placed under the GNU PublicLicense 2.

" lines for handling line continuation, according to :help write-plugin<CR>
let s:save_cpo = &cpo
set cpo&vim
" make it possible for the user not to load the plugin, same source
if exists("g:loaded_visualMarks")
    finish
endif
let g:loaded_visualMarks = 1

" This small vimScript just wants to provide the following feature:
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
"   - the no-such-mark warning still requires the user to press Enter. Is it a
"     good reason to remove the prompts before calling `nchar`?
"   - utility functions to clean the dictionnary, change filenames, move files,
"     etc. (truly needed?)
"   - make all this a Pathogen-friendly Vim plugin? (I have no idea how to do)
"   - make the functions local to the script (s:, <SID>), handle <Plug>
"   - avoid saving and reading the dictionnary on each call to the functions.
"     Better use an `autocmd VimEnter, VimLeave`? Yet it would be less safe?
"     Does it slow the process down that much?
"   - save the type of visual mode? (v, V, <c-v>) (might be some more work since
"     3 positions are needed to save a <c-v> block)
"   - handle the un-file-named buffer case.
" DONE:
"   - use and save/read a `dictionnary`
"   - warn the user when trying to get a unexistent mark
"   - make the marks specific to each file.
"   - merged hallzy-master
"   - find the file in one's home whatever name one has ;)
"   - corrected a bug due to unconsistent variable names `mark` vs `register`
"   - corrected an inversion of `start` and `end` of the selection
"   - when restoring selection in a folded block, recursively unfold to show it
"   - choose whether or not leaving visual mode after having set a mark
"   - make the warning softer
"   - optional file location for the file
"
" This DOES begin to look like something! :)

" Here we go.

" A kind utility function to save a vimScript variable to a file? "{{{
function! s:SaveVariable(var, file)
    " the `writefile` function only take lists, so wrap it in a list
    call writefile([string(a:var)], a:file)
endfun
" And its other side: restore a variable from a file:
function! s:ReadVariable(file)
    " don't forget to unwrap it!
    let recover = readfile(a:file)[0]
    " watch out, it is so far just a string, make it what it should be:
    execute "let result = " . recover
    return result
endfun
" Cool, isn't it? Thank you VanLaser from the Stack!
" http://stackoverflow.com/q/31348782/3719101
"}}}

" Options:
" the file where the big dictionnary will be stored.
let g:visualMarks_marksFile = $HOME . "/.vim-vis-mark"
let g:visualMarks_exitVModeAfterMarking = 1

let g:filen = g:visualMarks_marksFile
" the big dictionnary itself:
" Its organization is simple:
"  - each *key* is the full path to a file
"  - each *entry* is also a dictionnary, for which:
"      - each *key* is a mark identifier
"      - each *entry* is the position of the recorded selection, a list:
"           - [startLine, startColumn, endLine, endColumn]
if filereadable(g:filen)
    let g:visualMarks = s:ReadVariable(g:filen)
else
    " create the file if it does not exist
    let g:visualMarks = {}
    call s:SaveVariable(g:visualMarks, g:filen)
endif

" This is the function setting a mark, called from visual mode.
function! s:VisualMark() "{{{
    " get the current file path
    let filePath = expand('%:p')

    " get the mark ID
    let mark = s:GetVisualMarkInput("mark selection ")

    " retrieve the position starting the selection
    normal! gvo
    let [startLine, startCol] = [line('.'), col('.')]

    " retrieve the position ending the selection
    normal! o
    let [endLine, endCol] = [line('.'), col('.')]

    " do whatever the user likes
    if g:visualMarks_exitVModeAfterMarking
        normal! v
    endif

    " update the dictionnary:
    " Initialize the file entry if didn't existed yet:
    if !has_key(g:visualMarks, filePath)
        let g:visualMarks[filePath] = {}
    endif
    " and fill it up!
    let g:visualMarks[filePath][mark] = [startLine, startCol, endLine, endCol]

    " and save it to the file. But I am sure we don't need to do this each time.
    call s:SaveVariable(g:visualMarks, g:filen)
endfun
"}}}

" This is the function retrieving a marked selection, called from normal mode.
function! s:GetVisualMark() "{{{
    " get the current file path
    let filePath = expand('%:p')

    " get the mark ID
    let mark = s:GetVisualMarkInput("restore selection ")

    " retrieve the latest version of the dictionnary. (No need each time?)
    let g:visualMarks = s:ReadVariable(g:filen)

    " check whether the mark has already been recorded, then put the flag down.
    let noSuchMark = 1
    if has_key(g:visualMarks, filePath)
        if has_key(g:visualMarks[filePath], mark)
            let noSuchMark = 0
        endif
    endif

    if noSuchMark
        echom "no Such mark " . mark . " for this file."
    else
        " Then we can safely get back to this selection!
        let coordinates = g:visualMarks[filePath][mark]
        "move to the start pos, go to visual mode, and go to the end pos
        " + recursively open folds, just enough to see the selection
        call cursor(coordinates[2], coordinates[3])
        normal! zv
        call cursor(coordinates[0], coordinates[1])
        "enter visual mode to select the rest
        exec "normal! zvv"
        call cursor(coordinates[2], coordinates[3])
    endif

    " And that's it! :)
endfun
"}}}

" Here is the function retrieving user input characterizing the mark. It returns
" an appropriate key for the dictionnary.
" For now, it uses `input` with a custom prompt message, and this is why it
" requires the enter key to be pressed
function! s:GetVisualMarkInput(prompt) "{{{
    echom a:prompt
    let mark = nr2char(getchar())
    return mark
endfun
"}}}

" " Don't work yet !
" " And we're done. Now map it to something cool:
" noremap <SID>Add :call <SID>Add(expand("<cword>"), 1)<CR>
" noremap <unique> <script> <Plug>TypecorrAdd <SID>Add
" map <unique> <Leader>a  <Plug>TypecorrAdd

" vnoremap <unique> <script> <Plug>VisualMarksVisualMark <SID>VisualMark
" nnoremap <unique> <script> <Plug>VisualMarksGetVisualMark <SID>GetVisualMark
" vnoremap <SID>VisualMark <esc>:call <SID>VisualMark()<CR>
" nnoremap <SID>GetVisualMark :call <SID>GetVisualMark()<CR>

" if !hasmapto("<Plug>VisualMarksVisualMark")
    " vmap <unique> m <Plug>VisualMarksVisualMark
" endif
" if !hasmapto("<Plug>VisualMarksGetVisualMark")
    " nmap < <Plug>VisualMarksGetVisualMark
" endif

vnoremap m <esc>:call <SID>VisualMark()<CR>
nnoremap < :call <SID>GetVisualMark()<CR>

" " lines for handling line continuation, according to :help write-plugin<CR>
" let &cpo = s:save_cpo
" unlet s:save_cpo


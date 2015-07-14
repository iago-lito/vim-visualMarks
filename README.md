visualMarks
===========

visualMarks is a small vimScript allowing marking and retrieving visually
selected blocks by associating them to marks, in way inspired from Vim's native
"registers".

Usage:
------
To use it with the default mapping and save the mark in register "a", type in visual mode:

```
ma
```

Note that to do the same, but save the selection in register "b" it would be
`mb` etc.


The default mapping to retrieve the mark from register "a" is this in normal
mode:

```
<a
```

And you will get it back. Of course, you can replace `a` with any mark you want.
These visual registers are saved in a separate file and are totally isolated from
the normal registers so a regular mark in register "a" will not get overwritten
by a visual mark in register "a".

This script also remembers which of the 3 visual modes you were in when you made
the mark, and it will recover that as well. So if you were in block visual, and
you retrieve your mark, you will have your mark selected in block visual.

These marks are also specific to a file, so a visual mark in file "a.txt" and a
visual mark in file "b.txt" of the same register name are different marks, and
will be persistent (ie, they will be able to be used after coming back to a file
after closing it).

Making Your Own Mapping:
------------------------
To change the default mapping to something else, put this into your vimrc:

```
vmap <unique> m <Plug>VisualMarksVisualMark
nmap <unique> < <Plug>VisualMarksGetVisualMark
```

And then change the `m` or `<` to whatever you want to use.


A Note from the Developers:
---------------------------
A few more features will come soon I hope. Feel free to contribute of course if
you feel inspired! :)


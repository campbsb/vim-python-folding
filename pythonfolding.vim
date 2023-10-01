" Python Folding macros for Vim
" Copy to ~/.vim/ftplugin/python/pythonfolding.vim
" Requires the following in your .vimrc, which are required for any filetype
" specific configuration:
"   set nocompatible
"   filetype plugin indent on
"
" Shout out to Steve Losh for a great tutorial - https://learnvimscriptthehardway.stevelosh.com/chapters/49.html
"
" Steve Campbell Dec 2019

" # Some notes to help with the code below
" ## Fold levels:
"   '-1' - undefined - same as the line above or below, whichever is smaller.
"   '0'  - not in a fold
"   '>1'  - open a fold of level 1
"   Avoid -1 to get good performance
"
" ## Variable types:
"   a: function parameter
"   w: Local to editor window
"   l: local to function
"   v: predefined Vim variable
"

setlocal foldmethod=expr
setlocal foldexpr=GetPythonFold()
setlocal foldtext=FoldText()
let w:currentLevel = 0
let w:levelStack = []

function! IndentLevel(lnum)
  "As we want to fold all lines in the module, incrememnt it by 1.
    return 1 + (indent(a:lnum) / &shiftwidth)
endfunction

function! StackIndent(currentIndent)
  let w:currentLevel = a:currentIndent
  while w:levelStack[-1] >= w:currentLevel
    unlet w:levelStack[-1]
  endwhile
  call add(w:levelStack, w:currentLevel)
  return '>' . w:currentLevel
endfunction

function! GetPythonFold()
  let currentLine = getline(v:lnum)

  " Skip blank lines
  if currentLine !~ '\v\S'
    return w:currentLevel
  endif

  let currentIndent = IndentLevel(v:lnum)

  " Classes definition - create new level 1 fold.
  " =~# - case sensitive regexp match - see https://vimhelp.org/eval.txt.html
  if currentLine =~# '\v^ *class '
    let w:inDecorator = 0
    return StackIndent(currentIndent)
  endif

  " Create new fold if we have a new function def, without preceding @decorators
  if currentLine =~# '\v^ *(async )? *def ' && w:inDecorator == 0
    if currentLine =~ '\v\([^\)]*$'
      " Make a note if we end the line with parentheses
      let w:inParens = 1
    endif
    return StackIndent(currentIndent)
  endif

  if currentLine =~# '\v^ *(class|(async  *)?def)'
    " We are no longer in a set of @decorators
    let w:inDecorator = 0
  endif

  " Create new fold if we are starting a set of @decorators
  " Useful for folding unit test files
  if currentLine =~# '\v^ *\@' && w:inDecorator == 0
    let w:inDecorator = 1
    return StackIndent(currentIndent)
  endif

  if w:inParens == 1 && currentLine =~ '\v^ *\)'
    let w:inParens = 0
    return w:currentLevel
  endif

  " Already in a fold? We want to return the correct indent.
  " However, if we were in a class method or an inner function, we have to check
  " that we haven't returned to the containing class/function.
  " We achieve this by checking to see if our current indent is less than the
  " current fold, and if so, popping levels off the stack until we get to the
  " right one.
  " Skip indent 0 for the top of the file
  " Skip this section if we are in function definition parentheses (w:inParens)
  " Skip indent 0 function calls - main()!
  if w:currentLevel > 0 && currentIndent > 0 && currentLine !~# '\v^[a-z_]+\('
    if w:inParens == 0
      while w:currentLevel > currentIndent
        unlet w:levelStack[-1]
        let w:currentLevel = w:levelStack[-1]
      endwhile
    endif
    return w:currentLevel
  endif

" At the top of the file, start a 'Headers' fold
  let w:currentLevel = 1
  let w:inDecorator = 0
  let w:inParens = 0
  let w:levelStack = [1]
  return ">1"
fi

endfunction

" Custom foldtext function to get the function def line if our fold starts
" with a patch
function! FoldText()
  if v:foldstart == 1
    let comment = "HEADERS"
  else
    let comment = getline( v:foldstart )
    let linenum = v:foldstart
    while linenum < v:foldend
      let line = getline( linenum )
      if line =~# '\v^ *(class |(async )?def )'
        let comment = line
        break
      endif
      let linenum = linenum + 1
    endwhile
  endif
  let n = v:foldend - v:foldstart + 1
  let info = printf("+-- %3d lines ", n)
  return info . comment
endfunction

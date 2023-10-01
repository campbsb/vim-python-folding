# vim-python-folding
Vim ftplugin for smart Python code folding

Simply copy the pythonfolding.vim file into your .vim/ftplugin/python directory

You will want the following lines in your .vimrc:
```
set nocompatible           " Required for filetype specific configuration
filetype plugin indent on  " Enables plugins based on filetype.
```

This module seeks to
* Don't fold everything - only fold classes, functions, and the file headers
* Have 'pie' decorators included into the fold of the function they are decorating, but have the fold still display the function name
* Have fast performance
* Display a useful set of initial folds, not the whole file in a single fold!

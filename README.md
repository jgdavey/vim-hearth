Hearth is designed to speed up your clojure TDD cycle by using a single
key mapping to run the most relevant test based on the current file
in vim. It can run a clojure test from within a REPL session, or from
the command line, and automatically detects which one to do (thanks to
fireplace.vim).

For more information, see the documentation.

Dependencies
------------

This plugin depends on [vim-fireplace][1], and you can optionally use it
with [tslime.vim][2] or [vimux][3].

**Note:** Due to a bug in the original tslime.vim plugin, please use
[my fork][2].


Installation
------------

Use [pathogen][4] or [vundle][5].

[1]: https://github.com/tpope/vim-fireplace
[2]: https://github.com/jgdavey/tslime.vim
[3]: https://github.com/benmills/vimux
[4]: https://github.com/tpope/vim-pathogen
[5]: https://github.com/gmarik/vundle

; -*-Emacs-Lisp-*-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:                        cscope interface for (X)Emacs
; Original author:                    Darryl Okahata,
; Author of new features, Maintainer: Dima Kogan
;
; (C) Copyright 2000, 2001, 2002, Darryl Okahata <darrylo@sonic.net>,
;     all rights reserved.
; (C) Copyright 2013 Dima Kogan <dima@secretsauce.net>
; GNU Emacs enhancements (C) Copyright 2001,
;         Triet H. Lai <thlai@mail.usyd.edu.au>
; Fuzzy matching and navigation code (C) Copyright 2001,
;         Steven Elliott <selliott4@austin.rr.com>
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This is a cscope interface for (X)Emacs.
;; It currently runs under Unix only.
;;
;; Using cscope, you can easily search for where symbols are used and defined.
;; Cscope is designed to answer questions like:
;;
;;         Where is this variable used?
;;         What is the value of this preprocessor symbol?
;;         Where is this function in the source files?
;;         What functions call this function?
;;         What functions are called by this function?
;;         Where does the message "out of space" come from?
;;         Where is this source file in the directory structure?
;;         What files include this header file?
;;
;; Send comments to dima@secretsauce.net
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ***** INSTALLATION *****
;;
;; * NOTE: this interface currently runs under Unix only.
;;
;; This module needs a shell script called "cscope-indexer", which
;; should have been supplied along with this emacs-lisp file.  The
;; purpose of "cscope-indexer" is to create and optionally maintain
;; the cscope databases.  If all of your source files are in one
;; directory, you don't need this script; it's very nice to have,
;; though, as it handles recursive subdirectory indexing, and can be
;; used in a nightly or weekly cron job to index very large source
;; repositories.  See the beginning of the file, "cscope-indexer", for
;; usage information.
;;
;; Installation steps:
;;
;; 0. (It is, of course, assumed that cscope is already properly
;;    installed on the current system.)
;;
;; 1. Install the "cscope-indexer" script into some convenient
;;    directory in $PATH.  The only real constraint is that (X)Emacs
;;    must be able to find and execute it.  You may also have to edit
;;    the value of PATH in the script, although this is unlikely; the
;;    majority of people should be able to use the script, "as-is".
;;
;; 2. Make sure that the "cscope-indexer" script is executable.  In
;;    particular, if you had to ftp this file, it is probably no
;;    longer executable.
;;
;; 3. Put this emacs-lisp file somewhere where (X)Emacs can find it.  It
;;    basically has to be in some directory listed in "load-path".
;;
;; 4. Edit your ~/.emacs file to add the line:
;;
;;      (require 'xcscope)
;;
;; 5. If you intend to use xcscope.el often you can optionally edit your
;;    ~/.emacs file to add keybindings that reduce the number of keystrokes
;;    required.  For example, the following will add "C-f#" keybindings, which
;;    are easier to type than the usual "C-c s" prefixed keybindings.  Note
;;    that specifying "global-map" instead of "cscope-global-keymap" makes the
;;    keybindings available in all buffers:
;;
;;	(define-key global-map [(control f3)]  'cscope-set-initial-directory)
;;	(define-key global-map [(control f4)]  'cscope-unset-initial-directory)
;;	(define-key global-map [(control f5)]  'cscope-find-this-symbol)
;;	(define-key global-map [(control f6)]  'cscope-find-global-definition)
;;	(define-key global-map [(control f7)]
;;	  'cscope-find-global-definition-no-prompting)
;;	(define-key global-map [(control f8)]  'cscope-pop-mark)
;;	(define-key global-map [(control f9)]  'cscope-history-forward-line)
;;	(define-key global-map [(control f10)] 'cscope-history-forward-file)
;;	(define-key global-map [(control f11)] 'cscope-history-backward-line)
;;	(define-key global-map [(control f12)] 'cscope-history-backward-file)
;;      (define-key global-map [(meta f9)]  'cscope-display-buffer)
;;      (define-key global-map [(meta f10)] 'cscope-display-buffer-toggle)
;;
;; 6. Restart (X)Emacs.  That's it.
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ***** USING THIS MODULE *****
;;
;; * Basic usage:
;;
;; If all of your C/C++/lex/yacc source files are in the same
;; directory, you can just start using this module.  If your files are
;; spread out over multiple directories, see "Advanced usage", below.
;;
;; Just edit a source file, and use the pull-down or pop-up (button 3)
;; menus to select one of:
;;
;;         Find symbol
;;         Find global definition
;;         Find called functions
;;         Find functions calling a function
;;         Find text string
;;         Find egrep pattern
;;         Find a file
;;         Find files #including a file
;;
;; The cscope database will be automatically created in the same
;; directory as the source files (assuming that you've never used
;; cscope before), and a buffer will pop-up displaying the results.
;; You can then use button 2 (the middle button) on the mouse to edit
;; the selected file, or you can move the text cursor over a selection
;; and press [Enter].
;;
;; The third mouse button is bound to a popup menu for cscope. The
;; previously-invoked find command is marked in the cscope menu. Shift-mouse
;; button 3 invokes the last find command again. E.g. if you look for the symbol
;; 'main' and afterwards you want to look for another symbol, just press Shift
;; and click the third button.
;;
;; Hopefully, the interface should be fairly intuitive.
;;
;;
;; * Locating the cscope databases:
;;
;; This module will first use the variable, `cscope-database-regexps', to search
;; for a suitable database directory. If a database location cannot be found
;; using this variable then a search is begun at the variable,
;; `cscope-initial-directory', if set. If not set and we're running this search
;; from the *cscope* buffer, the search is begun from the directory of the
;; search at point. Otherwise, the current directory is used. If the directory
;; is not a cscope database directory then the directory's parent, parent's
;; parent, etc. is searched until a cscope database directory is found, or the
;; root directory is reached. If the root directory is reached, the current
;; directory will be used.
;;
;; A cscope database directory is one in which EITHER a cscope database
;; file (e.g., "cscope.out") OR a cscope file list (e.g.,
;; "cscope.files") exists.  If only "cscope.files" exists, the
;; corresponding "cscope.out" will be automatically created by cscope
;; when a search is done.  By default, the cscope database file is called
;; "cscope.out", but this can be changed (on a global basis) via the
;; variable, `cscope-database-file'.  There is limited support for cscope
;; databases that are named differently than that given by
;; `cscope-database-file', using the variable, `cscope-database-regexps'.
;;
;; Note that the variable, `cscope-database-regexps', is generally not
;; needed, as the normal hierarchical database search is sufficient
;; for placing and/or locating the cscope databases.  However, there
;; may be cases where it makes sense to place the cscope databases
;; away from where the source files are kept; in this case, this
;; variable is used to determine the mapping.  One use for this
;; variable is when you want to share the database file with other
;; users; in this case, the database may be located in a directory
;; separate from the source files.  
;;
;; Setting the variable, `cscope-initial-directory', is useful when a
;; search is to be expanded by specifying a cscope database directory
;; that is a parent of the directory that this module would otherwise
;; use.  For example, consider a project that contains the following
;; cscope database directories:
;;
;;     /users/jdoe/sources
;;     /users/jdoe/sources/proj1
;;     /users/jdoe/sources/proj2
;;
;; If a search is initiated from a .c file in /users/jdoe/sources/proj1
;; then (assuming the variable, `cscope-database-regexps', is not set)
;; /users/jdoe/sources/proj1 will be used as the cscope data base directory.
;; Only matches in files in /users/jdoe/sources/proj1 will be found.  This
;; can be remedied by typing "C-c s a" and then "M-del" to remove single
;; path element in order to use a cscope database directory of
;; /users/jdoe/sources.  Normal searching can be restored by typing "C-c s A".
;;
;;
;; * Keybindings:
;;
;; All keybindings use the "C-c s" prefix, but are usable only while
;; editing a source file, or in the cscope results buffer:
;;
;;      C-c s s         Find symbol.
;;      C-c s =         Find assignments to this symbol
;;      C-c s d         Find global definition.
;;      C-c s g         Find global definition (alternate binding).
;;      C-c s G         Find global definition without prompting.
;;      C-c s c         Find functions calling a function.
;;      C-c s C         Find called functions (list functions called
;;                      from a function).
;;      C-c s t         Find text string.
;;      C-c s e         Find egrep pattern.
;;      C-c s f         Find a file.
;;      C-c s i         Find files #including a file.
;;
;; These pertain to navigation through the search results:
;;
;;      C-c s b         Display *cscope* buffer.
;;      C-c s B         Auto display *cscope* buffer toggle.
;;      C-c s n         Next symbol.
;;      C-c s N         Next file.
;;      C-c s p         Previous symbol.
;;      C-c s P         Previous file.
;;      C-c s u         Pop mark.
;;
;; These pertain to setting and unsetting the variable,
;; `cscope-initial-directory', (location searched for the cscope database
;;  directory):
;;
;;      C-c s a         Set initial directory.
;;      C-c s A         Unset initial directory.
;;
;; These pertain to cscope database maintenance:
;;
;;      C-c s L         Create list of files to index.
;;      C-c s I         Create list and index.
;;      C-c s E         Edit list of files to index.
;;      C-c s W         Locate this buffer's cscope directory
;;                      ("W" --> "where").
;;      C-c s S         Locate this buffer's cscope directory.
;;                      (alternate binding: "S" --> "show").
;;      C-c s T         Locate this buffer's cscope directory.
;;                      (alternate binding: "T" --> "tell").
;;      C-c s D         Dired this buffer's directory.
;;
;;
;; * Advanced usage:
;;
;; If the source files are spread out over multiple directories,
;; you've got a few choices:
;;
;; [ NOTE: you will need to have the script, "cscope-indexer",
;;   properly installed in order for the following to work.  ]
;;
;; 1. If all of the directories exist below a common directory
;;    (without any extraneous, unrelated subdirectories), you can tell
;;    this module to place the cscope database into the top-level,
;;    common directory.  This assumes that you do not have any cscope
;;    databases in any of the subdirectories.  If you do, you should
;;    delete them; otherwise, they will take precedence over the
;;    top-level database.
;;
;;    If you do have cscope databases in any subdirectory, the
;;    following instructions may not work right.
;;
;;    It's pretty easy to tell this module to use a top-level, common
;;    directory:
;;
;;    a. Make sure that the menu pick, "Cscope/Index recursively", is
;;       checked (the default value).
;;
;;    b. Select the menu pick, "Cscope/Create list and index", and
;;       specify the top-level directory.  This will run the script,
;;       "cscope-indexer", in the background, so you can do other
;;       things if indexing takes a long time.  A list of files to
;;       index will be created in "cscope.files", and the cscope
;;       database will be created in "cscope.out".
;;
;;    Once this has been done, you can then use the menu picks
;;    (described in "Basic usage", above) to search for symbols.
;;
;;    Note, however, that, if you add or delete source files, you'll
;;    have to either rebuild the database using the above procedure,
;;    or edit the file, "cscope.files" to add/delete the names of the
;;    source files.  To edit this file, you can use the menu pick,
;;    "Cscope/Edit list of files to index".
;;
;;
;; 2. If most of the files exist below a common directory, but a few
;;    are outside, you can use the menu pick, "Cscope/Create list of
;;    files to index", and specify the top-level directory.  Make sure
;;    that "Cscope/Index recursively", is checked before you do so,
;;    though.  You can then edit the list of files to index using the
;;    menu pick, "Cscope/Edit list of files to index".  Just edit the
;;    list to include any additional source files not already listed.
;;
;;    Once you've created, edited, and saved the list, you can then
;;    use the menu picks described under "Basic usage", above, to
;;    search for symbols.  The first time you search, you will have to
;;    wait a while for cscope to fully index the source files, though.
;;    If you have a lot of source files, you may want to manually run
;;    cscope to build the database:
;;
;;            cd top-level-directory    # or wherever
;;            rm -f cscope.out          # not always necessary
;;            cscope -b
;;
;;
;; 3. If the source files are scattered in many different, unrelated
;;    places, you'll have to manually create cscope.files and put a
;;    list of all pathnames into it.  Then build the database using:
;;
;;            cd some-directory         # wherever cscope.files exists
;;            rm -f cscope.out          # not always necessary
;;            cscope -b
;;
;;    Next, read the documentation for the variable,
;;    "cscope-database-regexps", and set it appropriately, such that
;;    the above-created cscope database will be referenced when you
;;    edit a related source file.
;;
;;    Once this has been done, you can then use the menu picks
;;    described under "Basic usage", above, to search for symbols.
;;
;;
;; * Interesting configuration variables:
;;
;; "cscope-truncate-lines"
;;      This is the value of `truncate-lines' to use in cscope
;;      buffers; the default is the current setting of
;;      `truncate-lines'.  This variable exists because it can be
;;      easier to read cscope buffers with truncated lines, while
;;      other buffers do not have truncated lines.
;;
;; "cscope-use-relative-paths"
;;      If non-nil, use relative paths when creating the list of files
;;      to index.  The path is relative to the directory in which the
;;      cscope database will be created.  If nil, absolute paths will
;;      be used.  Absolute paths are good if you plan on moving the
;;      database to some other directory (if you do so, you'll
;;      probably also have to modify `cscope-database-regexps').
;;      Absolute paths may also be good if you share the database file
;;      with other users (you'll probably want to specify some
;;      automounted network path for this).
;;
;; "cscope-index-recursively"
;;      If non-nil, index files in the current directory and all
;;      subdirectories.  If nil, only files in the current directory
;;      are indexed.  This variable is only used when creating the
;;      list of files to index, or when creating the list of files and
;;      the corresponding cscope database.
;;
;; "cscope-name-line-width"
;;      The width of the combined "function name:line number" field in
;;      the cscope results buffer.  If negative, the field is
;;      left-justified.
;;
;; "cscope-do-not-update-database"
;;      If non-nil, never check and/or update the cscope database when
;;      searching.  Beware of setting this to non-nil, as this will
;;      disable automatic database creation, updating, and
;;      maintenance.
;;
;; "cscope-display-cscope-buffer" 
;;      If non-nil, display the *cscope* buffer after each search
;;      (default).  This variable can be set in order to reduce the
;;      number of keystrokes required to navigate through the matches.
;;
;; "cscope-database-regexps"
;; 	List to force directory-to-cscope-database mappings.
;; 	This is a list of `(REGEXP DBLIST [ DBLIST ... ])', where:
;;
;; 	REGEXP is a regular expression matched against the current buffer's
;; 	current directory.  The current buffer is typically some source file,
;; 	and you're probably searching for some symbol in or related to this
;; 	file.  Basically, this regexp is used to relate the current directory
;; 	to a cscope database.  You need to start REGEXP with "^" if you want
;; 	to match from the beginning of the current directory.
;;
;; 	DBLIST is a list that contains one or more of:
;;
;; 	    ( DBDIR )
;; 	    ( DBDIR ( OPTIONS ) )
;; 	    ( t )
;; 	    t
;;
;; 	Here, DBDIR is a directory (or a file) that contains a cscope
;; 	database.  If DBDIR is a directory, then it is expected that the
;; 	cscope database, if present, has the filename given by the variable,
;; 	`cscope-database-file'; if DBDIR is a file, then DBDIR is the path
;; 	name to a cscope database file (which does not have to be the same as
;; 	that given by `cscope-database-file').  If only DBDIR is specified,
;; 	then that cscope database will be searched without any additional
;; 	cscope command-line options.  If OPTIONS is given, then OPTIONS is a
;; 	list of strings, where each string is a separate cscope command-line
;; 	option.
;;
;; 	In the case of "( t )", this specifies that the search is to use the
;; 	normal hierarchical database search.  This option is used to
;; 	explicitly search using the hierarchical database search either before
;; 	or after other cscope database directories.
;;
;; 	If "t" is specified (not inside a list), this tells the searching
;; 	mechanism to stop searching if a match has been found (at the point
;; 	where "t" is encountered).  This is useful for those projects that
;; 	consist of many subprojects.  You can specify the most-used
;; 	subprojects first, followed by a "t", and then followed by a master
;; 	cscope database directory that covers all subprojects.  This will
;; 	cause the most-used subprojects to be searched first (hopefully
;; 	quickly), and the search will then stop if a match was found.  If not,
;; 	the search will continue using the master cscope database directory.
;;
;; 	Here, `cscope-database-regexps' is generally not used, as the normal
;; 	hierarchical database search is sufficient for placing and/or locating
;; 	the cscope databases.  However, there may be cases where it makes
;; 	sense to place the cscope databases away from where the source files
;; 	are kept; in this case, this variable is used to determine the
;; 	mapping.
;;
;; 	This module searches for the cscope databases by first using this
;; 	variable; if a database location cannot be found using this variable,
;; 	then the current directory is searched, then the parent, then the
;; 	parent's parent, until a cscope database directory is found, or the
;; 	root directory is reached.  If the root directory is reached, the
;; 	current directory will be used.
;;
;; 	A cscope database directory is one in which EITHER a cscope database
;; 	file (e.g., "cscope.out") OR a cscope file list (e.g.,
;; 	"cscope.files") exists.  If only "cscope.files" exists, the
;; 	corresponding "cscope.out" will be automatically created by cscope
;; 	when a search is done.  By default, the cscope database file is called
;; 	"cscope.out", but this can be changed (on a global basis) via the
;; 	variable, `cscope-database-file'.  There is limited support for cscope
;; 	databases that are named differently than that given by
;; 	`cscope-database-file', using the variable, `cscope-database-regexps'.
;;
;; 	Here is an example of `cscope-database-regexps':
;;
;;		(setq cscope-database-regexps
;;		      '(
;;			( "^/users/jdoe/sources/proj1"
;;			  ( t )
;;			  ( "/users/jdoe/sources/proj2")
;;			  ( "/users/jdoe/sources/proj3/mycscope.out")
;;			  ( "/users/jdoe/sources/proj4")
;;			  t
;;			  ( "/some/master/directory" ("-d" "-I/usr/local/include") )
;;			  )
;;			( "^/users/jdoe/sources/gnome/"
;;			  ( "/master/gnome/database" ("-d") )
;;			  )
;;			))
;;
;; 	If the current buffer's directory matches the regexp,
;; 	"^/users/jdoe/sources/proj1", then the following search will be
;; 	done:
;;
;; 	    1. First, the normal hierarchical database search will be used to
;;	       locate a cscope database.
;;
;; 	    2. Next, searches will be done using the cscope database
;;	       directories, "/users/jdoe/sources/proj2",
;;	       "/users/jdoe/sources/proj3/mycscope.out", and
;;	       "/users/jdoe/sources/proj4".  Note that, instead of the file,
;;	       "cscope.out", the file, "mycscope.out", will be used in the
;;	       directory "/users/jdoe/sources/proj3".
;;
;; 	    3. If a match was found, searching will stop.
;;
;; 	    4. If a match was not found, searching will be done using
;;	       "/some/master/directory", and the command-line options "-d"
;;	       and "-I/usr/local/include" will be passed to cscope.
;;
;; 	If the current buffer's directory matches the regexp,
;; 	"^/users/jdoe/sources/gnome", then the following search will be
;; 	done:
;;
;; 	    The search will be done only using the directory,
;; 	    "/master/gnome/database".  The "-d" option will be passed to
;; 	    cscope.
;;
;; 	If the current buffer's directory does not match any of the above
;; 	regexps, then only the normal hierarchical database search will be
;; 	done.
;;
;;
;; * Other notes:
;;
;; 1. The script, "cscope-indexer", uses a sed command to determine
;;    what is and is not a C/C++/lex/yacc source file.  It's idea of a
;;    source file may not correspond to yours.
;;
;; 2. This module is called, "xcscope", because someone else has
;;    already written a "cscope.el" (although it's quite old).
;;
;;
;; * KNOWN BUGS:
;;
;; 1. Cannot handle whitespace in directory or file names.
;;
;; 2. By default, colored faces are used to display results.  If you happen
;;    to use a black background, part of the results may be invisible
;;    (because the foreground color may be black, too).  There are at least
;;    two solutions for this:
;;
;;    2a. Turn off colored faces, by setting `cscope-use-face' to `nil',
;;        e.g.:
;;
;;            (setq cscope-use-face nil)
;;
;;    2b. Explicitly set colors for the faces used by cscope.  The faces
;;        are:
;;
;;            cscope-file-face
;;            cscope-function-face
;;            cscope-line-number-face
;;            cscope-mouse-face
;;            cscope-separator-face
;;
;; 3. The support for cscope databases different from that specified by
;;    `cscope-database-file' is quirky.  If the file does not exist, it
;;    will not be auto-created (unlike files names by
;;    `cscope-database-file').  You can manually force the file to be
;;    created by using touch(1) to create a zero-length file; the
;;    database will be created the next time a search is done.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'easymenu)


(defgroup cscope nil
  "Cscope interface for (X)Emacs.
Using cscope, you can easily search for where symbols are used and defined.
It is designed to answer questions like:

        Where is this variable used?
        What is the value of this preprocessor symbol?
        Where is this function in the source files?
        What functions call this function?
        What functions are called by this function?
        Where does the message \"out of space\" come from?
        Where is this source file in the directory structure?
        What files include this header file?
"
  :prefix "cscope-"
  :group 'tools)


(defcustom cscope-do-not-update-database nil
  "*If non-nil, never check and/or update the cscope database when searching.
Beware of setting this to non-nil, as this will disable automatic database
creation, updating, and maintenance."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-database-regexps nil
  "*List to force directory-to-cscope-database mappings.
This is a list of `(REGEXP DBLIST [ DBLIST ... ])', where:

REGEXP is a regular expression matched against the current buffer's
current directory.  The current buffer is typically some source file,
and you're probably searching for some symbol in or related to this
file.  Basically, this regexp is used to relate the current directory
to a cscope database.  You need to start REGEXP with \"^\" if you want
to match from the beginning of the current directory.

DBLIST is a list that contains one or more of:

    ( DBDIR )
    ( DBDIR ( OPTIONS ) )
    ( t )
    t

Here, DBDIR is a directory (or a file) that contains a cscope database.
If DBDIR is a directory, then it is expected that the cscope database,
if present, has the filename given by the variable,
`cscope-database-file'; if DBDIR is a file, then DBDIR is the path name
to a cscope database file (which does not have to be the same as that
given by `cscope-database-file').  If only DBDIR is specified, then that
cscope database will be searched without any additional cscope
command-line options.  If OPTIONS is given, then OPTIONS is a list of
strings, where each string is a separate cscope command-line option.

In the case of \"( t )\", this specifies that the search is to use the
normal hierarchical database search.  This option is used to
explicitly search using the hierarchical database search either before
or after other cscope database directories.

If \"t\" is specified (not inside a list), this tells the searching
mechanism to stop searching if a match has been found (at the point
where \"t\" is encountered).  This is useful for those projects that
consist of many subprojects.  You can specify the most-used
subprojects first, followed by a \"t\", and then followed by a master
cscope database directory that covers all subprojects.  This will
cause the most-used subprojects to be searched first (hopefully
quickly), and the search will then stop if a match was found.  If not,
the search will continue using the master cscope database directory.

Here, `cscope-database-regexps' is generally not used, as the normal
hierarchical database search is sufficient for placing and/or locating
the cscope databases.  However, there may be cases where it makes
sense to place the cscope databases away from where the source files
are kept; in this case, this variable is used to determine the
mapping.

This module searches for the cscope databases by first using this
variable; if a database location cannot be found using this variable,
then the current directory is searched, then the parent, then the
parent's parent, until a cscope database directory is found, or the
root directory is reached.  If the root directory is reached, the
current directory will be used.

A cscope database directory is one in which EITHER a cscope database
file (e.g., \"cscope.out\") OR a cscope file list (e.g.,
\"cscope.files\") exists.  If only \"cscope.files\" exists, the
corresponding \"cscope.out\" will be automatically created by cscope
when a search is done.  By default, the cscope database file is called
\"cscope.out\", but this can be changed (on a global basis) via the
variable, `cscope-database-file'.  There is limited support for cscope
databases that are named differently than that given by
`cscope-database-file', using the variable, `cscope-database-regexps'.

Here is an example of `cscope-database-regexps':

        (setq cscope-database-regexps
              '(
                ( \"^/users/jdoe/sources/proj1\"
                  ( t )
                  ( \"/users/jdoe/sources/proj2\")
                  ( \"/users/jdoe/sources/proj3/mycscope.out\")
                  ( \"/users/jdoe/sources/proj4\")
                  t
                  ( \"/some/master/directory\" (\"-d\" \"-I/usr/local/include\") )
                  )
                ( \"^/users/jdoe/sources/gnome/\"
                  ( \"/master/gnome/database\" (\"-d\") )
                  )
                ))

If the current buffer's directory matches the regexp,
\"^/users/jdoe/sources/proj1\", then the following search will be
done:

    1. First, the normal hierarchical database search will be used to
       locate a cscope database.

    2. Next, searches will be done using the cscope database
       directories, \"/users/jdoe/sources/proj2\",
       \"/users/jdoe/sources/proj3/mycscope.out\", and
       \"/users/jdoe/sources/proj4\".  Note that, instead of the file,
       \"cscope.out\", the file, \"mycscope.out\", will be used in the
       directory \"/users/jdoe/sources/proj3\".

    3. If a match was found, searching will stop.

    4. If a match was not found, searching will be done using
       \"/some/master/directory\", and the command-line options \"-d\"
       and \"-I/usr/local/include\" will be passed to cscope.

If the current buffer's directory matches the regexp,
\"^/users/jdoe/sources/gnome\", then the following search will be
done:

    The search will be done only using the directory,
    \"/master/gnome/database\".  The \"-d\" option will be passed to
    cscope.

If the current buffer's directory does not match any of the above
regexps, then only the normal hierarchical database search will be
done.

"
  :type '(repeat (list :format "%v"
		       (choice :value ""
			       (regexp :tag "Buffer regexp")
			       string)
		       (choice :value ""
			       (directory :tag "Cscope database directory")
			       string)
		       (string :value ""
			       :tag "Optional cscope command-line arguments")
		       ))
  :group 'cscope)
(defcustom cscope-name-line-width -30
  "*The width of the combined \"function name:line number\" field in the
cscope results buffer.  If negative, the field is left-justified."
  :type 'integer
  :group 'cscope)


(defcustom cscope-truncate-lines truncate-lines
  "*The value of `truncate-lines' to use in cscope buffers.
This variable exists because it can be easier to read cscope buffers
with truncated lines, while other buffers do not have truncated lines."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-display-times t
  "*If non-nil, display how long each search took.
The elasped times are in seconds.  Floating-point support is required
for this to work."
  :type 'boolean
  :group 'cscope)

(defcustom cscope-max-cscope-buffer-size 1000000
  "*If >0, limit the size of the *cscope* buffer. Only the
'cscope-max-cscope-buffer-size' bytes at the end are kept,
rounded up to keep whole sets of cscope output"
  :type 'integer
  :group 'cscope)

(defcustom cscope-program "cscope"
  "*The pathname of the cscope executable to use."
  :type 'string
  :group 'cscope)


(defcustom cscope-index-file "cscope.files"
  "*The name of the cscope file list file."
  :type 'string
  :group 'cscope)


(defcustom cscope-database-file "cscope.out"
  "*The name of the cscope database file."
  :type 'string
  :group 'cscope)


(defcustom cscope-edit-single-match t
  "*If non-nil and only one match is output, edit the matched location."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-display-cscope-buffer t
  "*If non-nil automatically display the *cscope* buffer after each search."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-stop-at-first-match-dir nil
  "*If non-nil, stop searching through multiple databases if a match is found.
This option is useful only if multiple cscope database directories are being
used.  When multiple databases are searched, setting this variable to non-nil
will cause searches to stop when a search outputs anything; no databases after
this one will be searched."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-use-relative-paths t
  "*If non-nil, use relative paths when creating the list of files to index.
The path is relative to the directory in which the cscope database
will be created.  If nil, absolute paths will be used.  Absolute paths
are good if you plan on moving the database to some other directory
(if you do so, you'll probably also have to modify
\`cscope-database-regexps\').  Absolute paths  may also be good if you
share the database file with other users (you\'ll probably want to
specify some automounted network path for this)."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-index-recursively t
  "*If non-nil, index files in the current directory and all subdirectories.
If nil, only files in the current directory are indexed.  This
variable is only used when creating the list of files to index, or
when creating the list of files and the corresponding cscope database."
  :type 'boolean
  :group 'cscope)

(defcustom cscope-indexing-script "cscope-indexer"
  "*The shell script used to create cscope indices."
  :type 'string
  :group 'cscope)


(defcustom cscope-symbol-chars "A-Za-z0-9_"
  "*A string containing legal characters in a symbol.
The current syntax table should really be used for this."
  :type 'string
  :group 'cscope)


(defcustom cscope-filename-chars "-.,/A-Za-z0-9_~!@#$%&+=\\\\"
  "*A string containing legal characters in a symbol.
The current syntax table should really be used for this."
  :type 'string
  :group 'cscope)


(defcustom cscope-allow-arrow-overlays t
  "*If non-nil, use an arrow overlay to show target lines.
Arrow overlays are only used when the following functions are used:

    cscope-show-entry-other-window
    cscope-show-next-entry-other-window
    cscope-show-prev-entry-other-window

The arrow overlay is removed when other cscope functions are used.
Note that the arrow overlay is not an actual part of the text, and can
be removed by quitting the cscope buffer."
  :type 'boolean
  :group 'cscope)


(defcustom cscope-overlay-arrow-string "=>"
  "*The overlay string to use when displaying arrow overlays."
  :type 'string
  :group 'cscope)


(defcustom cscope-close-window-after-select nil
  "*If non-nil close the window showing the cscope buffer after an entry has been selected."
  :type 'boolean
  :group 'cscope)


(defvar cscope-minor-mode-hooks nil
  "List of hooks to call when entering cscope-minor-mode.")


(defconst cscope-result-separator
  "===============================================================================\n"
  "Line of text to use as a visual separator.
Must end with a newline. Must work as a regex without quoting")

(defconst cscope-file-separator-start-regex
  "\\*\\*\\* .*:\n"
  "Regex to match a file-start separator. This has to match the
'***' that xcscope.el normally outputs. This is assumed to appear
at the start of a line, so the leading ^ must be omitted")

(defconst cscope-file-separator-end-regex
  "\n"
  "Regex to match a file-end separator. This is just an empty
  line, and this has to match what xcscope.el normally outputs in
  its 'cscope-process-filter'. This is assumed to appear at the
  start of a line, so the leading ^ must be omitted")

;;;;
;;;; Faces for fontification
;;;;

(defcustom cscope-use-face t
  "*Whether to use text highlighting (à la font-lock) or not."
  :group 'cscope
  :type '(boolean))


(defface cscope-file-face
  '((((class color) (background dark))
     (:foreground "yellow"))
    (((class color) (background light))
     (:foreground "blue"))
    (t (:bold t)))
  "Face used to highlight file name in the *cscope* buffer."
  :group 'cscope)


(defface cscope-function-face
  '((((class color) (background dark))
     (:foreground "cyan"))
    (((class color) (background light))
     (:foreground "magenta"))
    (t (:bold t)))
  "Face used to highlight function name in the *cscope* buffer."
  :group 'cscope)


(defface cscope-line-number-face
  '((((class color) (background dark))
     (:foreground "red"))
    (((class color) (background light))
     (:foreground "red"))
    (t (:bold t)))
  "Face used to highlight line number in the *cscope* buffer."
  :group 'cscope)

(defface cscope-mouse-face
  '((((class color) (background dark))
     (:foreground "white" :background "blue"))
    (((class color) (background light))
     (:foreground "white" :background "blue"))
    (t (:bold nil)))
  "Face used when mouse pointer is within the region of an entry."
  :group 'cscope)

(defface cscope-separator-face
  '((((class color) (background dark))
     (:bold t :overline t :underline t :foreground "red"))
    (((class color) (background light))
     (:bold t :overline t :underline t :foreground "red"))
    (t (:bold t)))
  "Face used to highlight the separator in the *cscope* buffer."
  :group 'cscope)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Probably, nothing user-customizable past this point.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defconst cscope-running-in-xemacs (string-match "XEmacs\\|Lucid" emacs-version))

(defvar cscope-list-entry-keymap
  (let ((map (make-keymap)))
    (suppress-keymap map)
    ;; The following section does not appear in the "Cscope" menu.
    (if cscope-running-in-xemacs
        (progn
          (define-key map [button2]   'cscope-mouse-select-entry-other-window)
          (define-key map [S-button2] 'cscope-mouse-select-entry-inplace))
      (define-key map [mouse-2]   'cscope-mouse-select-entry-other-window)
      (define-key map [S-mouse-2] 'cscope-mouse-select-entry-inplace))

    ;; \r is for the text-mode console emacs
    (define-key map [return] 'cscope-select-entry-other-window)
    (define-key map "\r"     'cscope-select-entry-other-window)

    ;; this works for the graphics emacsen-only. Default xterm on Debian does
    ;; not know how to see this key combination
    (define-key map (kbd "<S-return>") 'cscope-select-entry-inplace)

    (define-key map " " 'cscope-show-entry-other-window)
    (define-key map "o" 'cscope-select-entry-one-window)
    (define-key map "q" 'cscope-bury-buffer)
    (define-key map "Q" 'cscope-quit)
    (define-key map "h" 'cscope-help)
    (define-key map "?" 'cscope-help)
    ;; The following line corresponds to be beginning of the "Cscope" menu.
    (define-key map "s" 'cscope-find-this-symbol)
    (define-key map "d" 'cscope-find-this-symbol)
    (define-key map "g" 'cscope-find-global-definition)
    (define-key map "G" 'cscope-find-global-definition-no-prompting)
    (define-key map "=" 'cscope-find-assignments-to-this-symbol)
    (define-key map "c" 'cscope-find-functions-calling-this-function)
    (define-key map "C" 'cscope-find-called-functions)
    (define-key map "t" 'cscope-find-this-text-string)
    (define-key map "e" 'cscope-find-egrep-pattern)
    (define-key map "f" 'cscope-find-this-file)
    (define-key map "i" 'cscope-find-files-including-file)
    ;; --- (The '---' indicates that this line corresponds to a menu separator.)
    (define-key map (kbd "p")   'cscope-history-backward-line)
    (define-key map (kbd "M-p") 'cscope-history-backward-file)
    (define-key map (kbd "P")   'cscope-history-backward-file)
    (define-key map (kbd "M-P") 'cscope-history-backward-result)
    (define-key map (kbd "n")   'cscope-history-forward-line)
    (define-key map (kbd "M-n") 'cscope-history-forward-file)
    (define-key map (kbd "N")   'cscope-history-forward-file)
    (define-key map (kbd "M-N") 'cscope-history-forward-result)
    (define-key map (kbd "k")   'cscope-history-kill-line)
    (define-key map (kbd "M-k") 'cscope-history-kill-file)
    (define-key map (kbd "M-K") 'cscope-history-kill-result)
    (define-key map "u"         'cscope-pop-mark)
    ;; ---
    (define-key map "r" 'cscope-rerun-search-at-point)
    ;; ---
    (define-key map "a" 'cscope-set-initial-directory)
    (define-key map "A" 'cscope-unset-initial-directory)
    ;; ---
    (define-key map "L" 'cscope-create-list-of-files-to-index)
    (define-key map "I" 'cscope-index-files)
    (define-key map "E" 'cscope-edit-list-of-files-to-index)
    (define-key map "W" 'cscope-tell-user-about-directory)
    (define-key map "S" 'cscope-tell-user-about-directory)
    (define-key map "T" 'cscope-tell-user-about-directory)
    (define-key map "D" 'cscope-dired-directory)
    ;; The previous line corresponds to be end of the "Cscope" menu.
    map)
  "The *cscope* buffer keymap")


(defvar cscope-list-entry-hook nil
  "*Hook run after cscope-list-entry-mode entered.")


(defun cscope-list-entry-mode ()
  "Major mode for jumping/showing entry from the list in the *cscope* buffer.

\\{cscope-list-entry-keymap}"
  (use-local-map cscope-list-entry-keymap)
  (setq mode-name "cscope"
	major-mode 'cscope-list-entry-mode
	overlay-arrow-string cscope-overlay-arrow-string)

  (add-hook 'kill-buffer-hook 'cscope-cleanup-overlay-arrow)
  (run-hooks 'cscope-list-entry-hook))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cscope-output-buffer-name "*cscope*"
  "The name of the cscope output buffer.")


(defvar cscope-info-buffer-name "*cscope-info*"
  "The name of the cscope information buffer.")


(defvar cscope-process nil
  "The current cscope process.")
(make-variable-buffer-local 'cscope-process)


(defvar cscope-process-output nil
  "A buffer for holding partial cscope process output.")
(make-variable-buffer-local 'cscope-process-output)


(defvar cscope-command-args nil
  "Internal variable for holding major command args to pass to cscope.")
(make-variable-buffer-local 'cscope-command-args)


(defvar cscope-start-directory nil
  "Internal variable used to save the initial start directory.
The results buffer gets reset to this directory when a search has
completely finished.")
(make-variable-buffer-local 'cscope-start-directory)


(defvar cscope-search-list nil
  "A list of (DIR . FLAGS) entries.
This is a list of database directories to search.  Each entry in the list
is a (DIR . FLAGS) cell.  DIR is the directory to search, and FLAGS are the
flags to pass to cscope when using this database directory.  FLAGS can be
nil (meaning, \"no flags\").")
(make-variable-buffer-local 'cscope-search-list)


(defvar cscope-searched-dirs nil
  "The list of database directories already searched.")
(make-variable-buffer-local 'cscope-searched-dirs)

(defvar cscope-last-file nil
  "The file referenced by the last line of cscope process output.")
(make-variable-buffer-local 'cscope-last-file)


(defvar cscope-start-time nil
  "The search start time, in seconds.")
(make-variable-buffer-local 'cscope-start-time)


(defvar cscope-first-match-point nil
  "Buffer location of the first match.")
(make-variable-buffer-local 'cscope-first-match-point)


(defvar cscope-output-start nil
  "The point location of the start of a search's output.")
(make-variable-buffer-local 'cscope-output-start)


(defvar cscope-matched-multiple nil
  "Non-nil if cscope output multiple matches.")
(make-variable-buffer-local 'cscope-matched-multiple)


(defvar cscope-stop-at-first-match-dir-meta nil
  "")
(make-variable-buffer-local 'cscope-stop-at-first-match-dir-meta)


(defvar cscope-fuzzy-search-range 1000
  "How far the point should be adjusted if the symbol is not on the line
specified by the cscope database.")

(defvar cscope-previous-user-search nil
  "A form that describes the last search that was executed. For
instance if the last search was to find all uses of the symbol
\"N\", this variable would be set to '(cscope-find-this-symbol
\"N\")")

(defvar cscope-marker nil
  "The location from which cscope was invoked.")


(defvar cscope-marker-window nil
  "The window which should contain cscope-marker.  This is the window from
which cscope-marker is set when searches are launched from the *cscope*
buffer.")


(defvar cscope-marker-ring-length 16
  "Length of the cscope marker ring.")


(defvar cscope-marker-ring (make-ring cscope-marker-ring-length)
  "Ring of markers which are locations from which cscope was invoked.")


(defvar cscope-initial-directory nil
  "When set the directory in which searches for the cscope database
directory should begin.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cscope-global-keymap
  (let ((map (make-sparse-keymap)))

    (if cscope-running-in-xemacs
        (progn
          (define-key map [button3]   'cscope-mouse-popup-menu-or-search)
          (define-key map [S-button3] 'cscope-mouse-search-again))
      (define-key map [mouse-3]   'cscope-mouse-popup-menu-or-search)
      (define-key map [S-mouse-3] 'cscope-mouse-search-again))

    ;; The following line corresponds to be beginning of the "Cscope" menu.
    (define-key map "\C-css" 'cscope-find-this-symbol)
    (define-key map "\C-csd" 'cscope-find-global-definition)
    (define-key map "\C-csg" 'cscope-find-global-definition)
    (define-key map "\C-csG" 'cscope-find-global-definition-no-prompting)
    (define-key map "\C-cs=" 'cscope-find-assignments-to-this-symbol)
    (define-key map "\C-csc" 'cscope-find-functions-calling-this-function)
    (define-key map "\C-csC" 'cscope-find-called-functions)
    (define-key map "\C-cst" 'cscope-find-this-text-string)
    (define-key map "\C-cse" 'cscope-find-egrep-pattern)
    (define-key map "\C-csf" 'cscope-find-this-file)
    (define-key map "\C-csi" 'cscope-find-files-including-file)
    ;; --- (The '---' indicates that this line corresponds to a menu separator.)
    (define-key map "\C-csb" 'cscope-display-buffer)
    (define-key map "\C-csB" 'cscope-display-buffer-toggle)
    (define-key map "\C-csn" 'cscope-history-forward-line-current-result)
    (define-key map "\C-csN" 'cscope-history-forward-file-current-result)
    (define-key map "\C-csp" 'cscope-history-backward-line-current-result)
    (define-key map "\C-csP" 'cscope-history-backward-file-current-result)
    (define-key map "\C-csu" 'cscope-pop-mark)
    ;; ---
    (define-key map "\C-csa" 'cscope-set-initial-directory)
    (define-key map "\C-csA" 'cscope-unset-initial-directory)
    ;; ---
    (define-key map "\C-csL" 'cscope-create-list-of-files-to-index)
    (define-key map "\C-csI" 'cscope-index-files)
    (define-key map "\C-csE" 'cscope-edit-list-of-files-to-index)
    (define-key map "\C-csW" 'cscope-tell-user-about-directory)
    (define-key map "\C-csS" 'cscope-tell-user-about-directory)
    (define-key map "\C-csT" 'cscope-tell-user-about-directory)
    (define-key map "\C-csD" 'cscope-dired-directory)
    ;; The previous line corresponds to be end of the "Cscope" menu.

    map)
  "The global cscope keymap")

(let ((menu-before
       '([ "Find symbol" cscope-find-this-symbol t ]
         [ "Find global definition" cscope-find-global-definition t ]
         [ "Find global definition no prompting"
           cscope-find-global-definition-no-prompting t ]
         [ "Find assignments to symbol"
           cscope-find-assignments-to-this-symbol t ]
         [ "Find functions calling a function"
           cscope-find-functions-calling-this-function t ]
         [ "Find called functions" cscope-find-called-functions t ]
         [ "Find text string" cscope-find-this-text-string t ]
         [ "Find egrep pattern" cscope-find-egrep-pattern t ]
         [ "Find a file" cscope-find-this-file t ]
         [ "Find files #including a file"
           cscope-find-files-including-file t ]
         "-----------"))

      (menu-only-global
       '([ "Display *cscope* buffer" cscope-display-buffer t ]
         "-----------"
         [ "Next symbol"             cscope-history-forward-line-current-result t ]
         [ "Next file"               cscope-history-forward-file-current-result t ]
         [ "Previous symbol"         cscope-history-backward-line-current-result t ]
         [ "Previous file"           cscope-history-backward-file-current-result t ]
         [ "Pop mark"                cscope-pop-mark t ]
         "-----------"
         ))

      (menu-only-cscope
       '([ "Next symbol"         cscope-history-forward-line t ]
         [ "Next file"           cscope-history-forward-file t ]
         [ "Next result"         cscope-history-forward-result t ]
         [ "Previous symbol"     cscope-history-backward-line t ]
         [ "Previous file"       cscope-history-backward-file t ]
         [ "Previous result"     cscope-history-backward-result t ]
         [ "Kill symbol"         cscope-history-kill-line t ]
         [ "Kill file"           cscope-history-kill-file t ]
         [ "Kill result"         cscope-history-kill-result t ]
         [ "Pop mark"            cscope-pop-mark t ]
         "-----------"
         [ "Rerun search at point"     cscope-rerun-search-at-point t ]
         "-----------"
         ))

      (menu-after
       '(( "Cscope Database"
           [ "Set initial directory"
             cscope-set-initial-directory t ]
           [ "Unset initial directory"
             cscope-unset-initial-directory t ]
           "-----------"
           [ "Create list of files to index"
             cscope-create-list-of-files-to-index t ]
           [ "Create list and index"
             cscope-index-files t ]
           [ "Edit list of files to index"
             cscope-edit-list-of-files-to-index t ]
           [ "Locate this buffer's cscope directory"
             cscope-tell-user-about-directory t ]
           [ "Dired this buffer's cscope directory"
             cscope-dired-directory t ]
           )
         "-----------"
         ( "Options"
           [ "Auto close *cscope* buffer"
             (setq cscope-close-window-after-select
                   (not cscope-close-window-after-select))
             :style toggle :selected cscope-close-window-after-select ]
           [ "Auto edit single match"
             (setq cscope-edit-single-match
                   (not cscope-edit-single-match))
             :style toggle :selected cscope-edit-single-match ]
           [ "Auto display *cscope* buffer"
             (setq cscope-display-cscope-buffer
                   (not cscope-display-cscope-buffer))
             :style toggle :selected cscope-display-cscope-buffer ]
           [ "Stop at first matching database"
             (setq cscope-stop-at-first-match-dir
                   (not cscope-stop-at-first-match-dir))
             :style toggle
             :selected cscope-stop-at-first-match-dir ]
           [ "Never update cscope database"
             (setq cscope-do-not-update-database
                   (not cscope-do-not-update-database))
             :style toggle :selected cscope-do-not-update-database ]
           [ "Index recursively"
             (setq cscope-index-recursively
                   (not cscope-index-recursively))
             :style toggle :selected cscope-index-recursively ]
           [ "Use relative paths"
             (setq cscope-use-relative-paths
                   (not cscope-use-relative-paths))
             :style toggle :selected cscope-use-relative-paths ]
           )
         )))

  (easy-menu-define cscope-global-menu
    cscope-global-keymap
    "cscope menu"
    `("Cscope" ,@menu-before ,@menu-only-global ,@menu-after))

  (easy-menu-define cscope-buffer-menu
     cscope-list-entry-keymap
    "cscope menu"
    `("Cscope" ,@menu-before ,@menu-only-cscope ,@menu-after)))


(defun cscope-mouse-popup-menu-or-search (event)
  "Pop-up the menu or rerun the last search when double-clicked.
EVENT is the mouse event."
  (interactive "e")
  (mouse-set-point event)
  (case (event-click-count event)
    (1 (cscope-popup-menu event))
    (2 (cscope-run-last-search-noprompt))
  )
)
(defun cscope-mouse-search-again (event)
  "Run the last search type again on the symbol the user clicked
on. EVENT is the mouse event."
  (interactive "e")
  (mouse-set-point event)
  (cscope-run-last-search-noprompt))

(defun cscope-popup-menu (event)
  "Pop up MENU and perform an action if something was selected.
EVENT is the mouse event."
  (save-selected-window
    (select-window (posn-window (event-start event)))
    (let ((selection (x-popup-menu event cscope-global-menu))
          binding)
      (while selection
	(setq binding (lookup-key (or binding cscope-global-menu) (vector (car selection)))
	      selection (cdr selection)))
      (when binding
        (let (cscope-suppress-user-symbol-prompt)
          (call-interactively binding))))))

(defun cscope-run-last-search-noprompt ()
  "Run the last search type off of the symbol at point without
prompting the user. This is mostly for mouse-initiated searches."
  (when cscope-previous-user-search
    (let (cscope-suppress-user-symbol-prompt)
      (call-interactively (car cscope-previous-user-search)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Internal functions and variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cscope-insert-with-text-properties (text filename &optional line-number line)
  "Insert an entry with given TEXT, add entry attributes as text
properties. Unlike 'cscope-make-entry-line' this function is
called both for cscope entry lines and cscope file lines

The text properties to be added:
- common property: mouse-face,
- properties are used to open target file and its location: cscope-file,
  cscope-line-number"
  (let (plist beg end)

    (when cscope-use-face
      (setq plist (plist-put plist 'mouse-face 'cscope-mouse-face)))

    (setq beg (point))
    (insert text)
    (setq end (point)
	  plist (plist-put plist 'cscope-file filename))
    (when line-number
      (when (stringp line-number)
        (setq line-number (string-to-number line-number)))
      (setq plist (plist-put plist 'cscope-line-number line-number)))

    (add-text-properties beg end plist)
    ))


(if cscope-running-in-xemacs
    (progn
      (defalias 'cscope-event-window 'event-window)
      (defalias 'cscope-event-point 'event-point)
      (defalias 'cscope-recenter 'recenter)
      )
  (defun cscope-event-window (event)
    "Return the window at which the mouse EVENT occurred."
    (posn-window (event-start event)))
  (defun cscope-event-point (event)
    "Return the point at which the mouse EVENT occurred."
    (posn-point (event-start event)))
  (defun cscope-recenter (&optional n window)
    "Center point in WINDOW and redisplay frame.  With N, put point on line N."
    (save-selected-window
      (if (windowp window)
	  (select-window window))
      (recenter n)))
  )


(defun cscope-show-entry-internal (navprops
                                   &optional save-mark-p window arrow-p)
  "Display the buffer corresponding to FILE and LINE-NUMBER
in some window.  If optional argument WINDOW is given,
display the buffer in that WINDOW instead.  The window is
not selected.  Save point on mark ring before goto
LINE-NUMBER if optional argument SAVE-MARK-P is non-nil.
Put `overlay-arrow-string' if arrow-p is non-nil.
Returns the window displaying BUFFER."
  (let ( (file                     (elt navprops 0))
         (line-number              (or (elt navprops 1) -1))
         (fuzzy-search-text-regexp (elt navprops 2))
         buffer old-pos old-point new-point forward-point backward-point
         line-end line-length)
    (if (and (stringp file)
	     (integerp line-number))
	(progn
	  (unless (file-readable-p file)
	    (error "%s is not readable or exists" file))
	  (setq buffer (find-file-noselect file))
	  (if (windowp window)
	      (set-window-buffer window buffer)
	    (setq window (display-buffer buffer)))
	  (set-buffer buffer)
	  (if (> line-number 0)
	      (progn
		(setq old-pos (point))
		(goto-line line-number)
		(setq old-point (point))

                ;; Here I perform a fuzzy search. If the user has edited the
                ;; sources after building the cscope database, cscope may have
                ;; the wrong line numbers. Here I try to correct for this by
                ;; finding the cscope results in the text around where cscope
                ;; said they should appear. There is a choice here: I could look
                ;; for the original string the user searched for, or I can look
                ;; for the longer string that cscope has found. I do the latter
		(if (and fuzzy-search-text-regexp cscope-fuzzy-search-range)
		    (progn
		      ;; Calculate the length of the line specified by cscope.
		      (end-of-line)
		      (setq line-end (point))
		      (goto-char old-point)
		      (setq line-length (- line-end old-point))

		      ;; Search forward and backward for the pattern.
		      (setq forward-point (re-search-forward
					   fuzzy-search-text-regexp
					   (+ old-point
					      cscope-fuzzy-search-range) t))
		      (goto-char old-point)
		      (setq backward-point (re-search-backward
					    fuzzy-search-text-regexp
					    (- old-point
					       cscope-fuzzy-search-range) t))
		      (if forward-point
			  (progn
			    (if backward-point
				(setq new-point
				      ;; Use whichever of forward-point or
				      ;; backward-point is closest to old-point.
				      ;; Give forward-point a line-length advantage
				      ;; so that if the symbol is on the current
				      ;; line the current line is chosen.
				      (if (<= (- (- forward-point line-length)
						 old-point)
					      (- old-point backward-point))
					  forward-point
					backward-point))
			      (setq new-point forward-point)))
			(if backward-point
			    (setq new-point backward-point)
			  (setq new-point old-point)))
		      (goto-char new-point)
		      (beginning-of-line)
		      (setq new-point (point)))
		  (setq new-point old-point))
		(set-window-point window new-point)

                ;; if we're using an arrow overlay....
		(if (and cscope-allow-arrow-overlays arrow-p)
                    (set-marker

                     ;; ... set the existing marker if there is one, or make a
                     ;; new one ...
                     (or overlay-arrow-position
                         (setq overlay-arrow-position (make-marker)))

                     ;; ... at point
                     (point))

                  ;; if we need to remove a marker, do that if there is one
                  (when overlay-arrow-position
                    (set-marker overlay-arrow-position nil)))

		(or (not save-mark-p)
		    (= old-pos (point))
		    (push-mark old-pos))
		))

	  (if cscope-marker
	      (progn ;; The search was successful.  Save the marker so it
                     ;; can be returned to by cscope-pop-mark.
		(ring-insert cscope-marker-ring cscope-marker)
		;; Unset cscope-marker so that moving between matches does not
		;; fill cscope-marker-ring.
		(setq cscope-marker nil)))
          (setq cscope-marker-window window)
	  )
      (message "No entry found at point."))
    )
  window)

(defun cscope-find-this-separator-start (separator-regex from &optional strict)
  "Finds the start of the given separator before FROM.
If FROM is anywhere in a separator string, this separator is
used. If STRICT is non-nil this function returns nil if no
separator is found. Otherwise '(point-min)' is returned"

  ;; if we're below (point-min), give up. This can happen when trying to search
  ;; before eob. For instance, trying to find the prev result from eob
  (if (< from (point-min))
      (if strict nil (point-min))

    (let ((separator-regex-at-bol (concat "^" separator-regex)))
      (save-excursion
        (goto-char from)
        (beginning-of-line)

        ;; if we're at the separator, use it
        (if (looking-at separator-regex) (point)

          ;; otherwise, find the previous separator
          (or
           (re-search-backward separator-regex-at-bol nil t nil)

           ;; if there isn't one, use the start of the buffer
           (if strict nil (point-min))))))))

(defun cscope-find-next-separator-start (separator-regex from &optional strict)
  "Finds the next start of the given separator after FROM.
If FROM is anywhere in a separator string, the next separator is
used. If STRICT is non-nil this function returns nil if no
separator is found. Otherwise '(point-min)' is returned"

  (let ((separator-regex-at-bol (concat "^" separator-regex)))
    (save-excursion
      (goto-char from)

      ;; try to find the next separator (start a bit forward to not find
      ;; the current one).
      (if (progn (forward-char)
                 (re-search-forward separator-regex-at-bol nil t nil))

          ;; if there is a next one, navigate to its start, and use it
          (progn
            (forward-line -1)
            (beginning-of-line)
            (point))

        ;; otherwise, use the end of the buffer
        (if strict nil (point-max))))))

(defun cscope-get-history-bounds-this-result-internal (start-regex &optional end-regex)
  "Returns a list of the beginning and the end of the results
at (point). If END-REGEX is nil, the START-REGEX is used for both
the start and end bounds; the region then contains the start
separator, but not the end separator. If END-REGEX is non-nil, it
is used to find the end bound, and the region then contains both
separators. If some error has occured or if (point) isn't within
the computed bounds then nil is returned"

  (let* ((beg (cscope-find-this-separator-start start-regex (point)))
         (end
          (if end-regex
              ;; we have an end regex
              (save-excursion
                (goto-char beg)
                (re-search-forward (concat "^" end-regex) nil t nil))

            ;; no end regex given. use the start regex
            (cscope-find-next-separator-start start-regex beg))))

    ;; return the list if both bounds exist, and the original point is
    ;; within those bounds
    (if (and beg
             end
             (>= (point) beg)
             (or (< (point) end)
                 (and (eobp) (= (point) end))))
        (list beg end)
      nil)))

(defun cscope-get-history-bounds-this-result (which)
  "Convenience wrapper around
'cscope-get-history-bounds-this-result-internal'. WHICH is
'result to ask for result bounds or 'file to ask for file bounds"
  (cond
   ((eq which 'result) (cscope-get-history-bounds-this-result-internal cscope-result-separator))
   ((eq which 'file)   (cscope-get-history-bounds-this-result-internal cscope-file-separator-start-regex
                                                                       cscope-file-separator-end-regex))
   (t                  (error "cscope-get-history-bounds-this-result knows only about 'result and 'file"))))


(defun cscope-get-navigation-properties (&optional at buffer)
  "Reads the cscope navigation properties on this line. The
properties themselves are read from the beginning of the line,
since the trailing newline is NOT propertized."
  (with-current-buffer (or buffer (current-buffer))
    (save-excursion
      (when at (goto-char at))
      (beginning-of-line)
      (vector (get-text-property (point) 'cscope-file)
              (get-text-property (point) 'cscope-line-number)
              (get-text-property (point) 'cscope-fuzzy-search-text-regexp)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; functions in *cscope* buffer which lists the search results
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cscope-select-entry-other-window ()
  "Display the entry at point in other window, select the window.
Push current point on mark ring and select the entry window."
  (interactive)
  (let ((navprops (cscope-get-navigation-properties))
	window)
    (setq window (cscope-show-entry-internal navprops t))
    (if (windowp window)
	(select-window window))
    )
  (if cscope-close-window-after-select
    (delete-windows-on cscope-output-buffer-name)))

(defun cscope-select-entry-inplace ()
  "Display the entry in the window currently occupied by the
*cscope* buffer"
  (interactive)

  (let ((navprops (cscope-get-navigation-properties))
	window)
    (cscope-show-entry-internal navprops t (selected-window))))

(defun cscope-select-entry-one-window ()
  "Display the entry at point in one window, select the window."
  (interactive)
  (let ((navprops (cscope-get-navigation-properties))
	window)
    (setq window (cscope-show-entry-internal navprops t))
    (if (windowp window)
	(progn
	  (select-window window)
	  (sit-for 0)	;; Redisplay hack to allow delete-other-windows
			;; to continue displaying the correct location.
	  (delete-other-windows window)
	  ))
    ))


(defun cscope-select-entry-specified-window (window)
  "Display the entry at point in a specified window, select the window."
  (interactive)
  (let ((navprops (cscope-get-navigation-properties)))
    (setq window (cscope-show-entry-internal navprops t window))
    (if (windowp window)
	  (select-window window))
    ))


(defun cscope-mouse-select-entry-other-window (event)
  "Display the entry over which the mouse event occurred, select the window."
  (interactive "e")
  (let ((ep (cscope-event-point event))
	(win (cscope-event-window event))
	window)
    (if ep
        (progn
          (let ((navprops (cscope-get-navigation-properties ep (window-buffer win))))
            (select-window win)
            (setq window (cscope-show-entry-internal navprops t)))
          (if (windowp window)
              (select-window window)))
      (message "No entry found at point.")
      )
    ))

(defun cscope-mouse-select-entry-inplace (event)
  "Display the entry over which the mouse event occurred, select the window."
  (interactive "e")
  (let ((ep (cscope-event-point event))
	(win (cscope-event-window event)))
    (if ep
        (progn
          (let ((navprops (cscope-get-navigation-properties ep (window-buffer win))))
            (select-window win)
            (cscope-show-entry-internal navprops t win)))
      (message "No entry found at point.")
      )
    ))


(defun cscope-show-entry-other-window ()
  "Display the entry at point in other window.
Point is not saved on mark ring."
  (interactive)
  (let ((navprops (cscope-get-navigation-properties)))
    (cscope-show-entry-internal navprops nil nil t)
    ))


(defun cscope-display-buffer ()
  "Display the *cscope* buffer."
  (interactive)
  (let ((buffer (get-buffer cscope-output-buffer-name)))
    (if buffer
        (pop-to-buffer buffer)
      (error "The *cscope* buffer does not exist yet"))))


(defun cscope-display-buffer-toggle ()
  "Toggle cscope-display-cscope-buffer, which corresponds to
\"Auto display *cscope* buffer\"."
  (interactive)
  (setq cscope-display-cscope-buffer (not cscope-display-cscope-buffer))
  (message "The cscope-display-cscope-buffer variable is now %s."
           (if cscope-display-cscope-buffer "set" "unset")))

(defun cscope-navigate-and-show (forms &optional no-show)
  "This evaluates the navigation FORMS. These FORMS move the
point in the *cscope* buffer, and this function shows the result
in the source"

  (let* (old-point
         point
         (old-buffer (current-buffer))
         (old-buffer-window (get-buffer-window old-buffer))
         (cscope-buffer (get-buffer cscope-output-buffer-name))
         (buffer-window (get-buffer-window (or cscope-buffer (error "The *cscope* buffer does not exist yet"))))
         )
    (set-buffer cscope-buffer)
    (setq old-point (point))

    ;; I can now evaluate the forms
    (let ((forms-result

           ;; if we're limiting to this result then ...
           (if limit-to-current-result
               (let ((bounds (cscope-get-history-bounds-this-result 'result)))
                 (unless bounds (error "Couldn't find result bounds"))

                 ;; ... narrow to this result before evaluating ...
                 (save-restriction
                   (apply 'narrow-to-region bounds)
                   (eval forms)))

             ;; ... otherwise just evaluate
             (eval forms))))

      (unless forms-result
        (goto-char old-point)
        (error "Can't move further")))

    (setq point (point))

    (unless no-show
      (if (eq old-buffer cscope-buffer) ;; In the *cscope* buffer.
          (cscope-show-entry-other-window)
        (cscope-select-entry-specified-window old-buffer-window) ;; else
        (if (windowp buffer-window)
            (set-window-point buffer-window point))))
    (set-buffer old-buffer)))

(defun cscope-history-forward-backward (separator-regex do-next)
  "Body for 'cscope-history-forward-result'/'cscope-history-backward-result'
and 'cscope-history-forward-file'/'cscope-history-backward-file'"
  (let ((target-point
         (cond
          (do-next (cscope-find-next-separator-start separator-regex (point) t))
          (t       (cscope-find-this-separator-start separator-regex
                                                     (- (point) (if (looking-at separator-regex) 1 0)) t)))))
    (when target-point (goto-char target-point))))

(defun cscope-history-forward-result ( &optional limit-to-current-result )
  "Navigate to the next stored search results in the *cscope*
buffer."
  (interactive)
  (cscope-navigate-and-show
   '(cscope-history-forward-backward cscope-result-separator t) t))

(defun cscope-history-backward-result ( &optional limit-to-current-result )
  "Navigate to the previous stored search results in the *cscope*
buffer."
  (interactive)
  (cscope-navigate-and-show
   '(cscope-history-forward-backward cscope-result-separator nil) t))

(defun cscope-history-kill-result ()
  "Delete a cscope result from the *cscope* buffer."
  (interactive)
  (let ((bounds (cscope-get-history-bounds-this-result 'result)))
    (if bounds (apply 'delete-region bounds)
      (error "Nothing to kill"))))

(defun cscope-history-forward-file ( &optional limit-to-current-result )
  "Navigate to the next file results in the *cscope* buffer."
  (interactive)
  (cscope-navigate-and-show
   '(cscope-history-forward-backward cscope-file-separator-start-regex t)))

(defun cscope-history-forward-file-current-result ()
  "Like (cscope-history-forward-file), but limited to the current
result only. This exists for blind navigation. If the user isn't
looking at the *cscope* buffer, they shouldn't be jumping between
results"
  (interactive)
  (cscope-history-forward-file t))

(defun cscope-history-backward-file ( &optional limit-to-current-result )
  "Navigate to the previous file results in the *cscope* buffer."
  (interactive)
  (cscope-navigate-and-show
   '(cscope-history-forward-backward cscope-file-separator-start-regex nil)))

(defun cscope-history-backward-file-current-result ()
  "Like (cscope-history-backward-file), but limited to the current
result only. This exists for blind navigation. If the user isn't
looking at the *cscope* buffer, they shouldn't be jumping between
results"
  (interactive)
  (cscope-history-backward-file t))

(defun cscope-history-kill-file ()
  "Delete a cscope file set from the *cscope* buffer."
  (interactive)
  (let ((bounds (cscope-get-history-bounds-this-result 'file)))
    (if bounds
        (progn
          (apply 'delete-region bounds)
          (cscope-history-kill-if-empty 'result))
      (error "Nothing to kill"))))

(defun cscope-history-forward-line ( &optional limit-to-current-result )
  "Navigate to the next result line in the *cscope* buffer."
  (interactive)

  (cscope-navigate-and-show
   '(let ((target
           (let ((at (save-excursion
                       (end-of-line)
                       (point))))
             (next-single-property-change at 'cscope-line-number))))
      (when target (goto-char target)))))

(defun cscope-history-forward-line-current-result ()
  "Like (cscope-history-forward-line), but limited to the current
result only. This exists for blind navigation. If the user isn't
looking at the *cscope* buffer, they shouldn't be jumping between
results"
  (interactive)
  (cscope-history-forward-line t))

(defun cscope-history-backward-line ( &optional limit-to-current-result )
  "Navigate to the previous result line in the *cscope* buffer."
  (interactive)

  (cscope-navigate-and-show
   '(let ((target
           (let ((at (save-excursion
                       (beginning-of-line)
                       (previous-single-property-change (point) 'cscope-line-number))))
             (and at (previous-single-property-change at 'cscope-line-number)))))
      (when target (goto-char target)))))

(defun cscope-history-backward-line-current-result ()
  "Like (cscope-history-backward-line), but limited to the current
result only. This exists for blind navigation. If the user isn't
looking at the *cscope* buffer, they shouldn't be jumping between
results"
  (interactive)
  (cscope-history-backward-line t))

(defun cscope-history-kill-line ()
  "Delete a cscope line from the *cscope* buffer."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (if (get-text-property (point) 'cscope-line-number)
        (progn
          (delete-region (point) (progn (forward-line 1) (point)))
          (cscope-history-kill-if-empty 'file))
      (error "Nothing to kill"))))

(defun cscope-history-kill-if-empty (which)
  "Kills object specified by WHICH, if it is empty. WHICH is
either 'result or 'file"
  (let ((bounds (cscope-get-history-bounds-this-result which)))
    (unless
        ;; not-empty condition computed here; different depending on WHICH
        (cond
         ((eq which 'file)
          (let ((nextpropchange (next-single-property-change (car bounds) 'cscope-line-number nil (cadr bounds))))
            (and nextpropchange
                (/= nextpropchange (cadr bounds)))))
         ((eq which 'result)

          (save-excursion
            (goto-char (car bounds))
            (re-search-forward (concat "^" cscope-file-separator-start-regex) (cadr bounds) t nil)))
         (t (error "cscope-history-kill-if-empty given unknown argument")))

      (apply 'delete-region bounds)
      (when (eq which 'file)
        (cscope-history-kill-if-empty 'result)))))

(defun cscope-pop-mark ()
  "Pop back to where cscope was last invoked."
  (interactive)

  ;; This function is based on pop-tag-mark, which can be found in
  ;; lisp/progmodes/etags.el.

  (if (ring-empty-p cscope-marker-ring)
      (error "There are no marked buffers in the cscope-marker-ring yet"))
  (let* ( (marker (ring-remove cscope-marker-ring 0))
	  (old-buffer (current-buffer))
	  (marker-buffer (marker-buffer marker))
	  marker-window
	  (marker-point (marker-position marker))
	  (cscope-buffer (get-buffer cscope-output-buffer-name)) )

    ;; After the following both cscope-marker-ring and cscope-marker will be
    ;; in the state they were immediately after the last search.  This way if
    ;; the user now makes a selection in the previously generated *cscope*
    ;; buffer things will behave the same way as if that selection had been
    ;; made immediately after the last search.
    (setq cscope-marker marker)

    (if marker-buffer
	(if (eq old-buffer cscope-buffer)
	    (progn ;; In the *cscope* buffer.
	      (set-buffer marker-buffer)
	      (setq marker-window (display-buffer marker-buffer))
	      (set-window-point marker-window marker-point)
	      (select-window marker-window))
	  (switch-to-buffer marker-buffer))
      (error "The marked buffer has been deleted"))
    (goto-char marker-point)
    (set-buffer old-buffer)))

(defun cscope-rerun-search-at-point ()
  "Re-runs the search at the point of the *cscope* buffer. Result
modified in-place"
  (interactive)

  (unless (eq (get-buffer cscope-output-buffer-name) (current-buffer))
    (error "(cscope-rerun-search-at-point) only makes sense from a *cscope* buffer"))

  (when cscope-process
    (error "A cscope search is still in progress -- only one at a time is allowed"))

  ;; move to where we were after the search is done??
  (let ((beg-end (cscope-get-history-bounds-this-result 'result)))
    (if beg-end
        (let* ((beg (elt beg-end 0))
               (end (elt beg-end 1))
               (search (get-text-property beg 'cscope-stored-search))

               ;; try to rerun the search in the same directory as before
               (cscope-initial-directory (or cscope-initial-directory
                                             (get-text-property beg 'cscope-directory)))
               cscope-rerunning-search ;; this is bound here to tell cscope-call to not move the point
               )
          (delete-region beg end)
          (goto-char beg)
          (eval search))
      (error "No result at point"))))

(defun cscope-set-initial-directory (cs-id)
  "Set the cscope-initial-directory variable.  The
cscope-initial-directory variable, when set, specifies the directory
where searches for the cscope database directory should begin.  This
overrides the current directory, which would otherwise be used."
  (interactive "DCscope Initial Directory: ")
  (setq cscope-initial-directory cs-id))


(defun cscope-unset-initial-directory ()
  "Unset the cscope-initial-directory variable."
  (interactive)
  (setq cscope-initial-directory nil)
  (message "The cscope-initial-directory variable is now unset."))


(defun cscope-help ()
  (interactive)
  (message
   (format "RET=%s, SPC=%s, o=%s, n=%s, p=%s, q=%s, h=%s"
	   "Select"
	   "Show"
	   "SelectOneWin"
	   "ShowNext"
	   "ShowPrev"
	   "Quit"
	   "Help")))

(defun cscope-cleanup-overlay-arrow ()
  (when overlay-arrow-position
    (set-marker overlay-arrow-position nil)
    (setq overlay-arrow-position nil
          overlay-arrow-string nil)))

(defun cscope-bury-buffer ()
  "Clean up cscope, if necessary, and bury the buffer."
  (interactive)
  (cscope-cleanup-overlay-arrow)
  (bury-buffer))



(defun cscope-quit ()
  (interactive)
  (cscope-bury-buffer)
  (kill-buffer cscope-output-buffer-name)
  )


(defun cscope-boldify-if-needed (&rest args)
  "Returns a string in a bold face that's a concatenation of ARGS.
This is done if 'cscope-use-face' is non-nil. Otherwise a plain
concatenation of ARGS is returned"
  (let ((str (apply 'concat args)))
    (if cscope-use-face
        (propertize str 'face 'bold)
      str)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cscope-canonicalize-directory (dir)
  (or dir
      (setq dir default-directory))
  (setq dir (file-name-as-directory
	     (expand-file-name (substitute-in-file-name dir))))
  dir
  )


(defun cscope-search-directory-hierarchy (directory)
  "Look for a cscope database in the directory hierarchy.
Starting from DIRECTORY, look upwards for a cscope database."
  (let (this-directory database-dir)
    (catch 'done
      (if (file-regular-p directory)
	  (throw 'done directory))
      (setq directory (cscope-canonicalize-directory directory)
	    this-directory directory)
      (while this-directory
	(if (or (file-exists-p (concat this-directory cscope-database-file))
		(file-exists-p (concat this-directory cscope-index-file)))
	    (progn
	      (setq database-dir this-directory)
	      (throw 'done database-dir)
	      ))
	(if (string-match "^\\(/\\|[A-Za-z]:[\\/]\\)$" this-directory)
	    (throw 'done directory))
	(setq this-directory (file-name-as-directory
			      (file-name-directory
			       (directory-file-name this-directory))))
	))
    ))


(defun cscope-find-info (top-directory)
  "Locate a suitable cscope database directory.
First, `cscope-database-regexps' is used to search for a suitable
database directory.  If a database location cannot be found using this
variable, then the current directory is searched, then the parent,
then the parent's parent, until a cscope database directory is found,
or the root directory is reached.  If the root directory is reached,
the current directory will be used."
  (let (info regexps dir-regexp this-directory)
    (setq top-directory (cscope-canonicalize-directory
			 (or top-directory cscope-initial-directory)))
    (catch 'done
      ;; Try searching using `cscope-database-regexps' ...
      (setq regexps cscope-database-regexps)
      (while regexps
	(setq dir-regexp (car (car regexps)))
	(cond
	 ( (stringp dir-regexp)
	   (if (string-match dir-regexp top-directory)
	       (progn
		 (setq info (cdr (car regexps)))
		 (throw 'done t)
		 )) )
	 ( (and (symbolp dir-regexp) dir-regexp)
	   (progn
	     (setq info (cdr (car regexps)))
	     (throw 'done t)
	     ) ))
	(setq regexps (cdr regexps))
	)

      ;; Try looking in the directory hierarchy ...
      (if (setq this-directory
		(cscope-search-directory-hierarchy top-directory))
	  (progn
	    (setq info (list (list this-directory)))
	    (throw 'done t)
	    ))

      ;; Should we add any more places to look?

      )		;; end catch
    (if (not info)
	(setq info (list (list top-directory))))
    info
    ))


(defun cscope-make-entry-line (func-name line-number line)
  "Makes a propertized line containing a single cscope result.
This function sets up face and the fuzzy-search string"

  ;; The format of entry line:
  ;; func-name[line-number]______line
  ;; <- cscope-name-line-width ->
  ;; `format' of Emacs doesn't have "*s" spec.
  (let ((str (format (format "%%%ds %%s" cscope-name-line-width)
                     (format "%s[%s]" func-name line-number) line))
        (search-type   (car cscope-previous-user-search))
        (search-symbol (cadr cscope-previous-user-search))
	beg end)

    ;; I set up the 'cscope-fuzzy-search-text-regexp property to allow fuzzy
    ;; searches to work. cscope collapses spaces for some reason, so I explictly
    ;; look for an arbitrary amounts of whitespace
    (unless (string= line "<unknown>")
      (let ((fuzzy-search-text-regexp
             (mapconcat 'regexp-quote
                        (split-string line "[ \f\t\n\r\v]+\\|\\b" t) "\\s-*")))

        (put-text-property 0 (length str) 'cscope-fuzzy-search-text-regexp fuzzy-search-text-regexp str)))

    ;; now I set up the face properties
    (when cscope-use-face
      (setq end (length func-name))
      (put-text-property 0 end 'face 'cscope-function-face str)
      (setq beg (1+ end)
            end (+ beg (length line-number)))
      (put-text-property beg end 'face 'cscope-line-number-face str)

      (when (not (string= line "<unknown>"))
        (let* ((search-type   (car cscope-previous-user-search))
               (search-symbol (cadr cscope-previous-user-search))

               ;; nothing to highlight for search types where the sought symbol isn't
               ;; expected to appear at a matched result line. If we're not searching
               ;; for a regex, quote the string to effectively search for plain text
               (highlight-search-re
                (if (or (eq search-type 'cscope-find-this-file)
                        (eq search-type 'cscope-find-called-functions))
                    nil
                  (if (eq search-type 'cscope-find-egrep-pattern)
                      search-symbol
                    (regexp-quote search-symbol)))))

          (when highlight-search-re

            ;; unless we're searching for plain text strings, the tokens we seek
            ;; are full words, so we limit ourselves to those
            (unless (or (eq search-type 'cscope-find-egrep-pattern)
                        (eq search-type 'cscope-find-this-text-string))
              (setq highlight-search-re (concat "\\b" highlight-search-re "\\b")))

            (let* ((case-fold-search nil)
                   (start (string-match
                           highlight-search-re
                           str beg)))
              (when start
                (put-text-property start (match-end 0) 'face 'bold str)))))))

    str))


(defun cscope-process-filter (process output)
  "Accept cscope process output and reformat it for human readability.
Magic text properties are added to allow the user to select lines
using the mouse."
  (let ( (old-buffer (current-buffer)) )
    (with-current-buffer (process-buffer process)
      (let (line file function-name line-number)
        (save-excursion
          (goto-char (process-mark process))
          ;; Get the output thus far ...
          (if cscope-process-output
              (setq cscope-process-output (concat cscope-process-output
                                                  output))
            (setq cscope-process-output output))
          ;; Slice and dice it into lines.
          ;; While there are whole lines left ...
          (while (and cscope-process-output
                      (string-match "\\([^\n]+\n\\)\\(\\(.\\|\n\\)*\\)"
                                    cscope-process-output))
            (setq file				nil
                  glimpse-stripped-directory	nil
                  )
            ;; Get a line
            (setq line (substring cscope-process-output
                                  (match-beginning 1) (match-end 1)))
            (setq cscope-process-output (substring cscope-process-output
                                                   (match-beginning 2)
                                                   (match-end 2)))
            (if (= (length cscope-process-output) 0)
                (setq cscope-process-output nil))

            ;; This should always match.
            (if (string-match
                 "^\\([^ \t]+\\)[ \t]+\\([^ \t]+\\)[ \t]+\\([0-9]+\\)[ \t]+\\(.*\\)\n"
                 line)
                (progn
                  (let (str)
                    (setq file (substring line (match-beginning 1)
                                          (match-end 1))
                          function-name (substring line (match-beginning 2)
                                                   (match-end 2))
                          line-number (substring line (match-beginning 3)
                                                 (match-end 3))
                          line (substring line (match-beginning 4)
                                          (match-end 4))
                          )
                    ;; If the current file is not the same as the previous
                    ;; one ...
                    (if (not (and cscope-last-file
                                  (string= file cscope-last-file)))
                        (progn
                          ;; The current file is different.

                          ;; Insert a separating blank line if
                          ;; necessary.
                          (if cscope-last-file (insert "\n"))
                          ;; Insert the file name
                          (setq str (concat "*** " file ":"))
                          (if cscope-use-face
                              (put-text-property 0 (length str)
                                                 'face 'cscope-file-face
                                                 str))
                          (cscope-insert-with-text-properties
                           str
                           (expand-file-name file))
                          (insert "\n")))

                    (if cscope-first-match-point
                        (setq cscope-matched-multiple t)
                      (setq cscope-first-match-point (point)))

                    ;; ... and insert the line, with the
                    ;; appropriate indentation.
                    (cscope-insert-with-text-properties
                     (cscope-make-entry-line function-name
                                             line-number
                                             line)
                     (expand-file-name file)
                     line-number
                     line)
                    (insert "\n")
                    (setq cscope-last-file file)
                    ))
              (insert line "\n")
              ))
          (set-marker (process-mark process) (point))
          )
        (set-buffer-modified-p nil)))))


(defun cscope-process-sentinel (process event)
  "Sentinel for when the cscope process dies."
  (let* ((buffer (process-buffer process)) window update-window
         (done t)
         (old-buffer (current-buffer))
	 (old-buffer-window (get-buffer-window old-buffer)) )

    (with-current-buffer buffer
      (let (continue)
        (save-excursion
          (goto-char (process-mark process))

          (if (or (and (setq window (get-buffer-window buffer))
                       (= (window-point window) (point-max)))
                  (= (point) (point-max)))
              (setq update-window t))
          (delete-process process)

          (when (= cscope-output-start (point))
            (insert " --- No matches were found ---\n"))
          
          (when (not cscope-start-directory)
            (setq cscope-start-directory default-directory))

          (setq continue
                (and cscope-search-list
                     (not (and cscope-first-match-point
                               cscope-stop-at-first-match-dir
                               (not cscope-stop-at-first-match-dir-meta)))))
          (when continue
            (setq continue (cscope-search-one-database)))
          (if continue
              (setq done nil)
            (insert "\nSearch complete.")
            (if cscope-display-times
                (let ( (times (current-time)) cscope-stop elapsed-time )
                  (setq cscope-stop (+ (* (car times) 65536.0)
                                       (car (cdr times))
                                       (* (car (cdr (cdr times))) 1.0E-6)))
                  (setq elapsed-time (- cscope-stop cscope-start-time))
                  (insert (format "  Search time = %.2f seconds."
                                  elapsed-time))
                  ))
            (insert "\n")
            (setq cscope-process nil)
            (if cscope-running-in-xemacs
                (setq modeline-process ": Search complete"))

            ;; save the directory of this search
            (let ((search-start-point (cscope-find-this-separator-start cscope-result-separator (1- (point)) t)))
              (put-text-property search-start-point (point) 'cscope-directory default-directory))

            (if cscope-start-directory
                (setq default-directory cscope-start-directory)))
          (set-buffer-modified-p nil))

        (if (and done cscope-first-match-point update-window)
            (if window
                (set-window-point window cscope-first-match-point)
              (goto-char cscope-first-match-point))
          )

        (when cscope-first-match-point
          (if cscope-display-cscope-buffer
              (if (and cscope-edit-single-match (not cscope-matched-multiple))
                  (cscope-show-entry-internal
                   (cscope-get-navigation-properties cscope-first-match-point (process-buffer process))
                   t))
            (cscope-select-entry-specified-window old-buffer-window)))

        ;; if the *cscope* buffer is too long, truncate it
        (with-current-buffer (process-buffer process)
          (when (and done
                     (> cscope-max-cscope-buffer-size 0)
                     (> (- (point-max) (point-min)) cscope-max-cscope-buffer-size))

            (save-excursion
              (goto-char (point-max))
              (let ((cut-at-point (cscope-find-this-separator-start
                                   cscope-result-separator
                                   (- (point-max) cscope-max-cscope-buffer-size)
                                   t)))
                (when cut-at-point
                  (delete-region (point-min) cut-at-point))))))

        (if (and done (eq old-buffer buffer) cscope-first-match-point)
            (cscope-help))))))



(defun cscope-search-one-database ()
  "Pop a database entry from cscope-search-list and do a search there."
  (let ( next-item options cscope-directory database-file outbuf done
		   base-database-file-name)
    (setq outbuf (get-buffer-create cscope-output-buffer-name))
    (save-excursion
      (catch 'finished
	(set-buffer outbuf)
	(setq options '("-L"))
	(while (and (not done) cscope-search-list)
	  (setq next-item (car cscope-search-list)
		cscope-search-list (cdr cscope-search-list)
		base-database-file-name cscope-database-file
		)
	  (if (listp next-item)
	      (progn
		(setq cscope-directory (car next-item))
		(if (not (stringp cscope-directory))
		    (setq cscope-directory
			  (cscope-search-directory-hierarchy
			   default-directory)))
		(if (file-regular-p cscope-directory)
		    (progn
		      ;; Handle the case where `cscope-directory' is really
		      ;; a full path name to a cscope database.
		      (setq base-database-file-name
			    (file-name-nondirectory cscope-directory)
			    cscope-directory
			    (file-name-directory cscope-directory))
		      ))
		(setq cscope-directory 
		      (file-name-as-directory cscope-directory))
		(if (not (member cscope-directory cscope-searched-dirs))
		    (progn
		      (setq cscope-searched-dirs (cons cscope-directory
						       cscope-searched-dirs)
			    done t)
		      ))
		)
	    (progn
	      (if (and cscope-first-match-point
		       cscope-stop-at-first-match-dir
		       cscope-stop-at-first-match-dir-meta)
		  (throw 'finished nil))
	      ))
	  )
	(if (not done)
	    (throw 'finished nil))
	(if (car (cdr next-item))
	    (let (newopts)
	      (setq newopts (car (cdr next-item)))
	      (if (not (listp newopts))
		  (error (format "Cscope options must be a list: %s" newopts)))
	      (setq options (append options newopts))
	      ))
	(if cscope-command-args
	    (setq options (append options cscope-command-args)))
	(setq database-file (concat cscope-directory base-database-file-name)
	      cscope-searched-dirs (cons cscope-directory
					 cscope-searched-dirs)
	      )

	;; The database file and the directory containing the database file
	;; must both be writable.
	(if (or (not (file-writable-p database-file))
		(not (file-writable-p (file-name-directory database-file)))
		cscope-do-not-update-database)
	    (setq options (cons "-d" options)))


;; is this require for multiple databases?
	;; (goto-char (point-max))
        (if (string= base-database-file-name cscope-database-file)
            (insert "\nDatabase directory: "
                    (cscope-boldify-if-needed cscope-directory)
                    "\n\n")
          (insert "\nDatabase directory/file: "
		  (cscope-boldify-if-needed cscope-directory base-database-file-name)
                  "\n\n"))
	;; Add the correct database file to search
	(setq options (cons base-database-file-name options))
	(setq options (cons "-f" options))
	(setq cscope-output-start (point))
	(setq default-directory cscope-directory)

        (setq cscope-process-output nil
              cscope-last-file nil
              )
        (setq cscope-process
              (apply 'start-file-process "cscope" outbuf
                     cscope-program options))
        (set-process-filter cscope-process 'cscope-process-filter)
        (set-process-sentinel cscope-process 'cscope-process-sentinel)
        (set-marker (process-mark cscope-process) (point))
        (process-kill-without-query cscope-process)
        (if cscope-running-in-xemacs
            (setq modeline-process ": Searching ..."))
	t
	))
    ))

(defun cscope-call (basemsg search-id symbol)
  "Generic function to call to process cscope requests.
BASEMSG is a message describing this search; SEARCH-ID is a
numeric id indicating to the cscope backend what kind of search
this is."
  (let* ( (outbuf (get-buffer-create cscope-output-buffer-name))
          (old-buffer (current-buffer))
          (directory
           (cscope-canonicalize-directory

            ;; if we have an initial directory, use it. Otherwise if we're in
            ;; *cscope*, try to use the directory of the search at point
            (or cscope-initial-directory
                (and (eq outbuf old-buffer)
                     (get-text-property (point) 'cscope-directory)))))
          (msg (concat basemsg " "
                       (cscope-boldify-if-needed symbol)))
          (args (list (format "-%d" search-id) symbol)))
    (if cscope-process
	(error "A cscope search is still in progress -- only one at a time is allowed"))
    (if (eq outbuf old-buffer) ;; In the *cscope* buffer.
        (let ((marker-buf (window-buffer cscope-marker-window)))
          (when marker-buf
	      ;; Assume that cscope-marker-window is the window, from the
	      ;; users perspective, from which the search was launched and the
	      ;; window that should be returned to upon cscope-pop-mark.
            (with-current-buffer marker-buf
              (setq cscope-marker (point-marker)))))

      ;; Not in the *cscope buffer.
	  ;; Set the cscope-marker-window to whichever window this search
	  ;; was launched from.
	  (setq cscope-marker-window (get-buffer-window old-buffer))
      (setq cscope-marker (point-marker)))
    (save-excursion
      (set-buffer outbuf)
      (if cscope-display-times
	  (let ( (times (current-time)) )
	    (setq cscope-start-time (+ (* (car times) 65536.0) (car (cdr times))
				       (* (car (cdr (cdr times))) 1.0E-6)))))
      (setq default-directory directory
	    cscope-start-directory nil
	    cscope-search-list (cscope-find-info directory)
	    cscope-searched-dirs nil
	    cscope-command-args args
	    cscope-first-match-point nil
	    cscope-stop-at-first-match-dir-meta (memq t cscope-search-list)
	    cscope-matched-multiple nil)
      (setq truncate-lines cscope-truncate-lines)

      ;; insert the separator at the start of the result set
      (unless (boundp 'cscope-rerunning-search) (goto-char (point-max)))
      (when (not (bolp))
        (insert "\n"))

      ;; don't apply the face to the trailing newline in the separator
      (let ((separator-start (point)))
        (insert cscope-result-separator)
        (when cscope-use-face
          (put-text-property separator-start (1- (point)) 'face 'cscope-separator-face)
          (put-text-property separator-start (1- (point)) 'cscope-stored-search cscope-previous-user-search)))

      (insert msg)
      (cscope-search-one-database)
      )
    (if cscope-display-cscope-buffer
	(progn
	  (pop-to-buffer outbuf)
	  (cscope-help))
      (set-buffer outbuf))
    (cscope-list-entry-mode)
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cscope-unix-index-process nil
  "The current indexing process.")

(defvar cscope-indexing-status-string nil
  "The string returned by the indexer. This receives the indexer
  output as it comes over time")

(defun cscope-unix-index-files-filter (process output)
  "Called when the indexing process says 'output'. I pop up a
  message in a buffer or the echo area"

  ;; add the new string
  (setq cscope-indexing-status-string
        (concat cscope-indexing-status-string output))

  ;; and display
  (display-message-or-buffer cscope-indexing-status-string "*cscope-indexing-buffer*"))

(defun cscope-unix-index-files-sentinel (process event)
  "Simple sentinel to print a message saying that indexing is finished."
  (setq cscope-indexing-status-string
        (concat cscope-indexing-status-string
                cscope-result-separator
                "\n"
                (if (equal event "finished\n")
                    "Indexing finished\n"
                  (concat "Indexing process received signal: " event "Stopping indexing"))))

  (display-message-or-buffer cscope-indexing-status-string "*cscope-indexing-buffer*")
  (delete-process process)
  (setq cscope-unix-index-process nil)
  (setq cscope-indexing-status-string nil))


(defun cscope-unix-index-files-internal (top-directory header-text args)
  "Core function to call the indexing script."
  (save-excursion
    (setq top-directory (cscope-canonicalize-directory top-directory))
    (setq cscope-indexing-status-string
          (or header-text ""))

    (setq args (append args
                       (list "-v"
                             "-i" cscope-index-file
                             "-f" cscope-database-file
                             (if cscope-use-relative-paths
                                 "." top-directory))))
    (if cscope-index-recursively
        (setq args (cons "-r" args)))
    (setq cscope-unix-index-process
          (let ((default-directory top-directory))
            (apply 'start-file-process "cscope-indexer"
                   nil
                   cscope-indexing-script args)))
    (set-process-filter cscope-unix-index-process 'cscope-unix-index-files-filter)
    (set-process-sentinel cscope-unix-index-process
                          'cscope-unix-index-files-sentinel)
    (process-kill-without-query cscope-unix-index-process)
    )
  )


(defun cscope-index-files (top-directory)
  "Index files in a directory.
This function creates a list of files to index, and then indexes
the listed files.
The variable, \"cscope-index-recursively\", controls whether or not
subdirectories are indexed."
  (interactive "DIndex files in directory: ")
  (let ()
    (cscope-unix-index-files-internal
     top-directory
     (format "Creating cscope index `%s' in:\n\t%s\n\n%s"
	     cscope-database-file top-directory cscope-result-separator)
     nil)
    ))


(defun cscope-create-list-of-files-to-index (top-directory)
  "Create a list of files to index.
The variable, \"cscope-index-recursively\", controls whether or not
subdirectories are indexed."
  (interactive "DCreate file list in directory: ")
  (let ()
    (cscope-unix-index-files-internal
     top-directory
     (format "Creating cscope file list `%s' in:\n\t%s\n\n"
	     cscope-index-file top-directory)
     '("-l"))
    ))


(defun cscope-edit-list-of-files-to-index ()
  "Search for and edit the list of files to index.
If this functions causes a new file to be edited, that means that a
cscope.out file was found without a corresponding cscope.files file."
  (interactive)
  (let (info directory file)
    (setq info (cscope-find-info nil))
    (if (/= (length info) 1)
	(error "There is no unique cscope database directory!"))
    (setq directory (car (car info)))
    (if (not (stringp directory))
	(setq directory
	      (cscope-search-directory-hierarchy default-directory)))
    (setq file (concat (file-name-as-directory directory) cscope-index-file))
    (find-file file)
    (message (concat "File: " file))
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cscope-tell-user-about-directory ()
  "Display the name of the directory containing the cscope database."
  (interactive)
  (let (info directory)
    (setq info (cscope-find-info nil))
    (if (= (length info) 1)
	(progn
	  (setq directory (car (car info)))
	  (message (concat "Cscope directory: " directory))
	  )
      (let ( (outbuf (get-buffer-create cscope-info-buffer-name)) )
	(display-buffer outbuf)
	(save-excursion
	  (set-buffer outbuf)
	  (buffer-disable-undo)
	  (erase-buffer)
	  (insert "Cscope search directories:\n")
	  (while info
	    (if (listp (car info))
		(progn
		  (setq directory (car (car info)))
		  (if (not (stringp directory))
		      (setq directory
			    (cscope-search-directory-hierarchy
			     default-directory)))
		  (insert "\t" directory "\n")
		  ))
	    (setq info (cdr info))
	    )
	  )
	))
    ))


(defun cscope-dired-directory ()
  "Run dired upon the cscope database directory.
If possible, the cursor is moved to the name of the cscope database
file."
  (interactive)
  (let (info directory buffer p1 p2 pos)
    (setq info (cscope-find-info nil))
    (if (/= (length info) 1)
	(error "There is no unique cscope database directory!"))
    (setq directory (car (car info)))
    (if (not (stringp directory))
	(setq directory
	      (cscope-search-directory-hierarchy default-directory)))
    (setq buffer (dired-noselect directory nil))
    (switch-to-buffer buffer)
    (set-buffer buffer)
    (save-excursion
      (goto-char (point-min))
      (setq p1 (search-forward cscope-index-file nil t))
      (if p1
	  (setq p1 (- p1 (length cscope-index-file))))
      )
    (save-excursion
      (goto-char (point-min))
      (setq p2 (search-forward cscope-database-file nil t))
      (if p2
	  (setq p2 (- p2 (length cscope-database-file))))
      )
    (cond
     ( (and p1 p2)
       (if (< p1 p2)
	   (setq pos p1)
	 (setq pos p2))
       )
     ( p1
       (setq pos p1)
       )
     ( p2
       (setq pos p2)
       )
     )
    (if pos
	(set-window-point (get-buffer-window buffer) pos))
    ))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun cscope-extract-symbol-at-cursor (extract-filename try-to-use-region)
  (if (and try-to-use-region (use-region-p))

      ;; We have a region and we were asked to use it. This usually happens when
      ;; looking for text strings or regular expressions
      (buffer-substring-no-properties (region-beginning) (region-end))

    ;; Try to infer symbol from the text
    (let* ( (symbol-chars (if extract-filename
                              cscope-filename-chars
                            cscope-symbol-chars))
            (symbol-char-regexp (concat "[" symbol-chars "]"))
            )
      (save-excursion
        (buffer-substring-no-properties
         (progn
           (if (not (looking-at symbol-char-regexp))
               (re-search-backward "\\w" nil t))
           (skip-chars-backward symbol-chars)
           (point))
         (progn
           (skip-chars-forward symbol-chars)
           (point)
           )))
      )))


(defun cscope-prompt-for-symbol (prompt extract-filename try-to-use-region)
  "Prompt the user for a cscope symbol."
  (let ((sym (cscope-extract-symbol-at-cursor extract-filename try-to-use-region)))
    (if (or (not sym)
            (string= sym "")
            (not (boundp 'cscope-suppress-user-symbol-prompt))

            ;; Always prompt for symbol in dired mode.
            (eq major-mode 'dired-mode))
	(setq sym (read-from-minibuffer prompt sym))
      sym)
    ))


(defun cscope-find-this-symbol (symbol)
  "Locate a symbol in source code."
  (interactive (list
		(cscope-prompt-for-symbol "Find this symbol: " nil nil)
		))
  (setq cscope-previous-user-search `(cscope-find-this-symbol ,symbol))
  (cscope-call "Finding symbol:" 0 symbol)
  )


(defun cscope-find-global-definition (symbol)
  "Find a symbol's global definition."
  (interactive (list
		(cscope-prompt-for-symbol "Find this global definition: " nil nil)
		))
  (setq cscope-previous-user-search `(cscope-find-global-definition ,symbol))
  (cscope-call "Finding global definition:" 1 symbol)
  )


(defun cscope-find-global-definition-no-prompting ()
  "Find a symbol's global definition without prompting."
  (interactive)
  (let ( (symbol (cscope-extract-symbol-at-cursor nil nil)))
      (setq cscope-previous-user-search `(cscope-find-global-definition-no-prompting ,symbol))
    (cscope-call "Finding global definition:" 1 symbol)
    ))


(defun cscope-find-called-functions (symbol)
  "Display functions called by a function."
  (interactive (list
		(cscope-prompt-for-symbol
		 "Find functions called by this function: " nil nil)
		))
  (setq cscope-previous-user-search `(cscope-find-called-functions ,symbol))
  (cscope-call "Finding functions called by:" 2 symbol)
  )


(defun cscope-find-functions-calling-this-function (symbol)
  "Display functions calling a function."
  (interactive (list
		(cscope-prompt-for-symbol
		 "Find functions calling this function: " nil nil)
		))
  (setq cscope-previous-user-search `(cscope-find-functions-calling-this-function ,symbol))
  (cscope-call "Finding functions calling:" 3 symbol)
  )


(defun cscope-find-this-text-string (symbol)
  "Locate where a text string occurs."
  (interactive (list
		(cscope-prompt-for-symbol "Find this text string: " nil t)
		))
  (setq cscope-previous-user-search `(cscope-find-this-text-string ,symbol))
  (cscope-call "Finding text string:" 4 symbol)
  )


(defun cscope-find-egrep-pattern (symbol)
  "Run egrep over the cscope database."
  (interactive (list
		(let (cscope-no-mouse-prompts)
		  (cscope-prompt-for-symbol "Find this egrep pattern: " nil t))
		))
  (setq cscope-previous-user-search `(cscope-find-egrep-pattern ,symbol))
  (cscope-call "Finding egrep pattern:" 6 symbol)
  )


(defun cscope-find-this-file (symbol)
  "Locate a file."
  (interactive (list
		(let (cscope-no-mouse-prompts)
		  (cscope-prompt-for-symbol "Find this file: " t nil))
		))

  (setq cscope-previous-user-search `(cscope-find-this-file ,symbol))
  (cscope-call "Finding file:" 7 symbol)
  )


(defun cscope-find-files-including-file (symbol)
  "Locate all files #including a file."
  (interactive (list
		(let (cscope-no-mouse-prompts)
		  (cscope-prompt-for-symbol
		   "Find files #including this file: " t nil))
		))
  (setq cscope-previous-user-search `(cscope-find-files-including-file ,symbol))
  (cscope-call "Finding files #including file:" 8 symbol)
  )


(defun cscope-find-assignments-to-this-symbol (symbol)
  "Locate assignments to a symbol in the source code."
  (interactive (list
		(cscope-prompt-for-symbol "Find assignments to this symbol: " nil nil)
		))
  (setq cscope-previous-user-search `(cscope-find-assignments-to-this-symbol ,symbol))
  (cscope-call "Finding assignments to symbol:" 9 symbol)
  )



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar cscope-minor-mode nil
  "")
(make-variable-buffer-local 'cscope-minor-mode)
(put 'cscope-minor-mode 'permanent-local t)


(defun cscope-minor-mode (&optional arg)
  ""
  (progn
    (setq cscope-minor-mode (if (null arg) t (car arg)))
    (if cscope-minor-mode
	(progn
	  (easy-menu-add cscope-global-menu cscope-global-keymap)
	  (easy-menu-add cscope-buffer-menu cscope-list-entry-keymap)
	  (run-hooks 'cscope-minor-mode-hooks)
	  ))
    cscope-minor-mode
    ))


(defun cscope:hook ()
  ""
  (progn
    (cscope-minor-mode)
    ))


(or (assq 'cscope-minor-mode minor-mode-map-alist)
    (setq minor-mode-map-alist (cons (cons 'cscope-minor-mode cscope-global-keymap)
				     minor-mode-map-alist)))

(add-hook 'c-mode-hook (function cscope:hook))
(add-hook 'c++-mode-hook (function cscope:hook))
(add-hook 'dired-mode-hook (function cscope:hook))

(provide 'xcscope)

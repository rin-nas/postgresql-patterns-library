# inputrc

## Documentation

https://wiki.archlinux.org/title/Readline

## How to install?

Create file `~/.inputrc` and restart terminal.

Tested on `RHEL 8.9`.

File  **~/.inputrc**
```bash
# Use Home/End keyboard keys to navigate current line (same as CTRL+A or E), listing all variants for those keys here
"\e[1~": beginning-of-line          # Home
"\e[H": beginning-of-line           # Home
"\eOH": beginning-of-line           # Home
"\0001": beginning-of-line          # Home
"\e[4~": end-of-line                # End
"\e[F": end-of-line                 # End
"\eOF": end-of-line                 # End
"\0005": end-of-line                # End

# CTRL+DEL to delete from cursor to end of line
"\e[2~": quoted-insert              # INS
"\e[3~": delete-char                # DEL
"\e[3;4~": kill-line                # CTRL+DEL
"\e[3;5~": kill-line                # CTRL+DEL

"\0177": backward-kill-line         # CTRL+Backspace

# CTRL+arrows to move from word to word
"\e[5D": backward-word              # CTRL+left
"\e[1;4D": backward-word            # CTRL+left
"\e[1;5D": backward-word            # CTRL+left
"\eOD": backward-word               # CTRL+left
"\e[5C": forward-word               # CTRL+right
"\e[1;4C": forward-word             # CTRL+right
"\e[1;5C": forward-word             # CTRL+right
"\eOC": forward-word                # CTRL+right

# These are usually defaults:
"\e[A": history-search-backward    # search command history backward with up arrow key
"\e[B": history-search-forward     # search command history forward with down arrow key
"\e[D": backward-char              # left
"\e[C": forward-char               # right

# Possible zsh-like auto-complete:
#set show-all-if-ambiguous on       # enable single-tab completions
#"\t": menu-complete                # enable single-tab completions through a series of completions inline

set mark-symlinked-directories on   # Make auto-complete include trailing '/' on symlinks as well
set bind-tty-special-chars on       # Adds punctuation as word delimiters
set blink-matching-paren on         # Blink matching parenthesis
set completion-ignore-case on       # If you're used to case-insensitive file systems
set visible-stats on                # Show file type on multiple match
#set bell-style none                 # do not bell on tab-completion

$if Bash                            # same effect as "bind Space:magic-space" in ~/.bashrc
  Space: magic-space
$endif
```

## Links

* [Convenient colored command line prompt in `bash`](../bashrc)
* [Convenient colored command line prompt in `psql`](../psqlrc)

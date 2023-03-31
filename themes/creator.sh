#!/usr/bin/env bash

SED_SCRIPT=$'
/^command:/ {
    1s/^command: (.*)/\\1/
    h
    p
    s/./-/g
    n
    :list
    n
    s/^(\\/.*)\\/(.*)$/→ \e[38;5;81m\\2\e[0m in \e[38;5;249m\\1\e[0m/
    t list
}

/^(pyenv|homebrew):/ {
    s/ ([^ ]+\\*)/ \e[38;5;81m\\1\e[0m/g
    s/ ([^ ]+)/ \e[38;5;249m\\1\e[0m/g
}

/^config:/ {
    :configblock
    n
    s/([^ ]+)=([^ ]*)/ \e[38;5;81m\\1\e[0m=\e[38;5;249m\\2\e[0m/g
    t configblock
}

/^(usage|global arguments|aliases|logs):/ {
    :genericblock
    n
    s/^  .*/\e[38;5;249m&\e[0m/g
    t genericblock
}

/^commands:/ {
    :commandsblock
    n
    s/^  dpv ([^ ]+)(.*)/  \e[38;5;249mdpv\e[0m \e[38;5;81m\\1\e[0m\e[38;5;249m\\2\e[0m/
    t commandsblock
    s/^    --.*/\e[38;5;249m&\e[0m/
    t commandsblock

}

'

sed -E -f <(echo "$SED_SCRIPT")

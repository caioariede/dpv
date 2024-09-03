#!/usr/bin/env bash

SED_SCRIPT=$'
/^command:/ {
    s/command:/dpv →/
    n
    :list
    n
    s/^(\\/.*)\\/(.*)$/→ \e[38;5;81m\\2\e[0m in \e[38;5;249m\\1\e[0m/
    t list
}

/^status: / {
    s/status: (not activated)/status: \e[0;33m\\1\e[0m/
    s/status: (activated)/status: \e[0;32m\\1\e[0m/
}

/^(pyenv|homebrew|uv):/ {
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

/^virtualenv:/ {
    :venvblock
    n
    s/  status: (not activated)/  status: \e[0;33m\\1\e[0m/
    s/  status: (activated)/  status: \e[0;32m\\1\e[0m/
    s/^( +)([^:]+):(.*)/\\1\e[38;5;81m\\2\e[0m:\e[38;5;249m\\3\e[0m/g
    t venvblock
}

'

sed -E -f <(echo "$SED_SCRIPT")

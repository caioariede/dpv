```
dpv 1.0.0

usage:
  dpv             - installs virtualenv for the current directory
  dpv help        - display these instructions
  dpv list        - lists virtualenvs managed by dpv
  dpv where       - display the virtualenv directory
  dpv versions    - display python versions
    --all         - include all versions rather than a simplified list
    --installed   - only display versions that are currently installed
  dpv instrument  - instruments dpv
  dpv run [cmd]   - runs command inside virtualenv [default: $SHELL]

global arguments:
  -q / --quiet    - do not show logs

aliases:
  dpv -h / dpv help
  dpv -v / dpv versions
  dpv -l / dpv ls / dpv list


logs:
  - pyenv is installed and is the preferred installation method
  - homebrew is installed
```

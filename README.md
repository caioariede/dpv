```
dpv 0.9.0

usage:
  dpv [python version]

commands:
  dpv help             - display these instructions
  dpv info             - display information about the current virtualenv
  dpv list             - list virtualenvs created with dpv
  dpv run [command]    - run command inside virtualenv [default: $SHELL]
    --python [version] - specify python version
    --temp             - use a temporary virtualenv
  dpv versions         - display available python versions
    --all              - display extended list of available python versions
  dpv drop             - remove current virtualenv

global arguments:
  --pyenv              - use pyenv
  --homebrew           - use homebrew

aliases:
  dpv run / dpv
  dpv [version] / dpv run --python [version]
  dpv info / dpv (when virtualenv is activated)
  dpv help / --help / -h
  dpv list / --list / ls / -l
  dpv versions / -v
  dpv versions --all / -a
```

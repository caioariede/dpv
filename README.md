```
dpv 1.0.0

usage:
  dpv help             - display these instructions
  dpv list             - list virtualenvs created with dpv
  dpv run [command]    - run command inside virtualenv [default: $SHELL]
    --python [version] - specify python version
    --temp             - use a temporary virtualenv
  dpv versions         - display installed python versions
    --available        - display available ptyhon versions
    --all              - display all versions rather than a simplified list

global arguments:
  --no-pyenv           - disable pyenv detection
  --no-homebrew        - disable homebrew detection

aliases:
  dpv / dpv run
  dpv -h / dpv help
  dpv -l / dpv ls / dpv list
  dpv -v / dpv versions
```

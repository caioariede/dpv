**the dead simple Python virtualenv manager** *for the stoic programmer 🪚*

[![CI](https://github.com/caioariede/dpv/actions/workflows/ci.yml/badge.svg)](https://github.com/caioariede/dpv/actions/workflows/ci.yml)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/caioariede/dpv)
![GitHub file size in bytes](https://img.shields.io/github/size/caioariede/dpv/src/dpv)
![Platform](https://img.shields.io/badge/platform-linux%20and%20macos-lightgrey)
![GitHub](https://img.shields.io/github/license/caioariede/dpv)

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

## Comparison

### Initialize virtualenv

#### Context

* A specific Python version is specified (pyproject.toml, runtime.txt)
* homebrew & pyenv are both installed

#### dpv

```bash
$ dpv
python version [selected: 3.9.14 source: runtime.txt]:
installing python 3.9.14 using pyenv
  > python-build: use openssl@1.1 from homebrew
  > python-build: use readline from homebrew
  > Downloading Python-3.9.14.tar.xz...
  > -> https://www.python.org/ftp/python/3.9.14/Python-3.9.14.tar.xz
  > Installing Python-3.9.14...
  > python-build: use tcl-tk from homebrew
  > python-build: use readline from homebrew
  > python-build: use zlib from xcode sdk
  > Installed Python-3.9.14 to /Users/caio/.pyenv/versions/3.9.14
  >
done
dpv - myproject-3.9.14 activated

logs:
  - pyenv method selected
  - pyenv: version 3.9.14 needs to be installed
  - created new virtualenv: myproject-3.9.14
```

#### poetry

```bash
$ poetry install
The currently activated Python version 3.11.2 is not supported by the project (3.9.14).
Trying to find and use a compatible version.

Poetry was unable to find a compatible version. If you have one, you can explicitly use it via the "env use" command.
```






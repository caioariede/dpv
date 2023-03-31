**the d̲ead simple P̲ython v̲irtualenv manager** *for the stoic programmer 🪚*  

[![CI](https://github.com/caioariede/dpv/actions/workflows/ci.yml/badge.svg)](https://github.com/caioariede/dpv/actions/workflows/ci.yml)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/caioariede/dpv)
![GitHub file size in bytes](https://img.shields.io/github/size/caioariede/dpv/src/dpv)
![Platform](https://img.shields.io/badge/platform-linux%20and%20macos-lightgrey)
![GitHub](https://img.shields.io/github/license/caioariede/dpv)

![dpv](https://user-images.githubusercontent.com/55533/229202838-c2e73bbd-3943-43d1-8c3f-be02f64a88db.gif)

## Manual

```
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

config:
   CFG_VENVS_DIR=/Users/caio/.dpv/virtualenvs
   CFG_THEME=/Users/caio/Projects/caio/dpv/themes/creator.sh
   CFG_DIR=/Users/caio/.dpv
   CFG_PYENV_EXECUTABLE=pyenv
   CFG_HOMEBREW_EXECUTABLE=brew
   CFG_PREFERRED_INSTALL_METHODS=pyenv homebrew
```

## Installation

1. **Download**

```bash
bash -c 'curl -fsSLo $1 https://raw.githubusercontent.com/caioariede/dpv/HEAD/src/dpv && chmod +x $1' -- /usr/local/bin/dpv
```

2. **Configure** — Add the following line to your .bashrc, .zshrc, etc

```bash
eval "$(dpv internal-instrument)"
```

3. **Try it**

```bash
dpv --temp # this won't create any files in the current directory
```

## Install a theme (optional)

Yes, you can customize dpv's appearance :)

First, download the theme:

```bash
curl -sfSLO --create-dirs --output-dir ~/.dpv/themes/ https://raw.githubusercontent.com/caioariede/dpv/HEAD/themes/creator.sh
```

And add the following line to your .bashrc, .zshrc, etc (can be before or after dpv setup)

```bash
DPV_THEME=~/.dpv/themes/creator.sh
```

_Feel free to submit your own theme with a PR. Unfortunately right now there's no documentation around that, take a shot!_

## Command Comparison

| command                                     | dpv          | poetry                   |
| --                                          | --           | --                       |
| initialize virtualenv                       | dpv          | poetry install           |
| initialize virtualenv with specific version | dpv 3.9.16   | poetry env use 3.9.16    |
| initialize temporary virtualenv             | dpv --temp   |                          |
| open shell                                  | dpv          | poetry shell             |
| remove virtualenv                           | dpv drop     | poetry env remove 3.9.16 |
| quit shell                                  | `ctrl-d`     | `ctrl-d`                 |
| list python versions (available, installed) | dpv versions |                          |

## Behavior Comparison

### Initialize virtualenv

#### Context

* A specific Python version is specified (pyproject.toml, runtime.txt)
* homebrew & pyenv are both installed

#### dpv

dpv will install the required version

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

You can still choose an alrready installed version:

```bash
$ dpv versions --installed
installed python versions
-------------------------

pyenv: 3.11-dev* 3.10-dev* 3.9.14* 3.9.13* 3.9.12* 3.9.2* 3.6.15* 2.7.18*
homebrew: 3.11.2* 3.10.10* 3.9.16* 3.8.16* 3.7.16*

$ dpv 3.9.16
python version [selected: 3.9.16 source: command-line]:
dpv - ds-packages-3.9.16 activated

logs:
  - homebrew method selected
  - homebrew: version 3.9.16 already installed
  - created new virtualenv: ds-packages-3.9.16
```

#### poetry

```bash
$ poetry install
The currently activated Python version 3.11.2 is not supported by the project (3.9.14).
Trying to find and use a compatible version.

Poetry was unable to find a compatible version. If you have one, you can explicitly use it via the "env use" command.
```


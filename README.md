dpv (dee-pee-vee) is a dead simple virtual manager for Python that gets out of your way

![e01c0828348239 56052c74596be](https://github.com/caioariede/dpv/assets/55533/7c1a5baa-8727-4417-80f2-41cdcead61d6)

[![CI](https://github.com/caioariede/dpv/actions/workflows/ci.yml/badge.svg)](https://github.com/caioariede/dpv/actions/workflows/ci.yml)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/caioariede/dpv)
![GitHub file size in bytes](https://img.shields.io/github/size/caioariede/dpv/src/dpv)
![Platform](https://img.shields.io/badge/platform-linux%20and%20macos-lightgrey)
![GitHub](https://img.shields.io/github/license/caioariede/dpv)

## Why?

1. It's simple. Just type `dpv` or `dpv <python version>` and get the work done.
2. It's pure shell and POSIX-compliant tested with: ash bash dash ksh zsh
3. It's built to get out of the way!

## Usage

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
  dpv drop [name]      - remove virtualenv

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

## Installation

1. **Download**

```bash
sh -c 'curl -fsSLo $1 https://raw.githubusercontent.com/caioariede/dpv/HEAD/src/dpv && chmod +x $1' -- /usr/local/bin/dpv
```

2. **Configure** — Add the following line to your .bashrc, .zshrc, etc

```bash
eval "$(dpv internal-load-shell)"
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

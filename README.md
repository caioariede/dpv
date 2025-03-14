dpv (dee-pee-vee) is a dead simple alternative to [pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv) and [virtualenvwrapper](https://virtualenvwrapper.readthedocs.io/en/latest/)

<img src="https://github.com/caioariede/dpv/assets/55533/7c1a5baa-8727-4417-80f2-41cdcead61d6" alt="Bem-te-vi, Great Kiskadee, Pitangus sulphuratus, credit of Helena Stainer" title="Bem-te-vi, Great Kiskadee, Pitangus sulphuratus, credit of Helena Stainer">

[![CI](https://github.com/caioariede/dpv/actions/workflows/ci.yml/badge.svg)](https://github.com/caioariede/dpv/actions/workflows/ci.yml)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/caioariede/dpv)
![GitHub file size in bytes](https://img.shields.io/github/size/caioariede/dpv/src/dpv)
![Platform](https://img.shields.io/badge/platform-linux%20and%20macos-lightgrey)
![GitHub](https://img.shields.io/github/license/caioariede/dpv)

## Why?

1. It's simple. Just type `dpv` or `dpv <python version>` and get the work done.
2. It's pure shell and POSIX-compliant tested with: ash bash dash ksh zsh
3. It's built to get out of the way!

## How?

Think of `dpv` as an interface for whaterver of these tools you have installed: `uv`, `pyenv`, `brew`

It will automatically pick the one that is available and use it for the job.

## Installation

1. **Download**

```bash
sh -c 'curl -fsSLo $1 https://github.com/caioariede/dpv/releases/download/v0.12.2/dpv && chmod +x $1' -- /usr/local/bin/dpv
```

_Optional: in case your `/usr/local/bin` directory is not writable yet, [see](https://superuser.com/a/717683)._

```bash
sudo chmod -R u=rwX,go=rX /usr/local/bin
```

2. **Configure** — Add the following line to your .bashrc, .zshrc, etc

```bash
eval "$(dpv internal-load-shell)"
```

Check out more details in the [installation instructions](https://github.com/caioariede/dpv/discussions/32)

## Usage

Take a look at the [dpv cheatsheet](https://github.com/caioariede/dpv/discussions/38) - or for more detailed instructions, [check the documentation](https://github.com/caioariede/dpv/discussions/33)

#!/bin/bash
#
# Dead-simple Python Virtualenvs
#
# Installation:
#   1. Copy this file to /usr/local/bin/dpv
#   2. Give execution permission: "chmod +x /usr/local/bin/dpv"
#   3. Add this line to your ~/.zshrc (or whatever):
#
#       eval "$(dpv instrument)"
#
#   4. Make sure pyenv is installed: brew install pyenv
#
# Usage:
#   Go to the directory of the project and call "dpv"
#   If it complains that the Python version is not installed, use: pyenv install <version>
#
set -e

function cmd_usage() {
    echo "dpv $CFG_VERSION"
    echo
    echo "usage:"
    echo "  dpv             - installs virtualenv for the current directory"
    echo "  dpv usage       - display these instructions"
    echo "  dpv list        - lists virtualenvs managed by dpv"
    echo "  dpv where       - display the virtualenv directory"
    echo "  dpv version     - display version"
    echo "  dpv instrument  - instruments dpv"
    echo "  dpv shell       - enters the virtualenv"
    echo
    echo "  CTRL-D          - exits virtualenv"
    echo

}

function cmd_version() {
    _load_config_vars
    echo "$CFG_VERSION"
}

function cmd_where() {
    _load_config_vars
    _load_python_vars
    _where
}

function cmd_instrument() {
    # https://stackoverflow.com/a/13864829
    if [ -n "${DPV_SHELL+x}" ]; then
        _load_config_vars
        _load_python_vars
        _print_venv_activate
    fi
}

function cmd_list() {
    case "$1" in
    --plain | *)
        _load_config_vars
        _plain_list
        ;;
    esac
}

function cmd_shell() {
    if [ ! -d "$VENV_DIR" ]; then
        _load_config_vars
        _load_python_vars
        _create_venv_if_not_exists
        _persist
    fi

    _load_shell
}

function cmd_persist() {
    _load_config_vars
    _persist
}

function cmd_install() {
    _load_config_vars
    _install
}

function err_detecting_python_version() {
    echo "cannot determine python version for $PWD" >/dev/stderr

    _print_exit_shell
}

function err_activate_virtualenv() {
    echo "cannot activate the virtualenv" >/dev/stderr

    _print_exit_shell
}

function __main() {
    trap '_error_handling $?' EXIT

    case "$1" in
    where)
        cmd_where
        ;;

    instrument)
        cmd_instrument
        ;;

    list | ls)
        cmd_list "${2:---plain}"
        ;;

    shell | "")
        cmd_shell
        ;;

    version | -v | --version)
        cmd_version
        ;;

    persist)
        cmd_persist
        ;;

    install)
        cmd_install
        ;;

    usage)
        cmd_usage
        ;;

    *)
        trap - EXIT
        echo "?"
        exit 1
        ;;

    esac
}

function _error_handling() {
    case "$1" in

    2)
        err_detecting_python_version
        ;;

    3)
        err_activate_virtualenv
        ;;

    esac
}

function _load_shell() {
    if [ -n "${DPV_SHELL+x}" ]; then
        exit 0
    fi

    DPV_SHELL=1 "$SHELL"
}

function _load_config_vars() {
    CFG_VERSION="1.0.0"
    CFG_DIR="$HOME/.dpv"
    CFG_VENVS_DIR="$CFG_DIR/virtualenvs"
    CFG_VENVS_PERSIST_FILE="$CFG_DIR/virtualenvs.txt"

    mkdir -p "$CFG_VENVS_DIR"
}

function _load_python_vars() {
    PY_VERSION=$(_get_python_version)
    PY_PREFIX=$(_get_python_prefix)
    VENV_DIR=$CFG_VENVS_DIR/$PY_VERSION/$(basename "$PWD")-$PY_VERSION
}

function _get_python_version() {
    if [ -f "runtime.txt" ]; then
        sed 's/^python\-//' <runtime.txt
    else
        exit 1
    fi
}

function _get_python_prefix() {
    pyenv prefix "$PY_VERSION"
}

function _create_venv_if_not_exists() {
    if [ ! -d "$VENV_DIR" ]; then
        "$PY_PREFIX/bin/python" -m venv "$VENV_DIR"
    fi
}

function _print_venv_activate() {
    echo "source $VENV_DIR/bin/activate || exit 2"
}

function _where() {
    PY_VERSION=$(_get_python_version)
    PY_PREFIX=$(_get_python_prefix)
    VENV_DIR=$CFG_VENVS_DIR/$PY_VERSION/$(basename "$PWD")-$PY_VERSION

    echo "$VENV_DIR"
}

function _plain_list() {
    if [ ! -f "$CFG_VENVS_PERSIST_FILE" ]; then
        _persist
    fi

    while IFS= read -r line; do
        IFS=$'\t' read -r -a lst <<<"$line"
        PY_VERSION=${lst[0]}
        PY_PREFIX=${lst[1]}
        if [ -d "$PY_PREFIX" ]; then
            echo -e "${lst[0]}\t${lst[1]}\tINSTALLED"
        else
            echo -e "${lst[0]}\t${lst[1]}\tNOT INSTALLED"
        fi
    done < <(cat "$CFG_VENVS_PERSIST_FILE")
}

function _persist() {
    echo -n "" >"$CFG_VENVS_PERSIST_FILE"

    for py_version_dir in "$CFG_VENVS_DIR"/*; do
        for venv in "$py_version_dir"/*; do
            printf "%s\t%s\n" "$(basename "$py_version_dir")" "$venv" >>"$CFG_VENVS_PERSIST_FILE"
        done
    done
}

function _install() {
    while IFS= read -r line; do
        IFS=$'\t' read -r -a lst <<<"$line"
        PY_VERSION=${lst[0]}
        PY_PREFIX=$(_get_python_prefix)
        VENV_DIR="${lst[1]}"
        if [ ! -f "$PY_PREFIX" ]; then
            echo "Installing $VENV_DIR"
            _create_venv_if_not_exists
        fi
    done < <(_plain_list)
}

function _print_exit_shell() {
    if [ -n "${DPV_SHELL+x}" ]; then
        echo "unset DPV_SHELL"
        echo "exit 1"
    fi
}

__main "$@"

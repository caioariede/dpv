#!/bin/bash
set -e

if [ "$#" -eq 0 ]; then
    echo "usage: ./runtest [pyenv|homebrew]"
    exit 1
fi

./test/bats/bin/bats "test/test.sh" --show-output-of-passing-tests
./test/bats/bin/bats "test/test_$1.sh" --show-output-of-passing-tests

#!/bin/bash
set -e

export DPV_INSTALL_METHOD="${1:-pyenv}"

./test/bats/bin/bats "test/test.sh" --show-output-of-passing-tests
./test/bats/bin/bats "test/test_$DPV_INSTALL_METHOD.sh" --show-output-of-passing-tests

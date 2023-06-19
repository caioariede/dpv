#!/bin/bash
set -ex

echo "Running tests using shell: $(command -v "$TEST_SHELL")"

./test/bats/bin/bats --show-output-of-passing-tests "$@"

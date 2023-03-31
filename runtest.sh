#!/bin/bash
set -e

./test/bats/bin/bats --show-output-of-passing-tests "$@"

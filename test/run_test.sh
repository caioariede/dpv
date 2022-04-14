#!/bin/bash

./test/bats/bin/bats "test/test_$1.bats" --show-output-of-passing-tests
./test/bats/bin/bats "test/test.bats" --show-output-of-passing-tests

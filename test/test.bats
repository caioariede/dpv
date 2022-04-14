setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/../src:$PATH"

    DPV_DIR="$BATS_TEST_TMPDIR/test_dpv"
    PRJ_DIR="$BATS_TEST_TMPDIR/test_dpv_proj"
    export DPV_DIR
    export PRJ_DIR

    ERR_CANNOT_DETERMINE_PYTHON_VERSION=2
    export ERR_CANNOT_DETERMINE_PYTHON_VERSION

    rm -rf "$DPV_DIR"
    rm -rf "$PRJ_DIR"
    mkdir -p "$DPV_DIR"
    mkdir -p "$PRJ_DIR"

    cd "$PRJ_DIR"
}

setup_runtime_txt() {
    echo "3.7.12" >runtime.txt
}

@test "run usage command" {
    run dpv usage

    assert_success
    assert_output -p 'usage'
}

@test "run list command without any virtualenvs" {
    run dpv list

    assert_success
    assert_output ''
}

@test "run list command with virtualenvs" {
    printf "test\ttest\n" >"$DPV_DIR/virtualenvs.txt"

    run dpv list

    assert_success
    assert_output -p 'test'

    true >"$DPV_DIR/virtualenvs.txt"
}

@test "run where command with runtime.txt" {
    setup_runtime_txt

    run dpv where

    assert_success
    assert_output "$DPV_DIR/virtualenvs/3.7.12/test_dpv_proj-3.7.12"
}

@test "run version command" {
    run dpv version

    assert_success
    assert_output
}

@test "run instrument command without the shell flag set" {
    run dpv instrument

    assert_success
    assert_output ''
}

@test "run instrument command with the shell flag set" {
    setup_runtime_txt

    DPV_SHELL=1 run dpv instrument

    assert_success
    assert_output -p "source"
}

@test "run instrument command with the shell flag but cannot determine Python version" {
    DPV_SHELL=1 run dpv instrument

    assert_failure $ERR_CANNOT_DETERMINE_PYTHON_VERSION
}

@test "run 'run' command but cannot determine Python version" {
    run dpv run

    assert_failure $ERR_CANNOT_DETERMINE_PYTHON_VERSION
}

@test "run 'run' command with runtime.txt" {
    setup_runtime_txt

    run dpv run bash -c 'echo $DPV_SHELL'

    assert_success
    assert_output '1'
}

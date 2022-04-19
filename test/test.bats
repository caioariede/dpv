setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

    source "$DIR/helper.sh"
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

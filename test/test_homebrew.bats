setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

    source "$DIR/helper.sh"

    DPV_INSTALL_METHOD=homebrew
    export DPV_INSTALL_METHOD
}

setup_runtime_txt() {
    echo "3.7.12" >runtime.txt
}

@test "run usage command" {
    run dpv usage

    assert_success
    assert_output -p 'homebrew is installed (preferred)'
}

@test "run where command with runtime.txt" {
    setup_runtime_txt

    run dpv where --quiet

    assert_success
    assert_output "$DPV_DIR/virtualenvs/3.7/test_dpv_proj-3.7"
}

setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	source "$DIR/helper.sh"

	DPV_INSTALL_METHOD=pyenv
	export DPV_INSTALL_METHOD
}

setup_runtime_txt() {
	echo "3.7.12" >runtime.txt
}

function run_help_command { # @test
	run dpv help

	assert_success
	assert_output -p 'pyenv is installed (preferred)'
}

function run_where_command_with_runtime_txt { # @test
	setup_runtime_txt

	run dpv where --quiet

	assert_success
	assert_output "$DPV_DIR/virtualenvs/3.7.12/test_dpv_proj-3.7.12"
}

setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	# shellcheck source=./helper.sh
	. "$DIR/helper.sh"
}

setup_runtime_txt() {
	echo "3.7.12" >runtime.txt
}

#
# Test help command
#

test_cmd_help() { # @test
	run dpv help

	assert_success
	assert_output -p 'usage'
}

#
# Test list command
#

test_cmd_list_without_any_virtualenvs() { # @test
	run dpv list --quiet

	assert_success
	assert_output ''
}

#
# Test internal-instrument command
#

test_cmd_internal_instrument_without_shell_flag() { # @test
	run dpv internal-instrument

	assert_success
	assert_output ''
}

test_cmd_internal_instrument_with_shell_flag() { # @test
	setup_runtime_txt

	DPV_SHELL=1 run dpv internal-instrument

	assert_success
	assert_output -p "source"
}

test_cmd_internal_instrument_cannot_determine_python_version() { # @test
	DPV_SHELL=1 run dpv internal-instrument

	assert_failure "$ERR_CANNOT_DETERMINE_PYTHON_VERSION"
}

#
# Test run command
#

test_cmd_run_cannot_determine_python_version() { # @test
	run dpv run

	assert_failure "$ERR_CANNOT_DETERMINE_PYTHON_VERSION"
}

test_cmd_run_with_runtime_txt() { # @test
	setup_runtime_txt

	run dpv run bash -c 'python --version'

	assert_success
	assert_output -p "Python 3.7"
}

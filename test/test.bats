setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

    # shellcheck source=./helper.sh
	source "$DIR/helper.sh"
}

setup_runtime_txt() {
	echo "3.7.12" >runtime.txt
}

function run_help_command { # @test
	run dpv help

	assert_success
	assert_output -p 'usage'
}

function run_list_command_withotu_any_virtualenvs { # @test
	run dpv list --quiet

	assert_success
	assert_output ''
}

function run_version_command { # @test
	run dpv version

	assert_success
	assert_output
}

function run_instrument_command_without_the_shell_flag_set { # @test
	run dpv instrument

	assert_success
	assert_output ''
}

function run_instrument_command_with_the_shell_flag_set { # @test
	setup_runtime_txt

	DPV_SHELL=1 run dpv instrument

	assert_success
	assert_output -p "source"
}

function run_instrument_command_with_the_shell_flag_but_cannot_determine_python_version { # @test
	DPV_SHELL=1 run dpv instrument

	assert_failure "$ERR_CANNOT_DETERMINE_PYTHON_VERSION"
}

function run_run_command_but_cannot_determine_python_version { # @test
	run dpv run

	assert_failure "$ERR_CANNOT_DETERMINE_PYTHON_VERSION"
}

function run_run_command_with_runtime_txt { # @test
	setup_runtime_txt

	run dpv run bash -c 'python --version'

	assert_success
	assert_output -p "Python 3.7"
}

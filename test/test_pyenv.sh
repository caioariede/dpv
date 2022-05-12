setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	# shellcheck source=./helper.sh
	. "$DIR/helper.sh"
}

setup_runtime_txt() {
	echo "3.9.10" >runtime.txt
}

#
# Test help command
#

test_cmd_help() { # @test
	run dpv help

	assert_success
	assert_output -p 'pyenv is installed and is the preferred installation method'
}

#
# Test versions command
#

test_cmd_versions() { # @test
	run dpv versions

	assert_success
	assert_output --regexp 'pyenv:.*3\.7'
}

test_cmd_versions_extended() { # @test
    setup_runtime_txt

	run dpv versions --extended

	assert_success
	assert_output --regexp 'pyenv:.*3\.7\.12'
}

#
# Test run command
#

test_cmd_run() { # @test
	setup_runtime_txt

	run dpv run --pyenv python --version

	assert_success
	assert_output -p "Python 3.9.11"
}

test_cmd_run_with_version_argument() { # @test
	run dpv run --pyenv --python 3.10.2 python --version

	assert_success
	assert_output -p "Python 3.10.2"
}

test_cmd_run_with_version_alias() { # @test
	run dpv 3.10.2 --pyenv python --version

	assert_success
	assert_output -p "Python 3.10.2"
}

test_cmd_run_with_missing_executable() { # @test
	setup_runtime_txt

	PYENV_EXECUTABLE=NO_COMMAND run dpv --pyenv python --version

	assert_failure
    assert_output "pyenv is not installed (executable: NO_COMMAND)"
}

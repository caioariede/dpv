setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	# shellcheck source=./helper.sh
	. "$DIR/helper.sh"
}

setup_runtime_txt() {
	echo "3.9.11" >runtime.txt
}

#
# Test help command
#

test_cmd_help() { # @test
	run dpv help --homebrew

	assert_success
	assert_output -p 'homebrew is installed and is the preferred installation method'
}

#
# Test versions command
#

test_cmd_versions() { # @test
    setup_runtime_txt

	run dpv versions

	assert_success
	assert_output --regexp 'homebrew:.*3\.7'
}

#
# Test run command
#

test_cmd_run() { # @test
	setup_runtime_txt

	run dpv run python --version

	assert_success
	assert_output -p "Python 3.9"
}

test_cmd_run_with_version_argument() { # @test
	run dpv run --python 3.10 --homebrew python --version

	assert_success
	assert_output -p "Python 3.10"
}

test_cmd_run_with_version_alias() { # @test
	run dpv 3.10 --homebrew python --version

	assert_success
	assert_output -p "Python 3.10"
}

test_cmd_run_with_missing_executable() { # @test
	setup_runtime_txt

	HOMEBREW_EXECUTABLE=NO_COMMAND run dpv --homebrew python --version

	assert_failure
	assert_output "homebrew is not installed (executable: NO_COMMAND)"
}

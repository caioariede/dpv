setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	# shellcheck source=./helper.sh
	. "$DIR/helper.sh"

	DPV_INSTALL_METHOD=homebrew
	export DPV_INSTALL_METHOD
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
	assert_output -p 'homebrew is installed and is the preferred installation method'
}

#
# Test versions command
#

test_cmd_versions() { # @test
	run dpv versions

	assert_success
	assert_output --regexp 'homebrew:.*3\.7'
}

#
# Test run command
#

test_cmd_run_with_runtime_txt() { # @test
	setup_runtime_txt

	run dpv run python --version

	assert_success
	assert_output -p "Python 3.7"
}

test_cmd_run_with_user_input() { # @test
	run dpv run --python 3.9 python --version

	assert_success
	assert_output -p "Python 3.9"
}

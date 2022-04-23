setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	# shellcheck source=./helper.sh
	. "$DIR/helper.sh"

	DPV_INSTALL_METHOD=pyenv
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
	assert_output -p 'pyenv is installed and is the preferred installation method'
}

#
# Test where command
#

test_cmd_where_with_runtime_txt() { # @test
	setup_runtime_txt

	run dpv where

	assert_success
	assert_output -p "$DPV_DIR/virtualenvs/3.7.12/test_dpv_proj-3.7.12"
}

#
# Test versions command
#

test_cmd_versions() { # @test
	run dpv versions

	assert_success
	assert_output --regexp 'pyenv:.*3\.7'
}

test_cmd_versions_all() { # @test
	run dpv versions --all

	assert_success
	assert_output --regexp 'pyenv:.*3\.7\.12'
}

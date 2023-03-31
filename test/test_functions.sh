setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	# test config
	TEST_CONFIG_MAJOR_PYTHON_VERSION=3.9
	TEST_CONFIG_MINOR_PYTHON_VERSION=3.9.10

	# shellcheck source=./helper.sh
	. "$DIR/helper.sh"
	. dpv

	INTERNAL_LOG_FILE=$(mktemp "${TMPDIR:-/tmp/}dpv_test_logs.XXXXX")
}

assert_log_output() {
	run cat $INTERNAL_LOG_FILE
	assert_output "$@"
}

refute_log_output() {
	run cat $INTERNAL_LOG_FILE
	refute_output "$@"
}

#
# utility tests
#
test_dpv_check_is_set_true() { # @test
	run dpv_check_is_set ""
	assert_success
}

test_dpv_check_is_set_false() { # @test
	run dpv_check_is_set "ø"
	assert_failure
}

test_dpv_check_string_is_empty_true() { # @test
	run dpv_check_string_is_empty ""
	assert_success
}

test_dpv_check_string_is_empty_false() { # @test
	run dpv_check_string_is_empty "ø"
	assert_failure
}

test_dpv_check_file_is_empty_true() { # @test
	test_fn() {
		local tmp_file="$(mktemp)"
		touch $tmp_file
		dpv_check_file_is_empty "$tmp_file"
	}
	run test_fn
	assert_success
}

test_dpv_check_file_is_empty_false() { # @test
	test_fn() {
		local tmp_file="$(mktemp)"
		touch $tmp_file
		echo "x" >>$tmp_file
		dpv_check_file_is_empty "$tmp_file"
	}
	run test_fn
	assert_failure
}

test_dpv_filter_mainstream_version() { # @test
	test_fn() {
		printf "2.7\njython-2.5.1\npypy2-5.7.1-src\n3.8.4\n3.9.16" | dpv_filter_mainstream_version
	}
	run test_fn
	assert_line --index 0 "3.8.4"
	assert_line --index 1 "3.9.16"
}

test_dpv_filter_unique_major_versions() { # @test
	test_fn() {
		printf "2.7\njython-2.5.1\npypy2-5.7.1-src\n3.8.4\n3.8.3\n3.9.16\n3.9.15" | dpv_filter_unique_major_versions
	}
	run test_fn
	assert_line --index 0 "2.7"
	assert_line --index 1 "jython-2.5.1"
	assert_line --index 2 "pypy2-5.7.1-src"
	assert_line --index 3 "3.8.4"
	assert_line --index 4 "3.9.16"
}

test_dpv_format_major_version() { # @test
	test_fn() {
		echo "3.9.2" | dpv_format_major_version
		echo "3.10" | dpv_format_major_version
		echo "3.11-dev" | dpv_format_major_version
	}
	run test_fn
	assert_line --index 0 "3.9"
	assert_line --index 1 "3.10"
	assert_line --index 2 "3.11-dev"
}

test_dpv_sort_versions() { # @test
	test_fn() {
		printf "3.9.2\n3.8.4\n3.11-dev" | dpv_sort_versions
	}
	run test_fn
	assert_line --index 0 "3.11-dev"
	assert_line --index 1 "3.9.2"
	assert_line --index 2 "3.8.4"
}

test_dpv_format_nl_to_space() { # @test
	test_fn() {
		printf "3.9.2\n3.8.4\n3.11-dev" | dpv_format_nl_to_space
	}
	run test_fn
	assert_output "3.9.2 3.8.4 3.11-dev"
}

test_dpv_format_highlight_versions() { # @test
	test_fn() {
		local versions_to_highlight="$(printf "3.8.4\n3.9.12")"
		printf "2.7\n3.8.4\n3.9.0\n3.9.12" | dpv_format_highlight_versions "$versions_to_highlight"
	}
	run test_fn
	assert_line --index 0 "2.7"
	assert_line --index 1 "3.8.4*"
	assert_line --index 2 "3.9.0"
	assert_line --index 3 "3.9.12*"
}

test_dpv_internal_mktemp_venv_dir() { # @test
	test_fn() {
		INTERNAL_VENV_PYTHON_VERSION="99.9"
		echo $(dpv_internal_mktemp_venv_dir)
	}
	run test_fn
	assert_success
	assert_output --partial "99.9"
}

#
# vendor tests: pyenv
#

setup_pyenv_mock() {
	if [ "${BATS_MOCK_PYENV:-1}" -eq 1 ]; then
		CFG_PYENV_EXECUTABLE=echo
	fi
}

test_unsafe_pyenv_resolve_python_version() { # @test
	test_fn() {
		echo 2.7 | unsafe_pyenv_resolve_python_version
	}
	run test_fn
	assert_success
	assert_output "2.7.18"
}

test_unsafe_pyenv_resolve_python_version_not_available() { # @test
	test_fn() {
		echo "99.9" | unsafe_pyenv_resolve_python_version
	}
	run test_fn
	assert_failure
	assert_log_output --partial "cannot resolve version 99.9"
}

test_pyenv_load_available_python_versions() { # @test
	test_fn() {
		pyenv_load_available_python_versions
		echo "$INTERNAL_PYENV_AVAILABLE_PYTHON_VERSIONS"
	}
	run test_fn
	assert_success
	assert_output --partial "$TEST_CONFIG_MINOR_PYTHON_VERSION"
}

test_pyenv_load_installed_python_versions() { # @test
	run pyenv_load_installed_python_versions
	assert_success
}

test_pyenv_get_python_executable() { # @test
	run pyenv_get_python_executable
	assert_success
	assert_output --partial "/bin/python"
}

test_pyenv_install() { # @test
	setup_pyenv_mock

	test_fn() {
		echo "$TEST_CONFIG_MINOR_PYTHON_VERSION" | pyenv_install
	}
	run test_fn
	assert_success
}

test_pyenv_exec() { # @test
	setup_pyenv_mock

	run pyenv_exec help
	assert_success
}

test_pyenv_is_available() { # @test
	setup_pyenv_mock

	run pyenv_is_available
	assert_success
}

test_pyenv_is_not_available() { # @test
	CFG_PYENV_EXECUTABLE="pyenv-invalid-command"
	run pyenv_is_available
	assert_failure
}

#
# vendor tests: homebrew
#
setup_homebrew_mock() {
	if [ "${BATS_MOCK_HOMEBREW:-1}" -eq 1 ]; then
		CFG_HOMEBREW_EXECUTABLE=echo
	fi
}

test_homebrew_is_available() { # @test
	setup_homebrew_mock

	run homebrew_is_available
	assert_success
}

test_homebrew_is_not_available() { # @test
	CFG_HOMEBREW_EXECUTABLE="brew-invalid-command"
	run homebrew_is_available
	assert_failure
}

test_homebrew_exec() { # @test
	setup_homebrew_mock

	run homebrew_exec help
	assert_success
}

test_homebrew_install() { # @test
	setup_homebrew_mock

	test_fn() {
		echo "$TEST_CONFIG_MAJOR_PYTHON_VERSION" | homebrew_install
	}
	run test_fn
	assert_success
}

test_homebrew_get_python_executable() { # @test
	run homebrew_get_python_executable
	assert_success
	assert_output --partial "/bin/python"
}

test_homebrew_load_available_python_versions() { # @test
	test_fn() {
		homebrew_load_available_python_versions
		echo "$INTERNAL_HOMEBREW_AVAILABLE_PYTHON_VERSIONS"
	}
	run test_fn
	assert_success
	assert_output --partial "$TEST_CONFIG_MAJOR_PYTHON_VERSION"
}

test_homebrew_load_installed_python_versions() { # @test
	run homebrew_load_installed_python_versions
	assert_success
}

test_unsafe_homebrew_resolve_python_version() { # @test
	test_fn() {
		echo "$TEST_CONFIG_MAJOR_PYTHON_VERSION" | unsafe_homebrew_resolve_python_version
	}
	run test_fn
	assert_success
	assert_output --partial "$TEST_CONFIG_MAJOR_PYTHON_VERSION."
}

test_unsafe_homebrew_resolve_python_version_not_available() { # @test
	test_fn() {
		echo "99.9" | unsafe_homebrew_resolve_python_version
	}
	run test_fn
	assert_failure
	assert_log_output --partial "cannot resolve version 99.9"
}

test_homebrew_format_python_formula() { # @test
	test_fn() {
		echo "$TEST_CONFIG_MINOR_PYTHON_VERSION" | homebrew_format_python_formula
	}
	run test_fn
	assert_output "python@$TEST_CONFIG_MAJOR_PYTHON_VERSION"
}

test_homebrew_expand_python_version() { # @test
	test_fn() {
		echo "$TEST_CONFIG_MAJOR_PYTHON_VERSION" | homebrew_expand_python_version
	}
	run test_fn
	assert_output --partial "$TEST_CONFIG_MAJOR_PYTHON_VERSION."
}

test_homebrew_expand_python_version_not_available() { # @test
	test_fn() {
		echo "2.0" | homebrew_expand_python_version
	}
	run test_fn
	assert_failure
	assert_output ""
}

#
# dpv internals tests
#
test_dpv_internal_set_log_file() { # @test
	test_fn() {
		INTERNAL_LOG_FILE="ø"
		dpv_internal_set_log_file
		echo "$INTERNAL_LOG_FILE"
	}
	run test_fn
	assert_success
	assert_output --partial "dpv_logs"
}

test_unsafe_dpv_internal_set_available_install_methods_success() { # @test
	test_fn() {
		unsafe_dpv_internal_set_available_install_methods
	}
	run test_fn
	assert_success
}

test_unsafe_dpv_internal_set_available_install_methods_fail() { # @test
	test_fn() {
		CFG_PREFERRED_INSTALL_METHODS=""
		unsafe_dpv_internal_set_available_install_methods
	}
	run test_fn
	assert_failure "$ERR_NO_AVAILABLE_INSTALL_METHODS"
}

test_dpv_internal_run_command_log_failure_fail() { # @test
	test_fn() {
		local error_command="echo 'something failed' ; exit 1"
		dpv_internal_run_command_log_failure "$error_command"
	}
	run test_fn
	assert_failure
	assert_log_output --partial "something failed"
}

test_dpv_internal_run_command_log_failure_success() { # @test
	test_fn() {
		local success_command="echo 'it works' ; exit 0"
		dpv_internal_run_command_log_failure "$success_command"
	}
	run test_fn
	assert_success
	refute_log_output --partial "it works"
}

test_dpv_internal_print_logs_no_logs() { # @test
	run dpv_internal_print_logs
	assert_output --partial "no logs"
}

test_dpv_internal_print_logs_with_logs() { # @test
	test_fn() {
		dpv_internal_log "yes logs"
		dpv_internal_print_logs
	}
	run test_fn
	assert_output --partial "- yes logs"
}

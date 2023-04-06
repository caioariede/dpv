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

	mock_log_file "$(mktemp "${TMPDIR:-/tmp/}dpv_test_logs.XXXXX")"
}

#
# mocks
#
mock_log_file() {
	INTERNAL_LOG_FILE="$1"
}

mock_virtualenv_python_version() {
	INTERNAL_VIRTUALENV_PYTHON_VERSION="$1"
}

mock_available_install_methods() {
	INTERNAL_AVAILABLE_INSTALL_METHODS="$@"
}

mock_installed_python_versions() {
	local install="$(echo "$1" | tr '[:lower:]' '[:upper:'])"
	local var="INTERNAL_${install}_INSTALLED_PYTHON_VERSIONS"
	shift
	eval "$var='$@'"
}

mock_available_python_versions() {
	local install="$(echo "$1" | tr '[:lower:]' '[:upper:'])"
	local var="INTERNAL_${install}_AVAILABLE_PYTHON_VERSIONS"
	shift
	eval "$var='$@'"
}

mock_virtualenvs_dir() {
	CFG_VIRTUALENVS_DIR="$(pwd)/virtualenvs"
}

mock_virtualenv() {
	local venv_install_method="$1"
	shift
	local venv_python_version="$1"
	shift
	local project_path="$1"
	shift
	local venv_name="$(basename "$project_path")"

	local venv_path="$CFG_VIRTUALENVS_DIR/$venv_python_version/$venv_name"

	mkdir -p "$CFG_VIRTUALENVS_DIR/$venv_python_version/$venv_name"
	printf "path = $project_path\nversion = $venv_python_version\ninstall_method = $venv_install_method\n" >"$venv_path/dpv.cfg"
}

#
# custom asserts
#

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

test_dpv_internal_mkdir_virtualenv_temporary() { # @test
	test_fn() {
		mock_virtualenv_python_version "99.9"
		echo $(dpv_internal_mkdir_virtualenv_temporary)
	}
	run test_fn
	assert_success
	assert_output --partial "99.9"
}

test_dpv_internal_mkdir_virtualenv() { # @test
	test_fn() {
		mock_virtualenv_python_version "99.9"
		echo $(dpv_internal_mkdir_virtualenv)
	}
	run test_fn
	assert_success
	assert_output --partial "99.9"
}

#
# vendor tests: pyenv
#

mock_pyenv() {
	local cmd="${1:-echo}"
	if [ "${BATS_MOCK_PYENV:-1}" -eq 1 ]; then
		CFG_PYENV_EXECUTABLE="$cmd"
	fi
}

test_pyenv_resolve_python_version() { # @test
	test_fn() {
		echo 2.7 | pyenv_resolve_python_version
	}
	run test_fn
	assert_success
	assert_output "2.7.18"
}

test_pyenv_resolve_python_version_not_available() { # @test
	test_fn() {
		echo "99.9" | pyenv_resolve_python_version
	}
	run test_fn
	assert_success
	assert_output ""
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

test_unsafe_pyenv_get_python_executable_success() { # @test
	test_fn() {
		INTERNAL_VIRTUALENV_PYTHON_VERSION="$TEST_CONFIG_MINOR_PYTHON_VERSION"

		unsafe_pyenv_get_python_executable
	}

	run test_fn
	assert_success
	assert_output --partial "/bin/python"
}

test_unsafe_pyenv_get_python_executable_failure() { # @test
	test_fn() {
		INTERNAL_VIRTUALENV_PYTHON_VERSION="99.9"

		unsafe_pyenv_get_python_executable
	}

	run test_fn
	assert_failure
}

test_unsafe_pyenv_install_success() { # @test
	mock_pyenv

	test_fn() {
		echo "$TEST_CONFIG_MINOR_PYTHON_VERSION" | unsafe_pyenv_install
	}
	run test_fn
	assert_success
}

test_unsafe_pyenv_install_failure() { # @test
	mock_pyenv "exit 1"

	test_fn() {
		echo "$TEST_CONFIG_MINOR_PYTHON_VERSION" | unsafe_pyenv_install
	}
	run test_fn
	assert_failure "$ERR_INSTALLATION_FAILED"
}

test_pyenv_exec() { # @test
	mock_pyenv

	run pyenv_exec help
	assert_success
}

test_pyenv_is_available() { # @test
	mock_pyenv

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
mock_homebrew() {
	local cmd="${1:-echo}"
	if [ "${BATS_MOCK_HOMEBREW:-1}" -eq 1 ]; then
		CFG_HOMEBREW_EXECUTABLE="$cmd"
	fi
}

test_homebrew_is_available() { # @test
	mock_homebrew

	run homebrew_is_available
	assert_success
}

test_homebrew_is_not_available() { # @test
	CFG_HOMEBREW_EXECUTABLE="brew-invalid-command"
	run homebrew_is_available
	assert_failure
}

test_homebrew_exec() { # @test
	mock_homebrew

	run homebrew_exec help
	assert_success
}

test_unsafe_homebrew_install_success() { # @test
	mock_homebrew

	test_fn() {
		echo "$TEST_CONFIG_MAJOR_PYTHON_VERSION" | unsafe_homebrew_install
	}
	run test_fn
	assert_success
}

test_unsafe_homebrew_install_failure() { # @test
	mock_homebrew "exit 1"

	test_fn() {
		echo "$TEST_CONFIG_MAJOR_PYTHON_VERSION" | unsafe_homebrew_install
	}
	run test_fn
	assert_failure "$ERR_INSTALLATION_FAILED"
}

test_unsafe_homebrew_get_python_executable_success() { # @test
	test_fn() {
		INTERNAL_VIRTUALENV_PYTHON_VERSION="$TEST_CONFIG_MAJOR_PYTHON_VERSION"

		unsafe_homebrew_get_python_executable
	}

	run test_fn
	assert_success
	assert_output --partial "/bin/python"
}

test_unsafe_homebrew_get_python_executable_failure() { # @test
	test_fn() {
		INTERNAL_VIRTUALENV_PYTHON_VERSION="99.9"

		unsafe_homebrew_get_python_executable
	}

	run test_fn
	assert_failure
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

test_homebrew_resolve_python_version() { # @test
	test_fn() {
		echo "$TEST_CONFIG_MAJOR_PYTHON_VERSION" | homebrew_resolve_python_version
	}
	run test_fn
	assert_success
	assert_output --partial "$TEST_CONFIG_MAJOR_PYTHON_VERSION."
}

test_homebrew_resolve_python_version_not_available() { # @test
	test_fn() {
		echo "99.9" | homebrew_resolve_python_version
	}
	run test_fn
	assert_success
	assert_output ""
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
		mock_log_file "ø"
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

test_dpv_internal_scan_virtualenv_match() { # @test
	mock_virtualenvs_dir

	test_fn() {
		local project_path="$(pwd)/venv-1"
		mock_virtualenv "pyenv" "3.9.9" "$project_path"

		PWD="$project_path" dpv_internal_scan_virtualenv

		echo "$INTERNAL_VIRTUALENV_PYTHON_VERSION"
		echo "$INTERNAL_VIRTUALENV_INSTALL_METHOD"
		echo "$INTERNAL_VIRTUALENV_DIR"
	}

	run test_fn
	assert_success
	assert_line --index 0 "3.9.9"
	assert_line --index 1 "pyenv"
	assert_line --index 2 "$CFG_VIRTUALENVS_DIR/3.9.9/venv-1"
}

test_dpv_internal_scan_virtualenv_not_match() { # @test
	mock_virtualenvs_dir

	test_fn() {
		local project_path="$(pwd)/venv-1"
		mock_virtualenv "pyenv" "3.9.9" "$project_path"

		PWD="$(pwd)/venv-2" dpv_internal_scan_virtualenv
	}

	refute test_fn
}

test_unsafe_dpv_internal_scan_python_version_success_runtime_txt() { # @test
	test_fn() {
		echo "python-3.9.1" >>runtime.txt
		unsafe_dpv_internal_scan_python_version
		echo "$INTERNAL_SCAN_PYTHON_VERSION"
		echo "$INTERNAL_SCAN_PYTHON_VERSION_SOURCE"
	}
	run test_fn
	assert_success
	assert_line --index 0 "3.9.1"
	assert_line --index 1 "runtime.txt"
}

test_unsafe_dpv_internal_scan_python_version_success_pyproject_toml_single_quote() { # @test
	test_fn() {
		echo "python = '3.9.1'" >>pyproject.toml
		unsafe_dpv_internal_scan_python_version
		echo "$INTERNAL_SCAN_PYTHON_VERSION"
		echo "$INTERNAL_SCAN_PYTHON_VERSION_SOURCE"
	}
	run test_fn
	assert_success
	assert_line --index 0 "3.9.1"
	assert_line --index 1 "pyproject.toml"
}

test_unsafe_dpv_internal_scan_python_version_success_pyproject_toml_double_quote() { # @test
	test_fn() {
		echo 'python = "3.9.1"' >>pyproject.toml
		unsafe_dpv_internal_scan_python_version
		echo "$INTERNAL_SCAN_PYTHON_VERSION"
		echo "$INTERNAL_SCAN_PYTHON_VERSION_SOURCE"
	}
	run test_fn
	assert_success
	assert_line --index 0 "3.9.1"
	assert_line --index 1 "pyproject.toml"
}

test_unsafe_dpv_internal_scan_python_version_success_any_installed_version_pyenv() { # @test
	test_fn() {
		mock_available_install_methods "pyenv"
		mock_installed_python_versions "pyenv" "3.9.2"

		unsafe_dpv_internal_scan_python_version
		echo "$INTERNAL_SCAN_PYTHON_VERSION"
		echo "$INTERNAL_SCAN_PYTHON_VERSION_SOURCE"
	}
	run test_fn
	assert_success
	assert_line --index 0 "3.9.2"
	assert_line --index 1 --partial "pyenv"
}

test_unsafe_dpv_internal_scan_python_version_success_any_installed_version_homebrew() { # @test
	test_fn() {
		mock_available_install_methods "homebrew"
		mock_installed_python_versions "homebrew" "3.9.3"

		unsafe_dpv_internal_scan_python_version
		echo "$INTERNAL_SCAN_PYTHON_VERSION"
		echo "$INTERNAL_SCAN_PYTHON_VERSION_SOURCE"
	}
	run test_fn
	assert_success
	assert_line --index 0 "3.9.3"
	assert_line --index 1 --partial "homebrew"
}

test_unsafe_dpv_internal_scan_python_version_success_any_available_version_pyenv() { # @test
	test_fn() {
		mock_available_install_methods "pyenv"
		mock_installed_python_versions "pyenv" ""
		mock_available_python_versions "pyenv" "3.9.2"

		unsafe_dpv_internal_scan_python_version
		echo "$INTERNAL_SCAN_PYTHON_VERSION"
		echo "$INTERNAL_SCAN_PYTHON_VERSION_SOURCE"
	}
	run test_fn
	assert_success
	assert_line --index 0 "3.9.2"
	assert_line --index 1 --partial "pyenv"
}

test_unsafe_dpv_internal_scan_python_version_success_any_available_version_homebrew() { # @test
	test_fn() {
		mock_available_install_methods "homebrew"
		mock_installed_python_versions "homebrew" ""
		mock_available_python_versions "homebrew" "3.9.3"

		unsafe_dpv_internal_scan_python_version
		echo "$INTERNAL_SCAN_PYTHON_VERSION"
		echo "$INTERNAL_SCAN_PYTHON_VERSION_SOURCE"
	}
	run test_fn
	assert_success
	assert_line --index 0 "3.9.3"
	assert_line --index 1 --partial "homebrew"
}

test_unsafe_dpv_internal_scan_python_version_failure_no_available_python_versions() { # @test
	test_fn() {
		mock_available_install_methods "pyenv homebrew"
		mock_installed_python_versions "homebrew" ""
		mock_available_python_versions "homebrew" ""
		mock_installed_python_versions "pyenv" ""
		mock_available_python_versions "pyenv" ""

		unsafe_dpv_internal_scan_python_version
		echo "$INTERNAL_SCAN_PYTHON_VERSION"
		echo "$INTERNAL_SCAN_PYTHON_VERSION_SOURCE"
	}
	run test_fn
	assert_failure "$ERR_CANNOT_DETERMINE_PYTHON_VERSION"
}

test_unsafe_dpv_internal_resolve_python_version_match_installed() { # @test
	test_fn() {
		mock_available_install_methods "pyenv"
		mock_installed_python_versions "pyenv" "3.9.4"

		unsafe_dpv_internal_resolve_python_version "3.9"
		echo "$INTERNAL_RESOLVE_PYTHON_VERSION"
		echo "$INTERNAL_RESOLVE_INSTALL_METHOD"
	}

	run test_fn
	assert_success
	assert_line --index 0 "3.9.4"
	assert_line --index 1 "pyenv"
}

test_unsafe_dpv_internal_resolve_python_version_match_available() { # @test
	test_fn() {
		mock_available_install_methods "pyenv"
		mock_installed_python_versions "pyenv" ""
		mock_available_python_versions "pyenv" "3.9.4"

		unsafe_dpv_internal_resolve_python_version "3.9"
		echo "$INTERNAL_RESOLVE_PYTHON_VERSION"
		echo "$INTERNAL_RESOLVE_INSTALL_METHOD"
	}

	run test_fn
	assert_success
	assert_line --index 0 "3.9.4"
	assert_line --index 1 "pyenv"
	assert_log_output --partial "needs to be installed"
}

test_unsafe_dpv_internal_resolve_python_version_not_match() { # @test
	test_fn() {
		mock_available_install_methods "pyenv"
		mock_installed_python_versions "pyenv" ""
		mock_available_python_versions "pyenv" "3.8.1"

		unsafe_dpv_internal_resolve_python_version "3.9"
		echo "$INTERNAL_RESOLVE_PYTHON_VERSION"
		echo "$INTERNAL_RESOLVE_INSTALL_METHOD"
	}

	run test_fn
	assert_failure "$ERR_CANNOT_RESOLVE_PYTHON_VERSION"
}

tes_unsafe_dpv_internal_create_virtualenv_success() { # @test
	mock_virtualenvs_dir

	test_fn() {
		INTERNAL_VIRTUALENV_INSTALL_METHOD="pyenv"
		INTERNAL_VIRTUALENV_PYTHON_VERSION="$TEST_CONFIG_MINOR_PYTHON_VERSION"

		PWD=venv_test unsafe_dpv_internal_create_virtualenv

		test -f "$INTERNAL_VIRTUALENV_DIR"
	}

	run test_fn
}

tes_unsafe_dpv_internal_create_virtualenv_failure() { # @test
	mock_virtualenvs_dir

	test_fn() {
		INTERNAL_VIRTUALENV_INSTALL_METHOD="pyenv"
		INTERNAL_VIRTUALENV_PYTHON_VERSION="99.9" # non-existent version

		local error
		PWD=venv_test unsafe_dpv_internal_create_virtualenv || error="$?"

		echo "$INTERNAL_VIRTUALENV_DIR"

		exit "$error"
	}

	run test_fn
	assert_failure "$ERR_CANNOT_CREATE_VIRTUALENV"
}

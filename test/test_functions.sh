setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
	export DIR

	# test config
	TEST_CONFIG_MAJOR_PYTHON_VERSION=3.9
	TEST_CONFIG_MINOR_PYTHON_VERSION=3.9.13

	# shellcheck source=./helper.sh
	. "$DIR/helper.sh"

	export ENV=""

	sed 's/#DPV-INTERNAL-EVAL#/if dpv_check_string_is_empty "$CMD_ARGS"; then while read -r line; do eval "$line"; done; else eval "$CMD_ARGS"; fi/' "$DIR/../src/dpv" >$BATS_TEST_TMPDIR/dpv-test
	chmod +x $BATS_TEST_TMPDIR/dpv-test
	export PATH="$PATH:$BATS_TEST_TMPDIR"
	function dpv-eval() {
		$TEST_SHELL $BATS_TEST_TMPDIR/dpv-test internal-eval "$@"
	}
}

#
# utility tests
#
test_dpv_check_is_set_true() { # @test
	run dpv-eval dpv_check_is_set ""
	assert_success
	assert_output ""
}

test_dpv_check_is_set_false() { # @test
	run dpv-eval dpv_check_is_set "ø"
	assert_failure
}

test_dpv_check_string_is_empty_true() { # @test
	run dpv-eval dpv_check_string_is_empty ""
	assert_success
}

test_dpv_check_string_is_empty_false() { # @test
	run dpv-eval dpv_check_string_is_empty "ø"
	assert_failure
}

test_dpv_check_file_is_empty_true() { # @test
	test_fn() {
		local tmp_file="$(mktemp)"
		touch $tmp_file
		dpv-eval dpv_check_file_is_empty "$tmp_file"
	}
	run test_fn
	assert_success
}

test_dpv_check_file_is_empty_false() { # @test
	test_fn() {
		local tmp_file="$(mktemp)"
		touch $tmp_file
		echo "x" >>$tmp_file
		dpv-eval dpv_check_file_is_empty "$tmp_file"
	}
	run test_fn
	assert_failure
}

test_dpv_pipe_format_major_version() { # @test
	test_fn() {
		echo "3.9.2" | dpv-eval dpv_pipe_format_major_version
		echo "3.10" | dpv-eval dpv_pipe_format_major_version
		echo "3.11-dev" | dpv-eval dpv_pipe_format_major_version
		echo "3.8" | dpv-eval dpv_pipe_format_major_version
	}
	run test_fn
	assert_line --index 0 "3.9"
	assert_line --index 1 "3.10"
	assert_line --index 2 "3.11-dev"
	assert_line --index 3 "3.8"
}

test_dpv_pipe_sort_version() { # @test
	test_fn() {
		printf "3.9.2\n3.8.4\n3.11-dev" | dpv-eval dpv_pipe_sort_version
	}
	run test_fn
	assert_line --index 0 "3.11-dev"
	assert_line --index 1 "3.9.2"
	assert_line --index 2 "3.8.4"
}

test_dpv_pipe_format_nl_to_space() { # @test
	test_fn() {
		printf "3.9.2\n3.8.4\n3.11-dev" | dpv-eval dpv_pipe_format_nl_to_space
	}
	run test_fn
	assert_output "3.9.2 3.8.4 3.11-dev"
}

test_dpv_string_lstrip() { # @test
	test_fn() {
		printf "foobar" | dpv-eval dpv_string_lstrip 2
	}
	run test_fn
	assert_output "obar"
}

test_dpv_string_uppercase() { # @test
	run dpv-eval dpv_string_uppercase "foo"
	assert_output "FOO"
}

test_dpv_string_lowercase() { # @test
	run dpv-eval dpv_string_lowercase "FOO"
	assert_output "foo"
}

test_dpv_string_count_characters() { # @test
	run dpv-eval dpv_string_count_characters "foofoo" "o"
	assert_output "4"
}

test_dpv_string_regex_replace() { # @test
	run dpv-eval dpv_string_regex_replace "foobarfoo" "^foo" ""
	assert_output "barfoo"
}

#
# internal utility tests
#

test_dpv_internal_mkdir_virtualenv_temporary() { # @test
	test_fn() {
		mock_virtualenv_python_version "99.9"
		dpv-eval dpv_internal_mkdir_virtualenv_temporary
	}
	run test_fn
	assert_success
	assert_output --partial "99.9"
}

test_dpv_internal_mkdir_virtualenv() { # @test
	test_fn() {
		mock_virtualenv_python_version "99.9"
		dpv-eval dpv_internal_mkdir_virtualenv
	}
	run test_fn
	assert_success
	assert_output --partial "99.9"
}

test_dpv_internal_pipe_format_python_versions() { # @test
	test_fn() {
		mock_available_install_methods "PYENV"
		mock_internal_installed_python_versions "PYENV" "3.9.1"

		printf "3.9.2\n3.9.1\n3.8\n2.7\n" | dpv-eval dpv_internal_pipe_format_python_versions "PYENV"
	}
	run test_fn
	assert_line --index 0 "3.9.1*"
	assert_line --index 1 "3.8"
}

test_dpv_internal_pipe_format_python_versions_all() { # @test
	test_fn() {
		mock_available_install_methods "PYENV"
		mock_internal_installed_python_versions "PYENV" "3.9.1"

		dpv-eval <<'EOF'
printf "3.9.2\n3.9.1\n3.8\n2.7\n" | dpv_internal_pipe_format_python_versions "PYENV" --all
EOF

	}
	run test_fn
	assert_line --index 0 "3.9.2"
	assert_line --index 1 "3.9.1*"
	assert_line --index 2 "3.8"
}

test_dpv_internal_parse_virtualenv_config_file() { # @test
	test_fn() {
		local project_path="$(pwd)/myproject"

		mock_virtualenv --install-method "PYENV" --python-version "3.9.9" --project-path "$project_path"
		dpv-eval <<EOF
PWD=$project_path
dpv_internal_scan_virtualenv
dpv_internal_parse_virtualenv_config_file "\$INTERNAL_SCAN_VIRTUALENV_virtualenv_dir/dpv.cfg"
echo "\$INTERNAL_PARSE_VIRTUALENV_CONFIG_FILE_path"
echo "\$INTERNAL_PARSE_VIRTUALENV_CONFIG_FILE_version"
echo "\$INTERNAL_PARSE_VIRTUALENV_CONFIG_FILE_install_method"
EOF
	}

	run test_fn
	assert_success
	assert_line --index 0 "$(pwd)/myproject"
	assert_line --index 1 "3.9.9"
	assert_line --index 2 "PYENV"
}

#
# vendor tests: UV
#

mock_UV() {
	local cmd="${1:-true}"
	local options="${2:-}"
	if [ "${BATS_MOCK_UV:-1}" -eq 1 ] || [[ " $options " == *" --force-mock "* ]]; then
		export UV_EXECUTABLE="$cmd"
	fi
}

# bats test_tags=vendor:uv
test_dpv_internal_UV_resolve_python_version() { # @test
	run dpv-eval <<EOF
echo 3.9 | dpv_internal_UV_resolve_python_version
EOF
	assert_success
	assert_output "3.9.13"
}

# bats test_tags=vendor:uv
test_dpv_internal_UV_resolve_python_version_not_available() { # @test
	run dpv-eval <<EOF
    echo "99.9" | dpv_internal_UV_resolve_python_version
EOF
	assert_success
	assert_output ""
}

# bats test_tags=vendor:uv
test_dpv_internal_UV_available_python_versions() { # @test
	run dpv-eval <<EOF
dpv_internal_UV_available_python_versions
echo "\$INTERNAL_UV_AVAILABLE_PYTHON_VERSIONS"
EOF
	assert_success
	assert_output --partial "$TEST_CONFIG_MINOR_PYTHON_VERSION"
}

# bats test_tags=vendor:uv
test_dpv_internal_UV_installed_python_versions() { # @test
	run dpv-eval dpv_internal_UV_installed_python_versions
	assert_success
}

# bats test_tags=vendor:uv
test_unsafe_UV_get_python_executable_success() { # @test
	run dpv-eval <<EOF
INTERNAL_INITIALIZE_VIRTUALENV_python_version="$TEST_CONFIG_MINOR_PYTHON_VERSION"
unsafe_dpv_internal_UV_get_python_executable
EOF
	assert_success
	assert_output --partial "/bin/python"
}

# bats test_tags=vendor:uv
test_unsafe_dpv_internal_UV_get_python_executable_failure() { # @test
	test_fn() {
		INTERNAL_INITIALIZE_VIRTUALENV_python_version="99.9"
		dpv-eval unsafe_dpv_internal_UV_get_python_executable
	}
	run test_fn
	assert_failure
}

# bats test_tags=vendor:uv
test_unsafe_dpv_internal_UV_install_success() { # @test
	mock_UV "echo" --force-mock
	run dpv-eval <<EOF
echo "$TEST_CONFIG_MINOR_PYTHON_VERSION" | unsafe_dpv_internal_UV_install
EOF
	assert_success
}

# bats test_tags=vendor:uv
test_unsafe_dpv_internal_UV_install_failure() { # @test
	mock_UV "false" --force-mock
	run dpv-eval <<EOF
echo "$TEST_CONFIG_MINOR_PYTHON_VERSION" | unsafe_dpv_internal_UV_install
EOF
	assert_failure "139"
}

# bats test_tags=vendor:uv
test_dpv_UV_exec() { # @test
	test_fn() {
		mock_UV
		dpv-eval dpv_UV_exec help
	}
	run test_fn
	assert_success
}

# bats test_tags=vendor:uv
test_dpv_UV_is_available() { # @test
	mock_UV
	run dpv-eval dpv_UV_is_available
	assert_success
}

# bats test_tags=vendor:uv
test_UV_is_not_available() { # @test
	mock_UV "invalid-command" --force-mock
	run dpv-eval dpv_UV_is_available
	assert_failure
}

#
# vendor tests: PYENV
#

mock_PYENV() {
	local cmd="${1:-true}"
	local options="${2:-}"
	if [ "${BATS_MOCK_PYENV:-1}" -eq 1 ] || [[ " $options " == *" --force-mock "* ]]; then
		export PYENV_EXECUTABLE="$cmd"
	fi
}

# bats test_tags=vendor:pyenv
test_dpv_internal_PYENV_resolve_python_version() { # @test
	run dpv-eval <<EOF
echo 2.7 | dpv_internal_PYENV_resolve_python_version
EOF
	assert_success
	assert_output "2.7.18"
}

# bats test_tags=vendor:pyenv
test_dpv_internal_PYENV_resolve_python_version_not_available() { # @test
	run dpv-eval <<EOF
    echo "99.9" | dpv_internal_PYENV_resolve_python_version
EOF
	assert_success
	assert_output ""
}

# bats test_tags=vendor:pyenv
test_dpv_internal_PYENV_available_python_versions() { # @test
	run dpv-eval <<EOF
dpv_internal_PYENV_available_python_versions
echo "\$INTERNAL_PYENV_AVAILABLE_PYTHON_VERSIONS"
EOF
	assert_success
	assert_output --partial "$TEST_CONFIG_MINOR_PYTHON_VERSION"
}

# bats test_tags=vendor:pyenv
test_dpv_internal_PYENV_installed_python_versions() { # @test
	run dpv-eval dpv_internal_PYENV_installed_python_versions
	assert_success
}

# bats test_tags=vendor:pyenv
test_unsafe_PYENV_get_python_executable_success() { # @test
	run dpv-eval <<EOF
INTERNAL_INITIALIZE_VIRTUALENV_python_version="$TEST_CONFIG_MINOR_PYTHON_VERSION"
unsafe_dpv_internal_PYENV_get_python_executable
EOF
	assert_success
	assert_output --partial "/bin/python"
}

# bats test_tags=vendor:pyenv
test_unsafe_dpv_internal_PYENV_get_python_executable_failure() { # @test
	test_fn() {
		INTERNAL_INITIALIZE_VIRTUALENV_python_version="99.9"
		dpv-eval unsafe_dpv_internal_PYENV_get_python_executable
	}
	run test_fn
	assert_failure
}

# bats test_tags=vendor:pyenv
test_unsafe_dpv_internal_PYENV_install_success() { # @test
	mock_PYENV "echo" --force-mock
	run dpv-eval <<EOF
echo "$TEST_CONFIG_MINOR_PYTHON_VERSION" | unsafe_dpv_internal_PYENV_install
EOF
	assert_success
}

# bats test_tags=vendor:pyenv
test_unsafe_dpv_internal_PYENV_install_failure() { # @test
	mock_PYENV "false" --force-mock
	run dpv-eval <<EOF
echo "$TEST_CONFIG_MINOR_PYTHON_VERSION" | unsafe_dpv_internal_PYENV_install
EOF
	assert_failure "139"
}

# bats test_tags=vendor:pyenv
test_dpv_PYENV_exec() { # @test
	test_fn() {
		mock_PYENV
		dpv-eval dpv_PYENV_exec help
	}
	run test_fn
	assert_success
}

# bats test_tags=vendor:pyenv
test_dpv_PYENV_is_available() { # @test
	mock_PYENV
	run dpv-eval dpv_PYENV_is_available
	assert_success
}

# bats test_tags=vendor:pyenv
test_PYENV_is_not_available() { # @test
	mock_PYENV "invalid-command" --force-mock
	run dpv-eval dpv_PYENV_is_available
	assert_failure
}

#
# vendor tests: HOMEBREW
#
mock_HOMEBREW() {
	local cmd="${1:-true}"
	local options="${2:-}"
	if [ "${BATS_MOCK_HOMEBREW:-1}" -eq 1 ] || [[ " $options " == *" --force-mock "* ]]; then
		export HOMEBREW_EXECUTABLE="$cmd"
	fi
}

# bats test_tags=vendor:homebrew
test_dpv_HOMEBREW_is_available() { # @test
	test_fn() {
		mock_HOMEBREW
		dpv-eval dpv_HOMEBREW_is_available
	}
	run test_fn
	assert_success
}

# bats test_tags=vendor:homebrew
test_HOMEBREW_is_not_available() { # @test
	mock_HOMEBREW "brew-invalid-command" --force-mock
	run dpv-eval dpv_HOMEBREW_is_available
	assert_failure
}

# bats test_tags=vendor:homebrew
test_dpv_HOMEBREW_exec() { # @test
	test_fn() {
		mock_HOMEBREW
		dpv-eval dpv_HOMEBREW_exec help
	}
	run test_fn
	assert_success
}

# bats test_tags=vendor:homebrew
test_unsafe_dpv_internal_HOMEBREW_install_success() { # @test
	test_fn() {
		mock_HOMEBREW
		echo "$TEST_CONFIG_MAJOR_PYTHON_VERSION" | dpv-eval unsafe_dpv_internal_HOMEBREW_install
	}
	run test_fn
	assert_success
}

# bats test_tags=vendor:homebrew
test_unsafe_dpv_internal_HOMEBREW_install_failure() { # @test
	test_fn() {
		mock_HOMEBREW "false" --force-mock
		echo "$TEST_CONFIG_MAJOR_PYTHON_VERSION" | dpv-eval unsafe_dpv_internal_HOMEBREW_install
	}
	run test_fn
	assert_failure "139"
}

# bats test_tags=vendor:homebrew
test_unsafe_dpv_internal_HOMEBREW_get_python_executable_success() { # @test
	run dpv-eval <<EOF
INTERNAL_INITIALIZE_VIRTUALENV_python_version="$TEST_CONFIG_MAJOR_PYTHON_VERSION"
unsafe_dpv_internal_HOMEBREW_get_python_executable
EOF
	assert_success
	assert_output --partial "/bin/python"
}

# bats test_tags=vendor:homebrew
test_unsafe_dpv_internal_HOMEBREW_get_python_executable_failure() { # @test
	test_fn() {
		INTERNAL_INITIALIZE_VIRTUALENV_python_version="99.9"
		dpv-eval unsafe_dpv_internal_HOMEBREW_get_python_executable
	}

	run test_fn
	assert_failure
}

# bats test_tags=vendor:homebrew
test_dpv_internal_HOMEBREW_available_python_versions() { # @test
	run dpv-eval <<'EOF'
dpv_internal_HOMEBREW_available_python_versions
echo "$INTERNAL_HOMEBREW_AVAILABLE_PYTHON_VERSIONS"
EOF
	assert_success
	assert_output --partial "$TEST_CONFIG_MAJOR_PYTHON_VERSION"
}

# bats test_tags=vendor:homebrew
test_dpv_internal_HOMEBREW_installed_python_versions() { # @test
	run dpv-eval dpv_internal_HOMEBREW_installed_python_versions
	assert_success
}

# bats test_tags=vendor:homebrew
test_HOMEBREW_resolve_python_version() { # @test
	test_fn() {
		echo "$TEST_CONFIG_MAJOR_PYTHON_VERSION" | dpv-eval dpv_internal_HOMEBREW_resolve_python_version
	}
	run test_fn
	assert_success
	assert_output --partial "$TEST_CONFIG_MAJOR_PYTHON_VERSION."
}

# bats test_tags=vendor:homebrew
test_dpv_internal_HOMEBREW_resolve_python_version_not_available() { # @test
	test_fn() {
		echo "99.9" | dpv-eval dpv_internal_HOMEBREW_resolve_python_version
	}
	run test_fn
	assert_success
	assert_output ""
}

# bats test_tags=vendor:homebrew
test_dpv_HOMEBREW_format_python_formula() { # @test
	run dpv-eval dpv_HOMEBREW_format_python_formula "$TEST_CONFIG_MINOR_PYTHON_VERSION"
	assert_output "python@$TEST_CONFIG_MAJOR_PYTHON_VERSION"
}

# bats test_tags=vendor:homebrew
test_dpv_HOMEBREW_pipe_expand_python_version() { # @test
	test_fn() {
		echo "$TEST_CONFIG_MAJOR_PYTHON_VERSION" | dpv-eval dpv_HOMEBREW_pipe_expand_python_version
	}
	run test_fn
	assert_output --partial "$TEST_CONFIG_MAJOR_PYTHON_VERSION."
}

# bats test_tags=vendor:homebrew
test_dpv_HOMEBREW_pipe_expand_python_version_not_available() { # @test
	test_fn() {
		echo "2.0" | dpv-eval dpv_HOMEBREW_pipe_expand_python_version
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
		dpv-eval dpv_internal_set_log_file
		echo "$INTERNAL_LOG_FILE"
	}
	run test_fn
	assert_success
	assert_output --partial "dpv_log"
}

test_unsafe_dpv_internal_set_available_install_methods_success() { # @test
	run dpv-eval unsafe_dpv_internal_set_available_install_methods
	assert_success
}

test_unsafe_dpv_internal_set_available_install_methods_fail() { # @test
	test_fn() {
		CFG_PREFERRED_INSTALL_METHODS=""
		dpv-eval unsafe_dpv_internal_set_available_install_methods
	}
	run test_fn
	assert_failure "136"
}

# bats test_tags=vendor:uv
test_unsafe_dpv_internal_UV_install_deps_success() { # @test
	test_fn() {
        mock_virtualenv_install_method "UV"

		export DPV_MOCK_ARG_DEPS="y==1 x[foo]<2"
		export DPV_MOCK_UV_INSTALL="echo"

		dpv-eval unsafe_dpv_internal_install_deps
	}

	run test_fn

	assert_success
	assert_line --index 0 "uv: installing dependencies"
	assert_line --index 1 "  > y==1 x[foo]<2"
	assert_line --index 2 "uv: done"
}

test_unsafe_dpv_internal_install_deps_success() { # @test
	test_fn() {
		export DPV_MOCK_ARG_DEPS="y==1 x[foo]<2"
		export DPV_MOCK_PIP="echo"
		dpv-eval unsafe_dpv_internal_install_deps
	}

	run test_fn

	assert_success
	assert_line --index 0 "pip: installing dependencies"
	assert_line --index 1 "  > install y==1 x[foo]<2"
	assert_line --index 2 "pip: done"
}

test_unsafe_dpv_internal_install_deps_error() { # @test
	test_fn() {
		export DPV_MOCK_ARG_DEPS="y==1 x[foo]<2"
		export DPV_MOCK_PIP="false"
		dpv-eval unsafe_dpv_internal_install_deps
	}

	run test_fn

	assert_failure
	assert_line --index 0 "pip: installing dependencies"
	assert_line --index 2 "pip: failed"
}

test_dpv_internal_run_command_log_failure_fail() { # @test
	test_fn() {
		mock_log_file
		dpv-eval dpv_internal_run_command_log_failure "echo 'something failed' ; exit 1"
	}
	run test_fn
	assert_failure
	assert_log_output --partial "something failed"
}

test_dpv_internal_run_command_log_failure_success() { # @test
	run dpv-eval dpv_internal_run_command_log_failure "echo 'it works'"
	assert_success
	refute_log_output --partial "it works"
}

test_dpv_internal_print_logs_no_logs() { # @test
	run dpv-eval dpv_internal_print_logs
	assert_output ""
}

test_dpv_internal_print_logs_with_logs() { # @test
	mock_log_file
	run dpv-eval <<EOF
dpv_internal_log "yes logs"
dpv_internal_print_logs
EOF
	assert_output --partial "- yes logs"
}

test_dpv_internal_scan_virtualenv_match() { # @test
	local project_path="$(pwd)/venv-1"
	mock_virtualenv --install-method "PYENV" --python-version "3.9.9" --project-path "$project_path"

	run dpv-eval <<EOF
PWD="$project_path" dpv_internal_scan_virtualenv
echo "\$INTERNAL_SCAN_VIRTUALENV_virtualenv_dir"
echo "\$INTERNAL_SCAN_VIRTUALENV_version"
echo "\$INTERNAL_SCAN_VIRTUALENV_install_method"
EOF

	assert_success
	assert_line --index 0 "$DPV_DIR/virtualenvs/3.9.9/venv-1"
	assert_line --index 1 "3.9.9"
	assert_line --index 2 "PYENV"
}

test_dpv_internal_scan_virtualenv_not_match() { # @test
	local project_path="$(pwd)/venv-1"

	mock_virtualenv --install-method "PYENV" --python-version "3.9.9" --project-path "$project_path"
	run dpv-eval <<EOF
PWD="$(pwd)/venv-2"
dpv_internal_scan_virtualenv
EOF

	assert_output ""
}

test_dpv_internal_scan_python_version_success_runtime_txt() { # @test
	run dpv-eval <<EOF
echo "python-3.9.1" >>runtime.txt
dpv_internal_scan_python_version
echo \$INTERNAL_SCAN_PYTHON_VERSION_version
echo \$INTERNAL_SCAN_PYTHON_VERSION_source
EOF
	assert_success
	assert_line --index 0 "3.9.1"
	assert_line --index 1 "runtime.txt"
}

test_dpv_internal_scan_python_version_success_pyproject_toml() { # @test
	run dpv-eval <<'EOF'
echo "python = 3.9.1" >>pyproject.toml
dpv_internal_scan_python_version
echo $INTERNAL_SCAN_PYTHON_VERSION_version
echo $INTERNAL_SCAN_PYTHON_VERSION_source
EOF
	assert_success
	assert_line --index 0 "3.9.1"
	assert_line --index 1 "pyproject.toml"
}

# bats test_tags=vendor:pyenv
test_dpv_internal_scan_python_version_success_any_installed_version_PYENV() { # @test
	mock_available_install_methods "PYENV"
	mock_internal_installed_python_versions "PYENV" "3.9.2"
	run dpv-eval <<'EOF'
dpv_internal_scan_python_version
echo $INTERNAL_SCAN_PYTHON_VERSION_version
echo $INTERNAL_SCAN_PYTHON_VERSION_source
EOF
	assert_success
	assert_line --index 0 "3.9.2"
	assert_line --index 1 --partial "pyenv"
}

# bats test_tags=vendor:homebrew
test_dpv_internal_scan_python_version_success_any_installed_version_HOMEBREW() { # @test
	mock_available_install_methods "HOMEBREW"
	mock_internal_installed_python_versions "HOMEBREW" "3.9.3"
	run dpv-eval <<'EOF'
dpv_internal_scan_python_version
echo $INTERNAL_SCAN_PYTHON_VERSION_version
echo $INTERNAL_SCAN_PYTHON_VERSION_source
EOF
	assert_success
	assert_line --index 0 "3.9.3"
	assert_line --index 1 --partial "homebrew"
}

# bats test_tags=vendor:pyenv
test_dpv_internal_scan_python_version_success_any_available_version_PYENV() { # @test
	mock_available_install_methods "PYENV"
	mock_internal_installed_python_versions "PYENV" ""
	mock_internal_available_python_versions "PYENV" "3.9.2"
	run dpv-eval <<'EOF'
dpv_internal_scan_python_version
echo $INTERNAL_SCAN_PYTHON_VERSION_version
echo $INTERNAL_SCAN_PYTHON_VERSION_source
EOF
	assert_success
	assert_line --index 0 "3.9.2"
	assert_line --index 1 --partial "pyenv"
}

# bats test_tags=vendor:homebrew
test_dpv_internal_scan_python_version_success_any_available_version_HOMEBREW() { # @test
	test_fn() {
		mock_available_install_methods "HOMEBREW"
		mock_internal_installed_python_versions "HOMEBREW" ""
		mock_internal_available_python_versions "HOMEBREW" "3.9.3"
		dpv-eval <<'EOF'
dpv_internal_scan_python_version
echo $INTERNAL_SCAN_PYTHON_VERSION_version
echo $INTERNAL_SCAN_PYTHON_VERSION_source
EOF
	}
	run test_fn
	assert_success
	assert_line --index 0 "3.9.3"
	assert_line --index 1 --partial "homebrew"
}

test_dpv_internal_scan_python_version_failure_no_internal_available_python_versions() { # @test
	mock_available_install_methods "PYENV HOMEBREW"
	mock_internal_installed_python_versions "HOMEBREW" ""
	mock_internal_available_python_versions "HOMEBREW" ""
	mock_internal_installed_python_versions "PYENV" ""
	mock_internal_available_python_versions "PYENV" ""
	run dpv-eval dpv_internal_scan_python_version
	assert_failure
	assert_output ""
}

test_dpv_internal_resolve_python_version_match_installed() { # @test
	run dpv-eval <<EOF
$(mock_available_install_methods "PYENV HOMEBREW")
$(mock_internal_installed_python_versions "PYENV" "3.9.4")
$(mock_internal_installed_python_versions "HOMEBREW" "3.9.2")

dpv_internal_resolve_python_version "3.9"

echo "\$INTERNAL_RESOLVE_PYTHON_VERSION"
echo "\$INTERNAL_RESOLVE_INSTALL_METHOD"
EOF

	assert_success
	assert_line --index 0 "3.9.4"
	assert_line --index 1 "PYENV"
}

test_dpv_internal_resolve_python_version_match_available() { # @test
	run dpv-eval <<EOF
$(mock_log_file)
$(mock_available_install_methods "PYENV")
$(mock_internal_installed_python_versions "PYENV" "")
$(mock_internal_available_python_versions "PYENV" "3.9.4")

dpv_internal_resolve_python_version "3.9"

echo "\$INTERNAL_RESOLVE_PYTHON_VERSION"
echo "\$INTERNAL_RESOLVE_INSTALL_METHOD"
EOF

	assert_success
	assert_line --index 0 "3.9.4"
	assert_line --index 1 "PYENV"
	assert_log_output --partial "needs to be installed"
}

test_dpv_internal_resolve_python_version_not_match() { # @test
	run dpv-eval <<EOF
$(mock_available_install_methods "PYENV")
$(mock_internal_installed_python_versions "PYENV" "")
$(mock_internal_available_python_versions "PYENV" "3.8.1")

dpv_internal_resolve_python_version "3.9"
EOF
	assert_failure
}

test_unsafe_dpv_internal_create_virtualenv_success() { # @test
	run dpv-eval <<EOF
$(mock_virtualenvs_dir)

INTERNAL_INITIALIZE_VIRTUALENV_install_method="PYENV"
INTERNAL_INITIALIZE_VIRTUALENV_python_version="$TEST_CONFIG_MINOR_PYTHON_VERSION"

PWD=venv_test unsafe_dpv_internal_create_virtualenv

test -f "\$INTERNAL_CREATE_VIRTUALENV_virtualenv_dir/dpv.cfg"
test -d "\$INTERNAL_CREATE_VIRTUALENV_virtualenv_dir/lib"
EOF

	assert_success
}

test_unsafe_dpv_internal_create_virtualenv_failure() { # @test
	run dpv-eval <<EOF
$(mock_virtualenvs_dir)

INTERNAL_INITIALIZE_VIRTUALENV_install_method="PYENV"
INTERNAL_INITIALIZE_VIRTUALENV_python_version="99.9" # non-existent version

PWD=venv_test unsafe_dpv_internal_create_virtualenv || error="\$?"

echo "\$INTERNAL_INITIALIZE_VIRTUALENV_virtualenv_dir"

exit "\$error"
EOF

	assert_failure "140"
}

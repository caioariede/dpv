setup() {
	load 'test_helper/bats-support/load'
	load 'test_helper/bats-assert/load'

	DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

	# test config
	TEST_CONFIG_MAJOR_PYTHON_VERSION=3.9
	TEST_CONFIG_MINOR_PYTHON_VERSION=3.9.10

	# shellcheck source=./helper.sh
	. "$DIR/helper.sh"

	unset DPV_THEME
	export EXEC="$TEST_SHELL $DIR/../src/dpv"

	mock_log_file
}

#test_coverage() {
#	# the poor's man simple code coverage
#	test_fn() {
#		local testcases="$(grep "^test_cmd_.*@test" "$BATS_TEST_FILENAME")"
#
#		local missing="$(while IFS= read -r line; do
#			if [[ "$testcases" != *"test_cmd_$line"* ]]; then
#				echo $line
#			fi
#		done < <(grep -o "^cmd_[^(]\+" "$(which dpv)" | sed 's/cmd_//' | sort | uniq))"
#
#		if [[ "$missing" != "" ]]; then
#			echo "commands not covered by tests: $missing"
#			exit 1
#		fi
#	}
#	run test_fn
#	assert_success
#
#}

#test_dpv_cmd_help() {
#	test_fn() {
#		local help_output="$($EXEC help)"
#
#		while IFS= read -r line; do
#			if [[ "$help_output" != *"  dpv $line "* ]]; then
#				echo "command not present in help output: $line"
#				echo "$help_output"
#				exit 1
#			fi
#		done < <(grep -o "^cmd_[^(]\+" "$(which dpv)" | sed 's/cmd_//' | sort | uniq)
#	}
#	run test_fn
#	assert_output ""
#	assert_success
#}

test_dpv_internal_cmd_versions() { # @test
	test_fn() {
        mock_available_install_methods "$(printf "%s\n%s" "PYENV" "HOMEBREW")"

		mock_internal_available_python_versions "PYENV" "3.9.2 3.9.1 3.8"
		mock_internal_installed_python_versions "PYENV" "3.9.1"
		mock_internal_available_python_versions "HOMEBREW" "3.11.2 3.11.1 3.10"
		mock_internal_installed_python_versions "HOMEBREW" "3.11.2"

		$EXEC versions
	}

	run test_fn

	assert_success
	assert_output --partial "pyenv: 3.9.1* 3.8"
	assert_output --partial "homebrew: 3.11.2* 3.10"
}

test_dpv_internal_cmd_versions_all() { # @test
	test_fn() {
        mock_available_install_methods "$(printf "%s\n%s" "PYENV" "HOMEBREW")"

		mock_internal_available_python_versions "PYENV" "3.9.2 3.9.1 3.8"
		mock_internal_installed_python_versions "PYENV" "3.9.1"
		mock_internal_available_python_versions "HOMEBREW" "3.11.2 3.11.1 3.10"
		mock_internal_installed_python_versions "HOMEBREW" "3.11.2"

		$EXEC versions --all
	}

	run test_fn

	assert_output --partial "pyenv: 3.9.2 3.9.1* 3.8"
	assert_output --partial "homebrew: 3.11.2* 3.11.1 3.10"
}

test_dpv_internal_cmd_versions_installed() { # @test
	test_fn() {
        mock_available_install_methods "$(printf "%s\n%s" "PYENV" "HOMEBREW")"

		mock_internal_available_python_versions "PYENV" "3.9.2 3.9.1 3.8"
		mock_internal_installed_python_versions "PYENV" "3.9.1"
		mock_internal_available_python_versions "HOMEBREW" "3.11.2 3.11.1 3.10"
		mock_internal_installed_python_versions "HOMEBREW" "3.11.2"

		$EXEC versions --installed
	}

	run test_fn

	assert_output --partial "pyenv: 3.9.1*"
	assert_output --partial "homebrew: 3.11.2*"
}

test_cmd_drop_current_virtualenv() { # @test
	test_fn() {
		mock_virtualenv --install-method "pyenv" --python-version "3.9.2" --project-path "$(pwd)" --activate

		$EXEC drop
	}

	run test_fn

	[ ! -d "$DPV_MOCK_VIRTUALENV_DIR" ]
}

test_cmd_drop_another_virtualenv() { # @test
	mock_virtualenv --install-method "pyenv" --python-version "3.9.2" --project-path "$(pwd)/abc"
	VENV_A="$VENV_DIR"
	mock_virtualenv --install-method "pyenv" --python-version "3.9.2" --project-path "$(pwd)/def"
	VENV_B="$VENV_DIR"

	run $EXEC drop def # delete VENV_B

	assert_success

	[ -d "$VENV_A" ]
	[ ! -d "$VENV_B" ]
}

test_dpv_cmd_list() { # @test
	test_fn() {
		mock_virtualenv --install-method "pyenv" --python-version "3.9.1" --project-path "$(pwd)/def"
		mock_virtualenv --install-method "pyenv" --python-version "3.9.2" --project-path "$(pwd)/abc"

		$EXEC list
	}

	run test_fn
	assert_success
	assert_line --index 1 --partial "virtualenvs/3.9.2/abc"
	assert_line --index 2 --partial "virtualenvs/3.9.1/def"
}

test_dpv_internal_cmd_info_not_activated() { # @test
	test_fn() {
		mock_virtualenv --install-method "pyenv" --python-version "3.9.9" --project-path "$(pwd)"

		$EXEC info
	}

	run test_fn

	assert_success
	assert_output --partial "status: not activated"

	# should show config
	assert_output --partial "config:"
	# should show virtualenv config
	assert_output --partial "virtualenv:"

}

test_dpv_internal_cmd_info_activated() { # @test
	test_fn() {
		mock_virtualenv --install-method "pyenv" --python-version "3.9.2" --project-path "$(pwd)" --activate

		$EXEC info
	}

	run test_fn

	assert_success
	assert_output --partial "status: activated"

	# should show config
	assert_output --partial "config:"
	# should show virtualenv config
	assert_output --partial "virtualenv:"
}

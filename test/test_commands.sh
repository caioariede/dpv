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

	mock_log_file "$(mktemp "${TMPDIR:-/tmp/}dpv_test_logs.XXXXX")"
}

test_coverage() { # @test
	# the poor's man simple code coverage
	test_fn() {
		local testcases="$(grep "^test_cmd_.*@test" "$BATS_TEST_FILENAME")"

		local missing="$(while IFS= read -r line; do
			if [[ "$testcases" != *"test_cmd_$line"* ]]; then
				echo $line
			fi
		done < <(grep -o "^cmd_[^(]\+" "$(which dpv)" | sed 's/cmd_//' | sort | uniq))"

		if [[ "$missing" != "" ]]; then
			echo "commands not covered by tests: $missing"
			exit 1
		fi
	}
	run test_fn
	assert_success

}

test_dpv_cmd_help() { # @test
	test_fn() {
		local help_output="$(DPV_THEME= dpv help)"

		while IFS= read -r line; do
			if [[ "$help_output" != *"  dpv $line "* ]]; then
				echo "command not present in help output: $line"
				echo "$help_output"
				exit 1
			fi
		done < <(grep -o "^cmd_[^(]\+" "$(which dpv)" | sed 's/cmd_//' | sort | uniq)
	}
	run test_fn
	assert_success
}

test_dpv_cmd_versions() { # @test
	test_fn() {
		mock_available_install_methods "PYENV HOMEBREW"
		mock_available_python_versions "PYENV" "3.9.2 3.9.1 3.8"
		mock_installed_python_versions "PYENV" "3.9.1"
		mock_available_python_versions "HOMEBREW" "3.11.2 3.11.1 3.10"
		mock_installed_python_versions "HOMEBREW" "3.11.2"

		dpv versions
	}

	run test_fn

	assert_output --partial "pyenv: 3.9.1* 3.8"
	assert_output --partial "homebrew: 3.11.2* 3.10"
}

test_dpv_cmd_versions_all() { # @test
	test_fn() {
		mock_available_install_methods "PYENV HOMEBREW"
		mock_available_python_versions "PYENV" "3.9.2 3.9.1 3.8"
		mock_installed_python_versions "PYENV" "3.9.1"
		mock_available_python_versions "HOMEBREW" "3.11.2 3.11.1 3.10"
		mock_installed_python_versions "HOMEBREW" "3.11.2"

		dpv versions --all
	}

	run test_fn

	assert_output --partial "pyenv: 3.9.2 3.9.1* 3.8"
	assert_output --partial "homebrew: 3.11.2* 3.11.1 3.10"
}

test_dpv_cmd_versions_installed() { # @test
	test_fn() {
		mock_available_install_methods "PYENV HOMEBREW"
		mock_available_python_versions "PYENV" "3.9.2 3.9.1 3.8"
		mock_installed_python_versions "PYENV" "3.9.1"
		mock_available_python_versions "HOMEBREW" "3.11.2 3.11.1 3.10"
		mock_installed_python_versions "HOMEBREW" "3.11.2"

		dpv versions --installed
	}

	run test_fn

	assert_output --partial "pyenv: 3.9.1*"
	assert_output --partial "homebrew: 3.11.2*"
}

test_cmd_drop() { # @test
}

test_dpv_cmd_list() { # @test
	test_fn() {
		mock_virtualenvs_dir

		mock_virtualenv "pyenv" "3.9.1" "$(pwd)/def"
		mock_virtualenv "pyenv" "3.9.2" "$(pwd)/abc"

		dpv list
	}

	run test_fn
	assert_success
	assert_line --index 1 --partial "virtualenvs/3.9.2/abc"
	assert_line --index 2 --partial "virtualenvs/3.9.1/def"
}

test_dpv_cmd_info_not_activated() { # @test
	run dpv info

	assert_success
	assert_output --partial "status: not activated"

	# should show config
	assert_output --partial "config:"
}

test_dpv_cmd_info_activated() { # @test
	mock_virtualenvs_dir

	test_fn() {
		local project_path="$(pwd)/venv-1"
		mock_virtualenv "pyenv" "3.9.9" "$project_path"

		export DPV_VIRTUALENV_DIR="$DPV_MOCK_VIRTUALENVS_DIR/3.9.9/venv-1"

		dpv info
	}

	run test_fn

	assert_success
	assert_output --partial "status: activated"

	# should show config
	assert_output --partial "config:"
	# should show virtualenv config
	assert_output --partial "virtualenv:"

}

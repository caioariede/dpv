# make executables in src/ visible to PATH
PATH="$DIR/../src:$PATH"

DPV_DIR="$BATS_TEST_TMPDIR/test_dpv"
PRJ_DIR="$BATS_TEST_TMPDIR/test_dpv_proj"
export DPV_DIR
export PRJ_DIR

rm -rf "$DPV_DIR"
rm -rf "$PRJ_DIR"
mkdir -p "$DPV_DIR"
mkdir -p "$PRJ_DIR"

cd "$PRJ_DIR" || exit

#
# mocks
#
mock_log_file() {
	INTERNAL_LOG_FILE="$1"

    # for command tests:
	export DPV_MOCK_LOG_FILE="$1"
}

mock_virtualenv_python_version() {
	INTERNAL_VIRTUALENV_PYTHON_VERSION="$1"

    # for command tests:
	export DPV_MOCK_VIRTUALENV_PYTHON_VERSION="$1"
}

mock_available_install_methods() {
	INTERNAL_AVAILABLE_INSTALL_METHODS="$@"

    # for command tests:
	export DPV_MOCK_AVAILABLE_INSTALL_METHODS="$@"
}

mock_installed_python_versions() {
	local install="$(echo "$1" | tr '[:lower:]' '[:upper:'])"
	shift
    local versions=$(echo $@ | tr " " "\n")
	local var="INTERNAL_${install}_INSTALLED_PYTHON_VERSIONS"
	local mock_var="export DPV_MOCK_${install}_INSTALLED_PYTHON_VERSIONS"
	eval "$var='$versions'"
	eval "$mock_var='$versions'"
}

mock_available_python_versions() {
	local install="$(echo "$1" | tr '[:lower:]' '[:upper:'])"
	shift
    local versions=$(echo $@ | tr " " "\n")
	local var="INTERNAL_${install}_AVAILABLE_PYTHON_VERSIONS"
	local mock_var="export DPV_MOCK_${install}_AVAILABLE_PYTHON_VERSIONS"
	eval "$var='$versions'"
	eval "$mock_var='$versions'"
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

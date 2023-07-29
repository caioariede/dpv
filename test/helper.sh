DPV_DIR="$BATS_TEST_TMPDIR/.dpv"
export DPV_DIR

rm -rf "$DPV_DIR"
mkdir -p "$DPV_DIR"

DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"

mkdir -p "$BATS_TEST_TMPDIR/myproject"
cd "$BATS_TEST_TMPDIR/myproject" || exit

#
# mocks
#
MOCK_LOG_FILE="$(mktemp "${TMPDIR:-/tmp/}dpv_test_logs.XXXXX")"

mock_log_file() {
	export DPV_MOCK_LOG_FILE="$MOCK_LOG_FILE"
}

mock_virtualenv_python_version() {
	INTERNAL_INITIALIZE_VIRTUALENV_python_version="$1"

	# for command tests:
	export DPV_MOCK_VIRTUALENV_PYTHON_VERSION="$1"
}

mock_available_install_methods() {
	export DPV_MOCK_AVAILABLE_INSTALL_METHODS="$@"
	INTERNAL_AVAILABLE_INSTALL_METHODS="$@"
}

mock_internal_installed_python_versions() {
	local install="$1"
	shift
	local versions=$(echo $@ | tr " " "\n")
	local mock_var="export DPV_MOCK_${install}_INSTALLED_PYTHON_VERSIONS"
	eval "$mock_var='$versions'"
}

mock_internal_available_python_versions() {
	local install="$1"
	shift
	local versions=$(echo $@ | tr " " "\n")
	local mock_var="export DPV_MOCK_${install}_AVAILABLE_PYTHON_VERSIONS"
	eval "$mock_var='$versions'"
}

mock_virtualenvs_dir() {
	export DPV_MOCK_VIRTUALENVS_DIR="$DPV_DIR/virtualenvs"
	CFG_VIRTUALENVS_DIR="$DPV_DIR/virtualenvs"
}

mock_virtualenv() {
	mock_virtualenvs_dir

	local install_method
	local python_version
	local project_path
	local activate=0
	local opt_echo=0

	while [[ "$#" -gt 0 ]]; do
		case "$1" in
		--install-method | --python-version | --project-path)
			declare "$(echo "${1:2}" | tr '-' '_')"="$2"
			shift
			shift
			;;
		--activate)
			activate=1
			shift
			;;
		*)
			echo "invalid argument: $1"
			exit
			;;
		esac
	done

	local venv_name="$(basename "$project_path")"

	local venv_path="$DPV_MOCK_VIRTUALENVS_DIR/$python_version/$venv_name"
	mkdir -p "$venv_path"
	printf "path = $project_path\nversion = $python_version\ninstall_method = $install_method\n" >"$venv_path/dpv.cfg"

	if [[ "$activate" -eq "1" ]]; then
		export DPV_MOCK_VIRTUALENV_DIR="$venv_path"
	fi

	VENV_DIR="$venv_path"
}

#
# custom asserts
#

assert_log_output() {
	run cat $MOCK_LOG_FILE
	assert_output "$@"
}

refute_log_output() {
	run cat $MOCK_LOG_FILE
	refute_output "$@"
}

run_oneline() {
	"$TEST_SHELL" "$DIR/../src/dpv" internal-function "$@"
}

run_script() {
	"$TEST_SHELL" "$DIR/../src/dpv" internal-function
}

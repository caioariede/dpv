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
	INTERNAL_INITIALIZE_VIRTUALENV_python_version="$1"

	# for command tests:
	export DPV_MOCK_VIRTUALENV_PYTHON_VERSION="$1"
}

mock_available_install_methods() {
	INTERNAL_AVAILABLE_INSTALL_METHODS="$@"

	# for command tests:
	export DPV_MOCK_AVAILABLE_INSTALL_METHODS="$@"
}

mock_internal_installed_python_versions() {
	local install="$1"
	shift
	local versions=$(echo $@ | tr " " "\n")
	local var="INTERNAL_${install}_INSTALLED_PYTHON_VERSIONS"
	local mock_var="export DPV_MOCK_${install}_INSTALLED_PYTHON_VERSIONS"
	eval "$var='$versions'"
	eval "$mock_var='$versions'"
}

mock_internal_available_python_versions() {
	local install="$1"
	shift
	local versions=$(echo $@ | tr " " "\n")
	local var="INTERNAL_${install}_AVAILABLE_PYTHON_VERSIONS"
	local mock_var="export DPV_MOCK_${install}_AVAILABLE_PYTHON_VERSIONS"
	eval "$var='$versions'"
	eval "$mock_var='$versions'"
}

mock_virtualenvs_dir() {
	CFG_VIRTUALENVS_DIR="$(pwd)/virtualenvs"

	# for command tests:
	export DPV_MOCK_VIRTUALENVS_DIR="$(pwd)/virtualenvs"
}

mock_virtualenv() {
	if [[ "${DPV_MOCK_VIRTUALENVS_DIR:-}" == "" ]]; then
		mock_virtualenvs_dir
	fi

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
		--echo)
			opt_echo=1
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
	mkdir -p "$DPV_MOCK_VIRTUALENVS_DIR/$python_version/$venv_name"
	printf "path = $project_path\nversion = $python_version\ninstall_method = $install_method\n" >"$venv_path/dpv.cfg"

	if [[ "$activate" -eq "1" ]]; then
		export DPV_MOCK_VIRTUALENV_DIR="$venv_path"
	fi
	if [[ "$opt_echo" -eq "1" ]]; then
		echo "$venv_path"
	fi
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

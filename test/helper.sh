# make executables in src/ visible to PATH
PATH="$DIR/../src:$PATH"

DPV_DIR="$BATS_TEST_TMPDIR/test_dpv"
PRJ_DIR="$BATS_TEST_TMPDIR/test_dpv_proj"
export DPV_DIR
export PRJ_DIR

ERR_CANNOT_DETERMINE_PYTHON_VERSION=2
export ERR_CANNOT_DETERMINE_PYTHON_VERSION

rm -rf "$DPV_DIR"
rm -rf "$PRJ_DIR"
mkdir -p "$DPV_DIR"
mkdir -p "$PRJ_DIR"

cd "$PRJ_DIR" || exit

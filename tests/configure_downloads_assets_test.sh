#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
script="$script_dir/configure.sh"

if grep -Fq 'script_dir/assets/' "$script"; then
    printf '%s\n' 'FAIL: configure.sh still reads assets from the local checkout' >&2
    exit 1
fi

for asset in soclaas.config.toml soclaas-model-catalog.json; do
    expected="curl -fsSL \"\$REPO_RAW_URL/assets/\$asset\""
    grep -Fq "$expected" "$script" || {
        printf 'FAIL: configure.sh does not download %s from GitHub\n' "$asset" >&2
        exit 1
    }
done

printf '%s\n' 'PASS: configure.sh downloads all assets from GitHub'

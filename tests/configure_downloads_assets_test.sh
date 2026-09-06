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

grep -Fq "ENV_LOAD_START='if [ -f \"\$HOME/.config/soclaas/soclaas.env\" ]; then'" "$script" || {
    printf '%s\n' 'FAIL: configure.sh does not add the env-file loading guard' >&2
    exit 1
}

for env_command in \
    "printf '  set -a\\n'" \
    'ENV_LOAD_SOURCE' \
    "printf '  set +a\\n'"; do
    grep -Fq "$env_command" "$script" || {
        printf 'FAIL: configure.sh does not add env command: %s\n' "$env_command" >&2
        exit 1
    }
done

grep -Fq 'mkdir -p "$CONFIG_DIR" "$CODEX_DIR"' "$script" || {
    printf '%s\n' 'FAIL: configure.sh does not create the config directories' >&2
    exit 1
}
grep -Fq 'chmod 700 "$CONFIG_DIR"' "$script" || {
    printf '%s\n' 'FAIL: configure.sh does not protect the config directory' >&2
    exit 1
}
grep -Fq 'chmod 600 "$env_tmp"' "$script" || {
    printf '%s\n' 'FAIL: configure.sh does not protect the env file' >&2
    exit 1
}

printf '%s\n' 'PASS: configure.sh configures shell environment loading and permissions'

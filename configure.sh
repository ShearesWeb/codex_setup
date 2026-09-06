#!/bin/sh
#
# SocLaas Codex profile installer.
#
# POSIX sh: works with bash, zsh, dash, ash (busybox), Git Bash (Windows),
# and WSL. Designed to run out of the box from a one-liner:
#
#   curl -fsSL https://raw.githubusercontent.com/ShearesWeb/codex_setup/main/configure.sh | sh
#
#   - re-points the API key prompt at /dev/tty (on a private fd, so the
#     shell can keep reading the script from stdin)
#   - downloads the profile assets directly from GitHub (no repo clone needed)
#
# The API key may also be passed via the SOCLAAS_API_KEY environment
# variable, which skips the prompt (useful for automation / CI):
#
#   SOCLAAS_API_KEY=sk-... curl -fsSL <...>/configure.sh | sh
set -eu

REPO_RAW_URL="https://raw.githubusercontent.com/ShearesWeb/codex_setup/main"
ASSETS="soclaas.config.toml soclaas-model-catalog.json"
CONFIG_DIR="$HOME/.config/soclaas"
CODEX_DIR="$HOME/.codex"
ENV_FILE="$CONFIG_DIR/soclaas.env"
ALIAS_LINE="alias codex='codex --profile soclaas'"

fail() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

command -v curl >/dev/null 2>&1 || \
    fail "curl is required (install curl, or use a distro/Windows Git Bash that ships it)."

# --- fetch assets from GitHub --------------------------------------------------
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
assets_dir="$work_dir/assets"
mkdir -p "$assets_dir"

for asset in $ASSETS; do
    curl -fsSL "$REPO_RAW_URL/assets/$asset" -o "$assets_dir/$asset" \
        || fail "failed to download $asset from $REPO_RAW_URL/assets/$asset"
done

# --- collect API key -----------------------------------------------------------
# When run as `curl ... | sh`, stdin (fd 0) carries the script itself.
# Open /dev/tty on a private fd for the prompt so the shell never reads
# keystrokes as script; if no terminal is available, fall back to stdin.
if [ ! -t 0 ] && ( : < /dev/tty ) 2>/dev/null; then
    exec 3< /dev/tty
    tty_fd=3
else
    tty_fd=0
fi

if [ -z "${SOCLAAS_API_KEY:-}" ] && [ "$tty_fd" = 0 ] && [ ! -t 0 ]; then
    fail "no interactive terminal for the API key prompt; export SOCLAAS_API_KEY and re-run."
fi

if [ -n "${SOCLAAS_API_KEY:-}" ]; then
    api_key=$SOCLAAS_API_KEY
    printf 'SOCLAAS_API_KEY taken from environment\n'
else
    # Prompt, hiding input when talking to a terminal (stty -echo is not
    # POSIX, so fall back to visible input when there is no tty).
    hidden=0
    if [ -t "$tty_fd" ] && stty -echo 2>/dev/null; then
        hidden=1
    fi
    printf 'SOCLAAS_API_KEY: '
    read -r api_key <&"$tty_fd" || api_key=''
    if [ "$hidden" = 1 ]; then
        stty echo 2>/dev/null || true
    fi
    printf '\n'
fi

[ -n "$api_key" ] || \
    fail "SOCLAAS_API_KEY cannot be empty (or set the SOCLAAS_API_KEY environment variable)."

# --- write env file (atomic, 600) ------------------------------------------------
mkdir -p "$CONFIG_DIR" "$CODEX_DIR"
chmod 700 "$CONFIG_DIR"

# Shell-quote the key with bash/ksh %q when the running shell supports it;
# otherwise write the key verbatim (API keys are normally plain tokens).
quoted=$(printf '%q' "$api_key" 2>/dev/null) || quoted=$api_key

env_tmp=$(mktemp "$CONFIG_DIR/.soclaas.env.XXXXXX")
trap 'rm -rf "$work_dir"; rm -f "$env_tmp"' EXIT
{
    printf 'SOCLAAS_API_KEY=%s\n' "$quoted"
    printf 'SOCLAAS_BASE_URL=https://soclaas-api.comp.nus.edu.sg/v1\n'
    printf 'SOCLAAS_MODEL=default\n'
} > "$env_tmp"
chmod 600 "$env_tmp"
mv "$env_tmp" "$ENV_FILE"

# --- copy Codex assets --------------------------------------------------------------
cp "$assets_dir/soclaas.config.toml" "$CODEX_DIR/soclaas.config.toml"
cp "$assets_dir/soclaas-model-catalog.json" "$CODEX_DIR/soclaas-model-catalog.json"

# --- add shell alias (idempotent) ------------------------------------------------------
# Uses the rc file of the login shell when detectable, otherwise .bashrc
# (which also covers Git Bash on Windows).
case "${SHELL:-}" in
  */zsh) rc_file="$HOME/.zshrc" ;;
  *)     rc_file="$HOME/.bashrc" ;;
esac

touch "$rc_file"
if ! grep -Fqx "$ALIAS_LINE" "$rc_file"; then
    printf '\n%s\n' "$ALIAS_LINE" >> "$rc_file"
fi

# --- done -------------------------------------------------------------------------------
command -v codex >/dev/null 2>&1 || \
    printf 'NOTE: codex not found on PATH; install the Codex CLI if you have not already.\n'

printf 'SOCLAAS environment saved to %s\n' "$ENV_FILE"
printf 'Codex assets copied to %s\n' "$CODEX_DIR"
printf 'Alias added to %s\n' "$rc_file"
printf 'Run: source %s\n' "$rc_file"

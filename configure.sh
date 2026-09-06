#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
assets_dir="$script_dir/assets"
config_dir="$HOME/.config/soclaas"
codex_dir="$HOME/.codex"
env_file="$config_dir/soclaas.env"
alias_line="alias codex='codex --profile soclaas'"

for asset in soclaas.config.toml soclaas-model-catalog.json; do
    if [[ ! -f "$assets_dir/$asset" ]]; then
        printf 'Missing asset: %s\n' "$assets_dir/$asset" >&2
        exit 1
    fi
done

read -r -s -p "SOCLAAS_API_KEY: " api_key
printf '\n'

if [[ -z "$api_key" ]]; then
    printf 'SOCLAAS_API_KEY cannot be empty.\n' >&2
    exit 1
fi

mkdir -p "$config_dir" "$codex_dir"
chmod 700 "$config_dir"

env_tmp=$(mktemp "$config_dir/.soclaas.env.XXXXXX")
trap 'rm -f "$env_tmp"' EXIT
{
    printf 'SOCLAAS_API_KEY=%q\n' "$api_key"
    printf 'SOCLAAS_BASE_URL=https://soclaas-api.comp.nus.edu.sg/v1\n'
    printf 'SOCLAAS_MODEL=default\n'
} > "$env_tmp"
chmod 600 "$env_tmp"
mv "$env_tmp" "$env_file"
trap - EXIT

cp "$assets_dir/soclaas.config.toml" "$codex_dir/soclaas.config.toml"
cp "$assets_dir/soclaas-model-catalog.json" "$codex_dir/soclaas-model-catalog.json"

touch "$HOME/.bashrc"
if ! grep -Fqx "$alias_line" "$HOME/.bashrc"; then
    printf '\n%s\n' "$alias_line" >> "$HOME/.bashrc"
fi

printf 'SOCLAAS environment saved to %s\n' "$env_file"
printf 'Codex assets copied to %s\n' "$codex_dir"
printf 'Alias added to %s\n' "$HOME/.bashrc"
printf 'Run: source ~/.bashrc\n'

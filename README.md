# codex_setup

One-line installer for the SocLaas Codex profile. It saves your API key, copies the Codex profile and model catalog assets into `~/.codex`, and adds a `codex` alias.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/ShearesWeb/codex_setup/main/configure.sh | sh
```

Or, to review the script before running it:

```sh
curl -fsSL https://raw.githubusercontent.com/ShearesWeb/codex_setup/main/configure.sh -o configure.sh
sh configure.sh
```

## What it does

- Prompts for `SOCLAAS_API_KEY` (input is hidden) and writes it to `~/.config/soclaas/soclaas.env` (mode `600`) along with the base URL and default model.
- Copies `assets/soclaas.config.toml` and `assets/soclaas-model-catalog.json` to `~/.codex/`.
- Adds `alias codex='codex --profile soclaas'` to `~/.bashrc` or `~/.zshrc`, based on your shell (idempotent).
- Adds the SocLaas environment loader to the same shell startup file (idempotent).
- Creates `~/.config/soclaas` with mode `700` and stores `soclaas.env` with mode `600`.

## Usage

```sh
# Bash:
source ~/.bashrc

# Zsh (the default shell on current macOS):
# source ~/.zshrc

codex
```

## Manual environment setup

If you already have a `soclaas.env` file in `~/Downloads`, run:

```sh
mkdir -p "$HOME/.config/soclaas"
mv "$HOME/Downloads/soclaas.env" "$HOME/.config/soclaas/soclaas.env"
chmod 700 "$HOME/.config/soclaas"
chmod 600 "$HOME/.config/soclaas/soclaas.env"
```

Then add this block to `~/.bashrc` (Bash/Linux) or `~/.zshrc` (Zsh/macOS/Linux):

```sh
if [ -f "$HOME/.config/soclaas/soclaas.env" ]; then
  set -a
  . "$HOME/.config/soclaas/soclaas.env"
  set +a
fi
```

Reload the file for the current terminal:

```sh
source ~/.bashrc  # Bash
source ~/.zshrc   # Zsh
```

## Requirements

- `bash` (or a shell that runs the script with `sh`) and `curl`
- An existing `codex` binary on `PATH`

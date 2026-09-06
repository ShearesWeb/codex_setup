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
- Adds `alias codex='codex --profile soclaas'` to `~/.bashrc` (idempotent).

## Usage

```sh
source ~/.bashrc
codex
```

## Requirements

- `bash` (or a shell that runs the script with `sh`), `curl`, `git`
- An existing `codex` binary on `PATH`

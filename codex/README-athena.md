# Codex Athena Build

This workflow builds JDCloud AX1800 Pro / Athena (`jdcloud_re-ss-01`) firmware on GitHub Actions.

Use `.github/workflows/codex-athena.yml`.

Required repository secrets for preset firmware:

- `WAN2_USERNAME`
- `WAN2_PASSWORD`

Optional repository secrets:

- `WAN1_USERNAME`
- `WAN1_PASSWORD`

If `WAN1_USERNAME` / `WAN1_PASSWORD` are empty, the preset script uses the defaults in `codex/build-preset.sh`.

Artifacts:

- `athena-plain-*`: integrated packages, no broadband account preset.
- `athena-preset-*`: integrated packages plus dual-WAN/mwan3 first-boot config.

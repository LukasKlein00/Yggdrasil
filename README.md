# Yggdrasil

Declarative, reproducible homelab: Proxmox VE → Talos (talhelper) → Flux GitOps.
Goal: wipe everything, run one bootstrap flow, get a working server back with app state restored.

## Layout

```
infrastructure/proxmox/   Proxmox auto-install answer file, host-only Ansible
infrastructure/tofu/      OpenTofu (bpg/proxmox) VM definitions
talos/<cluster>/          talconfig.yaml, talsecret.sops.yaml, patches/
kubernetes/clusters/<c>/  Flux entrypoint per cluster
kubernetes/infrastructure Cilium, cert-manager, ingress, Tailscale operator, VolSync
kubernetes/apps/          Jellyfin, Audiobookshelf, arr stack, downloaders
```

## Getting started

Requires [mise](https://mise.jdx.dev). All other CLIs are pinned in `.mise.toml`.

Activate mise in your shell (`eval "$(mise activate bash)"` in `~/.bashrc`) so the pinned tools are on
`PATH` ahead of system binaries (e.g. Taskwarrior's `/usr/bin/task`). Then, from the repo root:

```sh
mise trust && mise install
task setup        # pre-commit hooks, SOPS diff driver
task sops:init    # creates ~/.config/sops/age/keys.txt if missing, writes the public key into .sops.yaml
```

Without shell activation, prefix commands with `mise exec --` (e.g. `mise exec -- task setup`).

Back up `~/.config/sops/age/keys.txt` in the password manager. It is the only secret that lives outside git.

## Secrets

This repo is public. Secrets are `*.sops.*` files encrypted with SOPS + age (`task sops:encrypt FILE=…`).
pre-commit (gitleaks + `scripts/check-sops.sh`) rejects plaintext `*.sops.*` files, `kind: Secret` outside
SOPS files, and age private keys. Anything that ever reaches git in plaintext gets rotated.

#!/usr/bin/env bash
# pre-commit guard for the public repo. Fails if:
#   - a *.sops.* file has no SOPS metadata / encrypted values (committed plaintext)
#   - a Kubernetes Secret lives in a file not named *.sops.yaml
#   - an age private key appears anywhere
set -euo pipefail

rc=0
for f in "$@"; do
    [[ -f "$f" ]] || continue

    if grep -Eq 'AGE-SECRET-KEY-1[0-9A-Z]{58}' "$f"; then
        echo "ERROR: $f contains an age private key" >&2
        rc=1
    fi

    case "$f" in
        .sops.yaml | */.sops.yaml) ;; # SOPS config, not a secret
        *.sops.*)
            if ! grep -Eq '^sops:|"sops":|^sops_version=' "$f" || ! grep -q 'ENC\[AES256_GCM' "$f"; then
                echo "ERROR: $f is not SOPS-encrypted (run: task sops:encrypt FILE=$f)" >&2
                rc=1
            fi
            ;;
        *.yaml | *.yml)
            if grep -Eq '^kind:[[:space:]]*Secret[[:space:]]*$' "$f"; then
                echo "ERROR: $f defines a Secret but is not a *.sops.yaml file" >&2
                rc=1
            fi
            ;;
    esac
done
exit "$rc"

#!/usr/bin/env bash
# Build one store variant for one device.
# Usage: ./build.sh [free|pro] [device]   e.g. ./build.sh pro fr265
set -euo pipefail

VARIANT="${1:-pro}"
DEVICE="${2:-fr265}"

case "$VARIANT" in
    free|pro) ;;
    *) echo "ERROR: variant must be 'free' or 'pro'." >&2; exit 1 ;;
esac

if [[ -n "${CONNECTIQ_SDK:-}" ]]; then
    MONKEYC="$CONNECTIQ_SDK/bin/monkeyc"
elif command -v monkeyc >/dev/null 2>&1; then
    MONKEYC="$(command -v monkeyc)"
else
    SDK="$(ls -d "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks"/*/ 2>/dev/null | sort -V | tail -1 || true)"
    MONKEYC="${SDK%/}/bin/monkeyc"
fi

if [[ ! -x "$MONKEYC" ]]; then
    echo "ERROR: monkeyc not found." >&2
    echo "Install Connect IQ or set CONNECTIQ_SDK to the SDK folder." >&2
    exit 1
fi

if [[ -z "${JAVA_HOME:-}" ]] && [[ -d /opt/homebrew/opt/openjdk ]]; then
    export JAVA_HOME=/opt/homebrew/opt/openjdk
    export PATH="$JAVA_HOME/bin:$PATH"
fi

KEY="${CONNECTIQ_KEY:-$PWD/developer_key.der}"
if [[ ! -f "$KEY" ]]; then
    echo "==> Creating developer key (first run only)..."
    openssl genrsa -out developer_key.pem 4096
    openssl pkcs8 -topk8 -inform PEM -outform DER \
        -in developer_key.pem -out developer_key.der -nocrypt
    KEY="$PWD/developer_key.der"
fi

NAME="MidnightChampagne"
if [[ "$VARIANT" == "pro" ]]; then
    NAME="MidnightChampagnePro"
fi

OUT_DIR="$VARIANT/bin"
PRG="$OUT_DIR/$NAME-$DEVICE.prg"
mkdir -p "$OUT_DIR"

echo "==> Building '$VARIANT' for: $DEVICE"
"$MONKEYC" -f "$VARIANT/monkey.jungle" -d "$DEVICE" -o "$PRG" -y "$KEY" -w

echo
echo "OK: $PRG"
echo "Simulator: monkeydo \"$PRG\" $DEVICE"
